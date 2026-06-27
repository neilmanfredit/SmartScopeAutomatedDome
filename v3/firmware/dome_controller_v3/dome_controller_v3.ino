/*
 * Seestar S50 Slewing Dome V3 — Arduino Mega Firmware
 * Target: Arduino Mega 2560
 *
 * Three A4988 stepper drivers:
 *   Motor 1 (AZ)  — dome azimuth rotation
 *   Motor 2 (PA)  — Panel A (left aperture panel)
 *   Motor 3 (PB)  — Panel B (right aperture panel)
 *
 * Az position feedback: TCRT5000 IR encoder, 36 slots
 * Az resolution: 10° per slot (optical), 0.0375° per step (motor)
 *
 * Serial protocol (9600 baud, newline terminated):
 *   GOTO ddd.d    — slew dome to azimuth ddd.d degrees (0-359.9)
 *   SYNC ddd.d    — set current position = ddd.d degrees
 *   STATUS        — reply: AZ:ddd.d PA:n PB:n MOVING:n
 *   STOP          — halt all motors
 *   ABORT         — halt all motors
 *   PA OPEN       — Panel A fully open
 *   PA CLOSE      — Panel A fully closed
 *   PA POS nn     — Panel A to nn% (0=closed, 100=fully open)
 *   PB OPEN       — Panel B fully open
 *   PB CLOSE      — Panel B fully closed
 *   PB POS nn     — Panel B to nn%
 *   PANELS OPEN   — both panels fully open
 *   PANELS CLOSE  — both panels fully closed
 *   PARK          — slew to park position (Az 0°), close panels
 *   HOME          — home encoder (index mark)
 *
 * INDI slave mode is handled entirely in the INDI driver;
 * the Arduino just executes GOTO commands received over serial.
 */

#include <Arduino.h>

// ── Pin Definitions ─────────────────────────────────────────
// Motor 1 (Az rotation)
const uint8_t AZ_STEP  = 2;
const uint8_t AZ_DIR   = 3;
const uint8_t AZ_EN    = 4;
const uint8_t AZ_MS1   = 22;
const uint8_t AZ_MS2   = 23;
const uint8_t AZ_MS3   = 24;

// Motor 2 (Panel A — left)
const uint8_t PA_STEP  = 5;
const uint8_t PA_DIR   = 6;
const uint8_t PA_EN    = 7;
const uint8_t PA_MS1   = 25;
const uint8_t PA_MS2   = 26;
const uint8_t PA_MS3   = 27;

// Motor 3 (Panel B — right)
const uint8_t PB_STEP  = 8;
const uint8_t PB_DIR   = 9;
const uint8_t PB_EN    = 10;
const uint8_t PB_MS1   = 28;
const uint8_t PB_MS2   = 29;
const uint8_t PB_MS3   = 30;

// Az encoder (TCRT5000 on A0)
const uint8_t ENC_PIN  = A0;

// Panel limit switches
const uint8_t PA_LIM_CLOSE = 31;  // Panel A fully closed
const uint8_t PA_LIM_OPEN  = 32;  // Panel A fully open
const uint8_t PB_LIM_CLOSE = 33;
const uint8_t PB_LIM_OPEN  = 34;

// Status LED
const uint8_t LED_PIN  = 13;

// ── Motion Constants ────────────────────────────────────────
// Az: 6:1 gear ratio, 1/8 step → 9600 steps/revolution
const uint32_t AZ_STEPS_REV  = 9600;
const float    AZ_DEG_PER_STEP = 360.0f / AZ_STEPS_REV;  // 0.0375°

// Panel: M6 × 1.0mm pitch, 1/8 step → 1600 steps/mm
const uint32_t PANEL_STEPS_MM   = 1600;
const uint32_t PANEL_MAX_TRAVEL = 85;   // mm
const uint32_t PANEL_MAX_STEPS  = PANEL_MAX_TRAVEL * PANEL_STEPS_MM;  // 136000

// Acceleration
const uint16_t AZ_SPEED_MIN  = 4000;  // µs between steps (slow start)
const uint16_t AZ_SPEED_MAX  = 300;   // µs at cruise
const uint16_t AZ_ACCEL      = 800;   // ramp steps

const uint16_t PAN_SPEED_MIN = 3000;
const uint16_t PAN_SPEED_MAX = 400;
const uint16_t PAN_ACCEL     = 600;

// Park position
const float AZ_PARK = 0.0f;

// ── State ───────────────────────────────────────────────────
float    azCurrent    = 0.0f;   // degrees
float    azTarget     = 0.0f;
int32_t  azSteps      = 0;      // absolute step count (can be negative)

int32_t  paPos        = 0;      // Panel A steps (0=closed)
int32_t  pbPos        = 0;      // Panel B steps
bool     paOpen       = false;
bool     pbOpen       = false;
bool     azMoving     = false;
bool     panMoving    = false;

String   cmdBuffer    = "";

// Encoder state
volatile uint16_t encCount   = 0;
uint16_t          encLast    = 0;
bool              encHomed   = false;

// ── Helpers ─────────────────────────────────────────────────
void motorEnable(uint8_t enPin, bool en) {
    digitalWrite(enPin, en ? LOW : HIGH);
}

void setMicrostep(uint8_t ms1, uint8_t ms2, uint8_t ms3) {
    // 1/8 step: MS1=H MS2=H MS3=L
    digitalWrite(ms1, HIGH);
    digitalWrite(ms2, HIGH);
    digitalWrite(ms3, LOW);
}

void doStep(uint8_t stepPin) {
    digitalWrite(stepPin, HIGH);
    delayMicroseconds(2);
    digitalWrite(stepPin, LOW);
}

// Accel curve — returns step interval µs for step i of n total
uint16_t interval(uint32_t i, uint32_t n, uint16_t vMin, uint16_t vMax, uint16_t ramp) {
    uint32_t decelStart = (n > (uint32_t)ramp * 2) ? n - ramp : ramp;
    float t;
    if (i < ramp)             t = (float)i / ramp;
    else if (i > decelStart)  t = 1.0f - (float)(i - decelStart) / ramp;
    else                      t = 1.0f;
    t = constrain(t, 0.0f, 1.0f);
    return (uint16_t)(vMin - t * (vMin - vMax));
}

// Shortest rotation direction and step count for az slew
void azCalcMove(float from, float to, int32_t &steps, bool &clockwise) {
    float diff = fmod(to - from + 360.0f, 360.0f);
    if (diff > 180.0f) { diff -= 360.0f; }
    clockwise = (diff >= 0);
    steps = (int32_t)(abs(diff) / AZ_DEG_PER_STEP + 0.5f);
}

bool serialStop() {
    if (Serial.available()) {
        char c = Serial.peek();
        if (c == 'S' || c == 'A') return true;
    }
    return false;
}

// ── Az Slew ─────────────────────────────────────────────────
void azSlew(float targetDeg) {
    int32_t steps; bool cw;
    azCalcMove(azCurrent, targetDeg, steps, cw);
    if (steps == 0) { Serial.println("AZ:AT_TARGET"); return; }

    digitalWrite(AZ_DIR, cw ? HIGH : LOW);
    motorEnable(AZ_EN, true);
    azMoving = true;
    digitalWrite(LED_PIN, HIGH);

    for (int32_t i = 0; i < steps; i++) {
        if (serialStop()) { Serial.readStringUntil('\n'); break; }
        doStep(AZ_STEP);
        azSteps += cw ? 1 : -1;
        azCurrent = fmod(azSteps * AZ_DEG_PER_STEP + 3600.0f, 360.0f);
        delayMicroseconds(interval(i, steps, AZ_SPEED_MIN, AZ_SPEED_MAX, AZ_ACCEL));
    }

    motorEnable(AZ_EN, false);
    azMoving = false;
    digitalWrite(LED_PIN, LOW);
    Serial.print("AZ_DONE:"); Serial.println(azCurrent, 1);
}

// ── Panel Move ──────────────────────────────────────────────
void panelMove(uint8_t stepPin, uint8_t dirPin, uint8_t enPin,
               uint8_t limClose, uint8_t limOpen,
               int32_t &pos, int32_t targetSteps, const char *name) {
    if (targetSteps == pos) { return; }
    bool opening = (targetSteps > pos);
    int32_t steps = abs(targetSteps - pos);

    if (opening && digitalRead(limOpen) == LOW) {
        pos = PANEL_MAX_STEPS; return;
    }
    if (!opening && digitalRead(limClose) == LOW) {
        pos = 0; return;
    }

    digitalWrite(dirPin, opening ? HIGH : LOW);
    motorEnable(enPin, true);
    panMoving = true;

    for (int32_t i = 0; i < steps; i++) {
        if (serialStop()) { Serial.readStringUntil('\n'); break; }
        if (opening  && digitalRead(limOpen)  == LOW) { pos = PANEL_MAX_STEPS; break; }
        if (!opening && digitalRead(limClose) == LOW) { pos = 0; break; }
        doStep(stepPin);
        pos += opening ? 1 : -1;
        pos = constrain(pos, 0L, (long)PANEL_MAX_STEPS);
        delayMicroseconds(interval(i, steps, PAN_SPEED_MIN, PAN_SPEED_MAX, PAN_ACCEL));
    }

    motorEnable(enPin, false);
    panMoving = false;
    Serial.print(name); Serial.print("_DONE:"); Serial.println(pos);
}

int32_t pctToSteps(int pct) {
    return constrain((long)pct * PANEL_MAX_STEPS / 100L, 0L, (long)PANEL_MAX_STEPS);
}

// ── Command Parser ───────────────────────────────────────────
void processCommand(String cmd) {
    cmd.trim(); cmd.toUpperCase();

    if (cmd.startsWith("GOTO ")) {
        float az = cmd.substring(5).toFloat();
        az = fmod(az + 360.0f, 360.0f);
        Serial.print("SLEWING:"); Serial.println(az, 1);
        azSlew(az);

    } else if (cmd.startsWith("SYNC ")) {
        azCurrent = fmod(cmd.substring(5).toFloat() + 360.0f, 360.0f);
        azSteps = (int32_t)(azCurrent / AZ_DEG_PER_STEP);
        encHomed = true;
        Serial.print("SYNCED:"); Serial.println(azCurrent, 1);

    } else if (cmd == "STATUS") {
        Serial.print("AZ:"); Serial.print(azCurrent, 1);
        Serial.print(" PA:"); Serial.print((int)(100L * paPos / PANEL_MAX_STEPS));
        Serial.print(" PB:"); Serial.print((int)(100L * pbPos / PANEL_MAX_STEPS));
        Serial.print(" MOVING:"); Serial.println((azMoving || panMoving) ? 1 : 0);

    } else if (cmd == "STOP" || cmd == "ABORT") {
        motorEnable(AZ_EN, false);
        motorEnable(PA_EN, false);
        motorEnable(PB_EN, false);
        azMoving = panMoving = false;
        Serial.println("STOPPED");

    } else if (cmd == "PA OPEN") {
        panelMove(PA_STEP, PA_DIR, PA_EN, PA_LIM_CLOSE, PA_LIM_OPEN,
                  paPos, PANEL_MAX_STEPS, "PA");
    } else if (cmd == "PA CLOSE") {
        panelMove(PA_STEP, PA_DIR, PA_EN, PA_LIM_CLOSE, PA_LIM_OPEN,
                  paPos, 0, "PA");
    } else if (cmd.startsWith("PA POS ")) {
        panelMove(PA_STEP, PA_DIR, PA_EN, PA_LIM_CLOSE, PA_LIM_OPEN,
                  paPos, pctToSteps(cmd.substring(7).toInt()), "PA");

    } else if (cmd == "PB OPEN") {
        panelMove(PB_STEP, PB_DIR, PB_EN, PB_LIM_CLOSE, PB_LIM_OPEN,
                  pbPos, PANEL_MAX_STEPS, "PB");
    } else if (cmd == "PB CLOSE") {
        panelMove(PB_STEP, PB_DIR, PB_EN, PB_LIM_CLOSE, PB_LIM_OPEN,
                  pbPos, 0, "PB");
    } else if (cmd.startsWith("PB POS ")) {
        panelMove(PB_STEP, PB_DIR, PB_EN, PB_LIM_CLOSE, PB_LIM_OPEN,
                  pbPos, pctToSteps(cmd.substring(7).toInt()), "PB");

    } else if (cmd == "PANELS OPEN") {
        panelMove(PA_STEP,PA_DIR,PA_EN,PA_LIM_CLOSE,PA_LIM_OPEN,paPos,PANEL_MAX_STEPS,"PA");
        panelMove(PB_STEP,PB_DIR,PB_EN,PB_LIM_CLOSE,PB_LIM_OPEN,pbPos,PANEL_MAX_STEPS,"PB");
        Serial.println("PANELS_OPEN");

    } else if (cmd == "PANELS CLOSE") {
        panelMove(PA_STEP,PA_DIR,PA_EN,PA_LIM_CLOSE,PA_LIM_OPEN,paPos,0,"PA");
        panelMove(PB_STEP,PB_DIR,PB_EN,PB_LIM_CLOSE,PB_LIM_OPEN,pbPos,0,"PB");
        Serial.println("PANELS_CLOSED");

    } else if (cmd == "PARK") {
        Serial.println("PARKING");
        panelMove(PA_STEP,PA_DIR,PA_EN,PA_LIM_CLOSE,PA_LIM_OPEN,paPos,0,"PA");
        panelMove(PB_STEP,PB_DIR,PB_EN,PB_LIM_CLOSE,PB_LIM_OPEN,pbPos,0,"PB");
        azSlew(AZ_PARK);
        Serial.println("PARKED");

    } else if (cmd == "HOME") {
        // Slow rotation until encoder gives rising edge at slot 0
        // Then sync position to 0°
        Serial.println("HOMING");
        motorEnable(AZ_EN, true);
        digitalWrite(AZ_DIR, HIGH);
        uint16_t lastVal = analogRead(ENC_PIN);
        for (uint32_t i = 0; i < AZ_STEPS_REV + 100; i++) {
            doStep(AZ_STEP);
            uint16_t val = analogRead(ENC_PIN);
            if (val > 600 && lastVal < 400) {
                // Rising edge = slot transition = index
                azCurrent = 0.0f; azSteps = 0; encHomed = true;
                motorEnable(AZ_EN, false);
                Serial.println("HOMED");
                return;
            }
            lastVal = val;
            delayMicroseconds(800);
        }
        motorEnable(AZ_EN, false);
        Serial.println("HOME_FAILED");

    } else {
        Serial.print("ERR:UNKNOWN:"); Serial.println(cmd);
    }
}

// ── Setup ────────────────────────────────────────────────────
void setup() {
    Serial.begin(9600);

    uint8_t stepPins[] = {AZ_STEP, PA_STEP, PB_STEP};
    uint8_t dirPins[]  = {AZ_DIR,  PA_DIR,  PB_DIR};
    uint8_t enPins[]   = {AZ_EN,   PA_EN,   PB_EN};
    uint8_t ms1[]      = {AZ_MS1,  PA_MS1,  PB_MS1};
    uint8_t ms2[]      = {AZ_MS2,  PA_MS2,  PB_MS2};
    uint8_t ms3[]      = {AZ_MS3,  PA_MS3,  PB_MS3};

    for (int i = 0; i < 3; i++) {
        pinMode(stepPins[i], OUTPUT);
        pinMode(dirPins[i],  OUTPUT);
        pinMode(enPins[i],   OUTPUT);
        motorEnable(enPins[i], false);
        setMicrostep(ms1[i], ms2[i], ms3[i]);
    }

    pinMode(PA_LIM_CLOSE, INPUT_PULLUP);
    pinMode(PA_LIM_OPEN,  INPUT_PULLUP);
    pinMode(PB_LIM_CLOSE, INPUT_PULLUP);
    pinMode(PB_LIM_OPEN,  INPUT_PULLUP);
    pinMode(LED_PIN, OUTPUT);

    // Determine initial panel states from limit switches
    if (digitalRead(PA_LIM_CLOSE) == LOW) paPos = 0;
    if (digitalRead(PA_LIM_OPEN)  == LOW) paPos = PANEL_MAX_STEPS;
    if (digitalRead(PB_LIM_CLOSE) == LOW) pbPos = 0;
    if (digitalRead(PB_LIM_OPEN)  == LOW) pbPos = PANEL_MAX_STEPS;

    Serial.println("DOME_V3_READY");
    processCommand("STATUS");
}

// ── Loop ─────────────────────────────────────────────────────
void loop() {
    while (Serial.available()) {
        char c = Serial.read();
        if (c == '\n' || c == '\r') {
            if (cmdBuffer.length() > 0) {
                processCommand(cmdBuffer);
                cmdBuffer = "";
            }
        } else {
            cmdBuffer += c;
        }
    }
}

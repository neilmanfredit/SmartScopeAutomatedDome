/*
 * Seestar S50 Nano Dome — Arduino Firmware
 * Target: Arduino Nano (ATmega328P)
 * Stepper: NEMA 17 via A4988 driver
 * Lead screw: M8 × 1.25mm pitch
 *
 * Serial protocol (9600 baud, newline terminated):
 *   OPEN      — open dome (rotate motor until limit switch or max steps)
 *   CLOSE     — close dome
 *   STOP      — immediate halt
 *   STATUS    — reply: OPEN | CLOSED | MOVING | ERROR
 *   ABORT     — same as STOP
 *   STEP nn   — jog nn steps (+ = open direction, - = close)
 *
 * Pin assignments:
 *   D2  — STEP pin (A4988)
 *   D3  — DIR pin  (A4988)
 *   D4  — ENABLE pin (LOW = enabled)
 *   D5  — Limit switch OPEN  (NO, pullup)
 *   D6  — Limit switch CLOSED (NO, pullup)
 *   D7  — MS1 (A4988 microstepping — tie HIGH for 1/8 step)
 *   D8  — MS2 (tie LOW)
 *   D9  — MS3 (tie LOW)
 *   D13 — Status LED (onboard)
 *
 * Motor spec: 200 steps/rev, 1/8 microstepping = 1600 steps/rev
 * Lead screw: M8 × 1.25mm pitch
 * Steps per mm: 1600 / 1.25 = 1280 steps/mm
 *
 * Full open travel: ~100mm of lead screw extension
 * Max steps open:   100 × 1280 = 128000 steps
 */

#include <Arduino.h>

// --- Pin definitions ---
const uint8_t STEP_PIN   = 2;
const uint8_t DIR_PIN    = 3;
const uint8_t EN_PIN     = 4;
const uint8_t SW_OPEN    = 5;   // limit: dome fully open
const uint8_t SW_CLOSED  = 6;   // limit: dome fully closed
const uint8_t MS1        = 7;
const uint8_t MS2        = 8;
const uint8_t MS3        = 9;
const uint8_t LED_PIN    = 13;

// --- Motion parameters ---
const uint32_t STEPS_PER_REV   = 1600;   // 200 × 1/8 microstep
const float    PITCH_MM         = 1.25;   // M8 lead screw pitch
const uint32_t STEPS_PER_MM    = (uint32_t)(STEPS_PER_REV / PITCH_MM);  // 1280
const uint32_t MAX_TRAVEL_MM   = 100;
const uint32_t MAX_STEPS       = MAX_TRAVEL_MM * STEPS_PER_MM;          // 128000

// Acceleration profile (simple trapezoidal)
const uint16_t SPEED_MIN_US    = 3000;  // step interval at start (slow)
const uint16_t SPEED_MAX_US    = 400;   // step interval at full speed
const uint16_t ACCEL_STEPS     = 1000;  // steps to reach full speed

// --- State machine ---
enum DomeState { IDLE, OPENING, CLOSING, ERROR_STATE };
DomeState state = IDLE;

int32_t  currentPos  = 0;  // steps from fully-closed
bool     isOpen      = false;
bool     isClosed    = true;

String   cmdBuffer   = "";

// --- Helpers ---
void stepperEnable(bool en) {
    digitalWrite(EN_PIN, en ? LOW : HIGH);
}

void setDir(bool openDir) {
    // openDir = true  → motor turns to extend lead screw (open dome)
    digitalWrite(DIR_PIN, openDir ? HIGH : LOW);
}

uint16_t accelInterval(uint32_t stepNum, uint32_t totalSteps) {
    // Simple trapezoidal: ramp up, cruise, ramp down
    uint32_t ramp = ACCEL_STEPS;
    uint32_t decelStart = (totalSteps > ramp * 2) ? totalSteps - ramp : ramp;

    float t;
    if (stepNum < ramp)
        t = (float)stepNum / ramp;
    else if (stepNum > decelStart)
        t = 1.0f - (float)(stepNum - decelStart) / ramp;
    else
        t = 1.0f;

    t = constrain(t, 0.0f, 1.0f);
    return (uint16_t)(SPEED_MIN_US - t * (SPEED_MIN_US - SPEED_MAX_US));
}

bool limitOpen() {
    return digitalRead(SW_OPEN) == LOW;
}

bool limitClosed() {
    return digitalRead(SW_CLOSED) == LOW;
}

void doStep() {
    digitalWrite(STEP_PIN, HIGH);
    delayMicroseconds(2);
    digitalWrite(STEP_PIN, LOW);
}

void runMotor(bool openDir, uint32_t numSteps) {
    setDir(openDir);
    stepperEnable(true);
    digitalWrite(LED_PIN, HIGH);

    for (uint32_t i = 0; i < numSteps; i++) {
        // Check limits every step
        if (openDir && limitOpen()) {
            currentPos = MAX_STEPS;
            isOpen = true;
            break;
        }
        if (!openDir && limitClosed()) {
            currentPos = 0;
            isClosed = true;
            break;
        }

        // Check for serial STOP
        if (Serial.available()) {
            char c = Serial.peek();
            if (c == 'S') {
                Serial.readStringUntil('\n');
                Serial.println("STOPPED");
                break;
            }
        }

        doStep();
        currentPos += openDir ? 1 : -1;
        currentPos = constrain(currentPos, 0L, (long)MAX_STEPS);

        delayMicroseconds(accelInterval(i, numSteps));
    }

    stepperEnable(false);
    digitalWrite(LED_PIN, LOW);
    state = IDLE;
}

void cmdOpen() {
    if (isOpen) { Serial.println("ALREADY_OPEN"); return; }
    state = OPENING;
    Serial.println("OPENING");
    isOpen = false; isClosed = false;
    uint32_t stepsNeeded = MAX_STEPS - currentPos;
    runMotor(true, stepsNeeded);
    if (limitOpen()) isOpen = true;
    Serial.println(isOpen ? "OPEN" : "OPEN_FAULT");
}

void cmdClose() {
    if (isClosed) { Serial.println("ALREADY_CLOSED"); return; }
    state = CLOSING;
    Serial.println("CLOSING");
    isOpen = false; isClosed = false;
    uint32_t stepsNeeded = currentPos;
    runMotor(false, stepsNeeded);
    if (limitClosed()) isClosed = true;
    Serial.println(isClosed ? "CLOSED" : "CLOSE_FAULT");
}

void cmdStatus() {
    if (isOpen)        Serial.println("OPEN");
    else if (isClosed) Serial.println("CLOSED");
    else if (state == OPENING)  Serial.println("OPENING");
    else if (state == CLOSING)  Serial.println("CLOSING");
    else               Serial.println("UNKNOWN");
    Serial.print("POS:");
    Serial.println(currentPos);
}

void cmdJog(int32_t steps) {
    bool dir = steps > 0;
    uint32_t n = abs(steps);
    runMotor(dir, n);
    Serial.print("JOGGED:");
    Serial.println(steps);
}

void processCommand(String cmd) {
    cmd.trim();
    cmd.toUpperCase();

    if (cmd == "OPEN")       cmdOpen();
    else if (cmd == "CLOSE") cmdClose();
    else if (cmd == "STOP" || cmd == "ABORT") {
        state = IDLE;
        stepperEnable(false);
        Serial.println("STOPPED");
    }
    else if (cmd == "STATUS") cmdStatus();
    else if (cmd.startsWith("STEP ")) {
        int32_t n = cmd.substring(5).toInt();
        cmdJog(n);
    }
    else {
        Serial.print("ERR:UNKNOWN:");
        Serial.println(cmd);
    }
}

void setup() {
    Serial.begin(9600);

    pinMode(STEP_PIN, OUTPUT);
    pinMode(DIR_PIN,  OUTPUT);
    pinMode(EN_PIN,   OUTPUT);
    pinMode(MS1,      OUTPUT);
    pinMode(MS2,      OUTPUT);
    pinMode(MS3,      OUTPUT);
    pinMode(LED_PIN,  OUTPUT);
    pinMode(SW_OPEN,   INPUT_PULLUP);
    pinMode(SW_CLOSED, INPUT_PULLUP);

    // 1/8 microstepping on A4988
    digitalWrite(MS1, HIGH);
    digitalWrite(MS2, LOW);
    digitalWrite(MS3, LOW);

    stepperEnable(false);  // disabled at rest

    // Determine initial state from switches
    if (limitClosed()) { isClosed = true;  currentPos = 0; }
    if (limitOpen())   { isOpen   = true;  currentPos = MAX_STEPS; }

    Serial.println("DOME_READY");
    cmdStatus();
}

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

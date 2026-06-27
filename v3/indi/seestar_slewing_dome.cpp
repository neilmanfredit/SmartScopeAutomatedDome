/*
 * Seestar S50 Slewing Dome V3 — INDI Driver
 * Inherits: INDI::Dome
 *
 * Capabilities:
 *   DOME_CAN_ROTATE     — azimuth slewing
 *   DOME_CAN_SYNC       — sync current Az position
 *   DOME_CAN_ABORT      — stop all motion
 *   DOME_HAS_SHUTTER    — panel open/close (mapped to shutter)
 *   DOME_HAS_PARK       — park at Az 0°, panels closed
 *   DOME_HAS_BACKLASH   — Az backlash compensation
 *
 * Slave mode:
 *   When a mount driver is connected (via INDI server), the driver
 *   reads RA/Dec → converts to Az → sends GOTO to Arduino.
 *   Update rate: 5 seconds (configurable).
 *   Dead-band: 2° (dome does not slew for movements < 2°).
 *
 * Panel control:
 *   Exposed as two independent INDI number properties:
 *   PANEL_A_POS (0-100%) and PANEL_B_POS (0-100%).
 *   Shutter OPEN maps to PANELS OPEN.
 *   Shutter CLOSE maps to PANELS CLOSE.
 *
 * Build:
 *   sudo apt install libindi-dev cmake build-essential
 *   mkdir build && cd build
 *   cmake -DCMAKE_INSTALL_PREFIX=/usr ..
 *   make -j4 && sudo make install
 *   indiserver -v indi_seestar_slewing_dome
 */

#pragma once
#include <indidome.h>
#include <connectionplugins/connectionserial.h>
#include <indicom.h>

class SeestarSlewingDome : public INDI::Dome
{
public:
    SeestarSlewingDome();
    virtual ~SeestarSlewingDome() = default;

    virtual bool        initProperties()  override;
    virtual bool        updateProperties() override;
    virtual const char *getDefaultName()  override;
    virtual bool        ISNewNumber(const char *dev, const char *name,
                                    double *vals, char *names[], int n) override;
    virtual bool        ISNewSwitch(const char *dev, const char *name,
                                    ISState *states, char *names[], int n) override;

    // Dome interface
    virtual IPState Move(DomeDirection dir, DomeMotionCommand cmd) override;
    virtual IPState MoveAbs(double az) override;
    virtual IPState MoveRel(double azDiff) override;
    virtual IPState Park()   override;
    virtual IPState UnPark() override;
    virtual bool    Sync(double az) override;
    virtual bool    Abort()  override;

    virtual bool    saveConfigItems(FILE *fp) override;

protected:
    virtual bool Connect()    override;
    virtual bool Disconnect() override;
    virtual void TimerHit()   override;

private:
    bool sendCmd(const char *cmd, char *resp = nullptr, int respLen = 0);
    bool readLine(char *buf, int maxLen, int timeoutMs = 2000);
    void parseStatus(const char *line);
    void slaveUpdate();

    int    fd        = -1;
    double azCurrent = 0.0;
    int    panelA    = 0;    // 0-100%
    int    panelB    = 0;
    bool   m_moving  = false;
    int    m_slaveTimer = 0;

    // Custom properties
    ITextVectorProperty  SerialPortVP;
    IText                SerialPortT[1] = {};

    INumberVectorProperty PanelAVP;
    INumber               PanelAN[1] = {};

    INumberVectorProperty PanelBVP;
    INumber               PanelBN[1] = {};

    INumberVectorProperty SlaveSettingsVP;
    INumber               SlaveSettingsN[2] = {};  // [0]=update interval, [1]=dead-band

    ISwitchVectorProperty SlaveModeVP;
    ISwitch               SlaveModeS[2] = {};   // [0]=SLAVE_ON, [1]=SLAVE_OFF

    ISwitchVectorProperty DriveTypeVP;
    ISwitch               DriveTypeS[2] = {};   // [0]=PINION, [1]=FRICTION
};

// ── Implementation ───────────────────────────────────────────

#include "seestar_slewing_dome.h"
#include <termios.h>
#include <unistd.h>
#include <cstring>
#include <cmath>
#include <memory>
#include <libnova/transform.h>
#include <libnova/utility.h>

static std::unique_ptr<SeestarSlewingDome> sDome(new SeestarSlewingDome());

void ISGetProperties(const char *dev) { sDome->ISGetProperties(dev); }
void ISNewSwitch(const char *dev, const char *name, ISState *states, char *names[], int n)
    { sDome->ISNewSwitch(dev, name, states, names, n); }
void ISNewText(const char *dev, const char *name, char *texts[], char *names[], int n)
    { sDome->ISNewText(dev, name, texts, names, n); }
void ISNewNumber(const char *dev, const char *name, double vals[], char *names[], int n)
    { sDome->ISNewNumber(dev, name, vals, names, n); }
void ISNewBLOB(const char *dev, const char *name, int sizes[], int blobsizes[],
               char *blobs[], char *formats[], char *names[], int n)
    { sDome->ISNewBLOB(dev, name, sizes, blobsizes, blobs, formats, names, n); }
void ISSnoopDevice(XMLEle *root) { sDome->ISSnoopDevice(root); }

SeestarSlewingDome::SeestarSlewingDome()
{
    SetDomeCapability(DOME_CAN_ROTATE | DOME_CAN_SYNC | DOME_CAN_ABORT |
                      DOME_HAS_SHUTTER | DOME_HAS_PARK | DOME_HAS_BACKLASH);
    setVersion(3, 0);
}

const char *SeestarSlewingDome::getDefaultName()
{
    return "Seestar Slewing Dome";
}

bool SeestarSlewingDome::initProperties()
{
    INDI::Dome::initProperties();

    // Serial port
    IUFillText(&SerialPortT[0], "PORT", "Port", "/dev/ttyUSB0");
    IUFillTextVector(&SerialPortVP, SerialPortT, 1, getDeviceName(),
                     "SERIAL_PORT", "Serial Port", OPTIONS_TAB, IP_RW, 60, IPS_IDLE);

    // Panel A position (0-100%)
    IUFillNumber(&PanelAN[0], "PANEL_A_PCT", "Panel A (%)", "%.0f", 0, 100, 5, 0);
    IUFillNumberVector(&PanelAVP, PanelAN, 1, getDeviceName(),
                       "PANEL_A", "Panel A", MAIN_CONTROL_TAB, IP_RW, 60, IPS_IDLE);

    // Panel B position (0-100%)
    IUFillNumber(&PanelBN[0], "PANEL_B_PCT", "Panel B (%)", "%.0f", 0, 100, 5, 0);
    IUFillNumberVector(&PanelBVP, PanelBN, 1, getDeviceName(),
                       "PANEL_B", "Panel B", MAIN_CONTROL_TAB, IP_RW, 60, IPS_IDLE);

    // Slave mode settings
    IUFillNumber(&SlaveSettingsN[0], "UPDATE_INTERVAL", "Update interval (s)", "%.0f", 1, 60, 1, 5);
    IUFillNumber(&SlaveSettingsN[1], "DEAD_BAND", "Dead-band (°)", "%.1f", 0, 10, 0.5, 2.0);
    IUFillNumberVector(&SlaveSettingsVP, SlaveSettingsN, 2, getDeviceName(),
                       "SLAVE_SETTINGS", "Slave Mode", OPTIONS_TAB, IP_RW, 60, IPS_IDLE);

    // Slave mode on/off
    IUFillSwitch(&SlaveModeS[0], "SLAVE_ON",  "Active",   ISS_OFF);
    IUFillSwitch(&SlaveModeS[1], "SLAVE_OFF", "Inactive", ISS_ON);
    IUFillSwitchVector(&SlaveModeVP, SlaveModeS, 2, getDeviceName(),
                       "SLAVE_MODE", "Slave Mode", OPTIONS_TAB,
                       IP_RW, ISR_1OFMANY, 60, IPS_IDLE);

    // Drive type
    IUFillSwitch(&DriveTypeS[0], "PINION",   "Ring gear + pinion", ISS_ON);
    IUFillSwitch(&DriveTypeS[1], "FRICTION", "Friction wheel",     ISS_OFF);
    IUFillSwitchVector(&DriveTypeVP, DriveTypeS, 2, getDeviceName(),
                       "DRIVE_TYPE", "Drive Type", OPTIONS_TAB,
                       IP_RW, ISR_1OFMANY, 60, IPS_IDLE);

    SetParkData(false, 0.0, 0.0);
    addAuxControls();
    return true;
}

bool SeestarSlewingDome::updateProperties()
{
    INDI::Dome::updateProperties();
    if (isConnected()) {
        defineProperty(&SerialPortVP);
        defineProperty(&PanelAVP);
        defineProperty(&PanelBVP);
        defineProperty(&SlaveSettingsVP);
        defineProperty(&SlaveModeVP);
        defineProperty(&DriveTypeVP);
    } else {
        deleteProperty(SerialPortVP.name);
        deleteProperty(PanelAVP.name);
        deleteProperty(PanelBVP.name);
        deleteProperty(SlaveSettingsVP.name);
        deleteProperty(SlaveModeVP.name);
        deleteProperty(DriveTypeVP.name);
    }
    return true;
}

bool SeestarSlewingDome::Connect()
{
    int rc = tty_connect(SerialPortT[0].text, 9600, 8, 0, 1, &fd);
    if (rc != TTY_OK) {
        char e[256]; tty_error_msg(rc, e, 256);
        LOGF_ERROR("Serial connect failed: %s", e);
        return false;
    }
    tcflush(fd, TCIOFLUSH);
    usleep(2500000);  // Arduino Mega reset time
    char resp[128] = {};
    readLine(resp, sizeof(resp), 4000);
    LOGF_INFO("Connected: %s", resp);
    SetTimer(1000);
    return true;
}

bool SeestarSlewingDome::Disconnect()
{
    if (fd >= 0) { tty_disconnect(fd); fd = -1; }
    return true;
}

bool SeestarSlewingDome::sendCmd(const char *cmd, char *resp, int respLen)
{
    if (fd < 0) return false;
    char buf[128];
    snprintf(buf, sizeof(buf), "%s\n", cmd);
    int n;
    if (tty_write(fd, buf, strlen(buf), &n) != TTY_OK) return false;
    if (resp != nullptr) return readLine(resp, respLen);
    return true;
}

bool SeestarSlewingDome::readLine(char *buf, int maxLen, int timeoutMs)
{
    if (fd < 0) return false;
    int rc = tty_read_section(fd, buf, '\n', timeoutMs / 1000, maxLen);
    if (rc != TTY_OK) return false;
    int len = strlen(buf);
    while (len > 0 && (buf[len-1] == '\n' || buf[len-1] == '\r' || buf[len-1] == ' '))
        buf[--len] = '\0';
    return true;
}

void SeestarSlewingDome::parseStatus(const char *line)
{
    // "AZ:ddd.d PA:nn PB:nn MOVING:n"
    float az; int pa, pb, mov;
    if (sscanf(line, "AZ:%f PA:%d PB:%d MOVING:%d", &az, &pa, &pb, &mov) == 4) {
        azCurrent = az;
        DomeAbsPosN[0].value = az;
        IDSetNumber(&DomeAbsPosNP, nullptr);
        panelA = pa; panelB = pb;
        PanelAN[0].value = pa;
        PanelBN[0].value = pb;
        IDSetNumber(&PanelAVP, nullptr);
        IDSetNumber(&PanelBVP, nullptr);
        m_moving = (mov != 0);
    }
}

// Slave mode: compute dome Az from mount RA/Dec
void SeestarSlewingDome::slaveUpdate()
{
    if (SlaveModeS[0].s != ISS_ON) return;

    // Get telescope Ra/Dec from snooping
    // INDI::Dome base class provides mountEquatorialPos (Ra, Dec)
    // and observerLocation (lat, lon) automatically when mount is linked
    double lst = get_local_sidereal_time(Longitude);   // hours
    double ha  = lst - mountEquatorialPos.rightascension;
    double lat = Latitude * M_PI / 180.0;
    double dec = mountEquatorialPos.declination * M_PI / 180.0;
    double haRad = ha * 15.0 * M_PI / 180.0;

    // Alt/Az from HA/Dec
    double sinAlt = sin(dec)*sin(lat) + cos(dec)*cos(lat)*cos(haRad);
    double az = atan2(-cos(dec)*sin(haRad),
                      sin(dec)*cos(lat) - cos(dec)*sin(lat)*cos(haRad));
    az = az * 180.0 / M_PI;
    if (az < 0) az += 360.0;

    double deadBand = SlaveSettingsN[1].value;
    double diff = fabs(az - azCurrent);
    if (diff > 180.0) diff = 360.0 - diff;

    if (diff > deadBand) {
        char cmd[32];
        snprintf(cmd, sizeof(cmd), "GOTO %.1f", az);
        sendCmd(cmd);
        m_moving = true;
        LOGF_DEBUG("Slave: slewing from %.1f° to %.1f°", azCurrent, az);
    }
}

IPState SeestarSlewingDome::MoveAbs(double az)
{
    az = fmod(az + 360.0, 360.0);
    char cmd[32];
    snprintf(cmd, sizeof(cmd), "GOTO %.1f", az);
    sendCmd(cmd);
    m_moving = true;
    return IPS_BUSY;
}

IPState SeestarSlewingDome::MoveRel(double azDiff)
{
    return MoveAbs(azCurrent + azDiff);
}

IPState SeestarSlewingDome::Move(DomeDirection dir, DomeMotionCommand cmd)
{
    if (cmd == MOTION_STOP) { Abort(); return IPS_OK; }
    return MoveRel(dir == DOME_CW ? 5.0 : -5.0);
}

bool SeestarSlewingDome::Sync(double az)
{
    char cmd[32];
    snprintf(cmd, sizeof(cmd), "SYNC %.1f", az);
    sendCmd(cmd);
    azCurrent = az;
    DomeAbsPosN[0].value = az;
    IDSetNumber(&DomeAbsPosNP, nullptr);
    return true;
}

IPState SeestarSlewingDome::Park()
{
    sendCmd("PARK");
    m_moving = true;
    SetParked(false);
    return IPS_BUSY;
}

IPState SeestarSlewingDome::UnPark()
{
    sendCmd("PANELS OPEN");
    SetParked(false);
    return IPS_OK;
}

bool SeestarSlewingDome::Abort()
{
    sendCmd("STOP");
    m_moving = false;
    return true;
}

bool SeestarSlewingDome::ISNewNumber(const char *dev, const char *name,
                                      double *vals, char *names[], int n)
{
    if (strcmp(name, "PANEL_A") == 0) {
        char cmd[32];
        snprintf(cmd, sizeof(cmd), "PA POS %d", (int)vals[0]);
        sendCmd(cmd);
        PanelAN[0].value = vals[0];
        PanelAVP.s = IPS_BUSY;
        IDSetNumber(&PanelAVP, nullptr);
        return true;
    }
    if (strcmp(name, "PANEL_B") == 0) {
        char cmd[32];
        snprintf(cmd, sizeof(cmd), "PB POS %d", (int)vals[0]);
        sendCmd(cmd);
        PanelBN[0].value = vals[0];
        PanelBVP.s = IPS_BUSY;
        IDSetNumber(&PanelBVP, nullptr);
        return true;
    }
    if (strcmp(name, "SLAVE_SETTINGS") == 0) {
        IUUpdateNumber(&SlaveSettingsVP, vals, names, n);
        SlaveSettingsVP.s = IPS_OK;
        IDSetNumber(&SlaveSettingsVP, nullptr);
        return true;
    }
    return INDI::Dome::ISNewNumber(dev, name, vals, names, n);
}

bool SeestarSlewingDome::ISNewSwitch(const char *dev, const char *name,
                                      ISState *states, char *names[], int n)
{
    if (strcmp(name, "SLAVE_MODE") == 0) {
        IUUpdateSwitch(&SlaveModeVP, states, names, n);
        SlaveModeVP.s = IPS_OK;
        IDSetSwitch(&SlaveModeVP, nullptr);
        LOGF_INFO("Slave mode: %s", SlaveModeS[0].s == ISS_ON ? "ON" : "OFF");
        return true;
    }
    if (strcmp(name, "DRIVE_TYPE") == 0) {
        IUUpdateSwitch(&DriveTypeVP, states, names, n);
        DriveTypeVP.s = IPS_OK;
        IDSetSwitch(&DriveTypeVP, nullptr);
        return true;
    }
    return INDI::Dome::ISNewSwitch(dev, name, states, names, n);
}

void SeestarSlewingDome::TimerHit()
{
    if (!isConnected()) return;

    // Poll status
    char resp[128] = {};
    if (sendCmd("STATUS", resp, sizeof(resp))) {
        parseStatus(resp);
        if (!m_moving) {
            if (DomeAbsPosNP.s == IPS_BUSY) {
                DomeAbsPosNP.s = IPS_OK;
                IDSetNumber(&DomeAbsPosNP, nullptr);
            }
            PanelAVP.s = IPS_OK; IDSetNumber(&PanelAVP, nullptr);
            PanelBVP.s = IPS_OK; IDSetNumber(&PanelBVP, nullptr);
        }
    }

    // Shutter state tracking
    if (panelA == 0 && panelB == 0)
        setShutterState(SHUTTER_CLOSED);
    else if (panelA > 0 || panelB > 0)
        setShutterState(SHUTTER_OPENED);

    // Slave mode update (every N seconds)
    m_slaveTimer++;
    int interval = (int)SlaveSettingsN[0].value;
    if (m_slaveTimer >= interval) {
        slaveUpdate();
        m_slaveTimer = 0;
    }

    SetTimer(1000);
}

bool SeestarSlewingDome::saveConfigItems(FILE *fp)
{
    INDI::Dome::saveConfigItems(fp);
    IUSaveConfigText(fp, &SerialPortVP);
    IUSaveConfigNumber(fp, &SlaveSettingsVP);
    IUSaveConfigSwitch(fp, &SlaveModeVP);
    IUSaveConfigSwitch(fp, &DriveTypeVP);
    return true;
}

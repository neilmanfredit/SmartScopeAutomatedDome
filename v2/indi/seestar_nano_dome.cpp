/*
 * Seestar S50 Nano Dome — INDI Driver
 * Based on INDI::Dome base class
 *
 * Build:
 *   mkdir build && cd build
 *   cmake -DCMAKE_INSTALL_PREFIX=/usr ..
 *   make && sudo make install
 *
 * Driver name in INDI: "Seestar Nano Dome"
 * Device class: Dome
 *
 * Implements:
 *   - Open / Close / Park (closes)
 *   - Abort
 *   - Status polling (1Hz)
 *   - Serial port selection (default /dev/ttyUSB0)
 */

#pragma once

#include <indidome.h>
#include <connectionplugins/connectionserial.h>

class SeestarNanoDome : public INDI::Dome
{
public:
    SeestarNanoDome();
    virtual ~SeestarNanoDome() = default;

    // INDI base class overrides
    virtual bool initProperties() override;
    virtual bool updateProperties() override;
    virtual const char *getDefaultName() override;

    virtual bool ISNewSwitch(const char *dev, const char *name,
                             ISState *states, char *names[], int n) override;

    virtual IPState Move(DomeDirection dir, DomeMotionCommand command) override;
    virtual IPState Park()   override;
    virtual IPState UnPark() override;
    virtual bool Abort()     override;

    virtual bool saveConfigItems(FILE *fp) override;

protected:
    virtual bool Connect()    override;
    virtual bool Disconnect() override;
    virtual void TimerHit()   override;

private:
    bool sendCommand(const char *cmd, char *response, int respLen);
    bool readResponse(char *buf, int maxLen, int timeoutMs = 2000);
    void updateDomeStatus();

    int  fd = -1;          // serial fd
    bool m_moving = false;
    char m_lastStatus[32] = "UNKNOWN";

    // Custom properties
    ITextVectorProperty SerialPortVP;
    IText SerialPortT[1] = {};
};

// ==============================================================
// Implementation
// ==============================================================

#include "seestar_nano_dome.h"
#include <indicom.h>
#include <termios.h>
#include <unistd.h>
#include <cstring>
#include <memory>

static std::unique_ptr<SeestarNanoDome> sDome(new SeestarNanoDome());

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

// ---------------------------------------------------------------
SeestarNanoDome::SeestarNanoDome()
{
    SetDomeCapability(DOME_CAN_OPEN | DOME_CAN_CLOSE | DOME_CAN_ABORT | DOME_HAS_SHUTTER);
    setVersion(1, 0);
}

const char *SeestarNanoDome::getDefaultName()
{
    return "Seestar Nano Dome";
}

bool SeestarNanoDome::initProperties()
{
    INDI::Dome::initProperties();

    // Serial port property
    IUFillText(&SerialPortT[0], "PORT", "Port", "/dev/ttyUSB0");
    IUFillTextVector(&SerialPortVP, SerialPortT, 1, getDeviceName(),
                     "SERIAL_PORT", "Serial Port", OPTIONS_TAB,
                     IP_RW, 60, IPS_IDLE);

    addAuxControls();
    return true;
}

bool SeestarNanoDome::updateProperties()
{
    INDI::Dome::updateProperties();

    if (isConnected())
        defineProperty(&SerialPortVP);
    else
        deleteProperty(SerialPortVP.name);

    return true;
}

bool SeestarNanoDome::Connect()
{
    const char *port = SerialPortT[0].text;
    int rc = tty_connect(port, 9600, 8, 0, 1, &fd);
    if (rc != TTY_OK)
    {
        char errMsg[256];
        tty_error_msg(rc, errMsg, 256);
        LOGF_ERROR("Failed to connect to %s: %s", port, errMsg);
        return false;
    }

    // Flush and wait for DOME_READY
    tcflush(fd, TCIOFLUSH);
    usleep(2000000);  // 2s Arduino reset time

    char resp[64] = {};
    readResponse(resp, sizeof(resp), 3000);
    LOGF_INFO("Connected to %s — %s", port, resp);

    SetTimer(1000);
    return true;
}

bool SeestarNanoDome::Disconnect()
{
    if (fd >= 0)
    {
        tty_disconnect(fd);
        fd = -1;
    }
    return true;
}

bool SeestarNanoDome::sendCommand(const char *cmd, char *response, int respLen)
{
    if (fd < 0) return false;

    char buf[64];
    snprintf(buf, sizeof(buf), "%s\n", cmd);

    int nbytes;
    int rc = tty_write(fd, buf, strlen(buf), &nbytes);
    if (rc != TTY_OK) return false;

    if (response != nullptr)
        return readResponse(response, respLen);

    return true;
}

bool SeestarNanoDome::readResponse(char *buf, int maxLen, int timeoutMs)
{
    if (fd < 0) return false;
    int rc = tty_read_section(fd, buf, '\n', timeoutMs / 1000, maxLen);
    if (rc != TTY_OK) return false;
    // Strip trailing whitespace
    int len = strlen(buf);
    while (len > 0 && (buf[len-1] == '\n' || buf[len-1] == '\r' || buf[len-1] == ' '))
        buf[--len] = '\0';
    return true;
}

IPState SeestarNanoDome::Move(DomeDirection dir, DomeMotionCommand command)
{
    if (command == MOTION_STOP)
    {
        Abort();
        return IPS_OK;
    }

    const char *cmd = (dir == DOME_CW) ? "OPEN" : "CLOSE";
    char resp[64] = {};
    sendCommand(cmd, resp, sizeof(resp));
    m_moving = true;
    LOGF_INFO("Dome %s command sent — %s", cmd, resp);
    return IPS_BUSY;
}

IPState SeestarNanoDome::Park()
{
    // Park = Close
    char resp[64] = {};
    sendCommand("CLOSE", resp, sizeof(resp));
    m_moving = true;
    SetParked(false);  // will be set true on confirmation
    return IPS_BUSY;
}

IPState SeestarNanoDome::UnPark()
{
    char resp[64] = {};
    sendCommand("OPEN", resp, sizeof(resp));
    m_moving = true;
    return IPS_BUSY;
}

bool SeestarNanoDome::Abort()
{
    char resp[64] = {};
    sendCommand("STOP", resp, sizeof(resp));
    m_moving = false;
    return true;
}

void SeestarNanoDome::TimerHit()
{
    if (!isConnected()) return;

    // Poll status every timer tick
    char resp[64] = {};
    if (sendCommand("STATUS", resp, sizeof(resp)))
    {
        if (strncmp(resp, "OPEN", 4) == 0)
        {
            setShutterState(SHUTTER_OPENED);
            m_moving = false;
        }
        else if (strncmp(resp, "CLOSED", 6) == 0)
        {
            setShutterState(SHUTTER_CLOSED);
            SetParked(true);
            m_moving = false;
        }
        else if (strncmp(resp, "OPENING", 7) == 0)
        {
            setShutterState(SHUTTER_MOVING);
            m_moving = true;
        }
        else if (strncmp(resp, "CLOSING", 7) == 0)
        {
            setShutterState(SHUTTER_MOVING);
            m_moving = true;
        }
    }

    SetTimer(1000);
}

bool SeestarNanoDome::ISNewSwitch(const char *dev, const char *name,
                                   ISState *states, char *names[], int n)
{
    return INDI::Dome::ISNewSwitch(dev, name, states, names, n);
}

bool SeestarNanoDome::saveConfigItems(FILE *fp)
{
    INDI::Dome::saveConfigItems(fp);
    IUSaveConfigText(fp, &SerialPortVP);
    return true;
}

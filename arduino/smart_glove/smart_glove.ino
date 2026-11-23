/* Smart Glove App 3.0: Classic Nano / ATmega328P, Bluetooth Classic SPP at 9600.
 * Cooperative soft real-time scheduling; SoftwareSerial is not full duplex.
 * See docs/PROTOCOL.md and docs/HARDWARE_GUIDE.md before bench operation.
 */
#include "glove_core.h"
#include "text_oled.h"
#include <Arduino.h>
#include <EEPROM.h>
#include <SoftwareSerial.h>
#include <avr/eeprom.h>

const uint8_t flexPins[5] = {A0, A1, A2, A3, A6};
const uint8_t forcePin = A7;
const uint8_t motorPins[5] = {11, 10, 9, 6, 5};
const uint16_t sendInterval = 100, displayInterval = 250;
SoftwareSerial bluetooth(2, 3);
TextOled display;

char txQueue[3][64];
uint8_t txHead = 0, txCount = 0, txOffset = 0, pendingTimeouts = 0;
bool txOverflow = false;
uint32_t lastSample = 0, lastSend = 0, lastDisplay = 0, lastRx = 0;
uint32_t missedSamples = 0, lastEeprom = 0;
uint32_t lastDiagnostics = 0;
uint8_t physicalMask = 0, reportedMask = 0;

void enqueue(const char *line) {
  if (txCount == 3 || strlen(line) > 62) {
    txOverflow = true;
    return;
  }
  char *target = txQueue[(txHead + txCount) % 3];
  strcpy(target, line);
  strcat(target, "\n");
  ++txCount;
}

void enqueueConstant(const __FlashStringHelper *text) {
  char line[48];
  strcpy_P(line, reinterpret_cast<PGM_P>(text));
  enqueue(line);
}

void sendAcknowledgement(const char *line) {
  if (strncmp(line, "EVT,VIB,", 8) == 0 && line[8] >= '1' && line[8] <= '5') {
    pendingTimeouts |= uint8_t(1 << (line[8] - '1'));
  } else
    enqueue(line);
}

GloveCore glove(sendAcknowledgement);
uint8_t record[CalibrationRecord::size];
int8_t currentSlot = -1;
uint16_t recordSequence = 0;
uint8_t writeStep = 0, destinationSlot = 0;
bool writing = false;

void initializePins() {
  for (uint8_t i = 0; i < 5; ++i) {
    digitalWrite(motorPins[i], LOW);
    pinMode(motorPins[i], OUTPUT);
  }
}

void loadCalibration() {
  Calibration selected = {};
  bool found = false;
  for (uint8_t slot = 0; slot < 2; ++slot) {
    for (uint8_t i = 0; i < sizeof(record); ++i)
      record[i] = EEPROM.read(slot * sizeof(record) + i);
    Calibration candidate;
    uint16_t sequence;
    if (CalibrationRecord::decode(record, candidate, sequence) &&
        (!found || CalibrationRecord::newer(sequence, recordSequence))) {
      selected = candidate;
      recordSequence = sequence;
      currentSlot = slot;
      found = true;
    }
  }
  if (found)
    glove.load(selected);
}

void saveCalibration(uint32_t now) {
  if (!glove.saveRequested())
    return;
  if (!writing) {
    destinationSlot = currentSlot == 0 ? 1 : 0;
    CalibrationRecord::encode(glove.pendingCalibration(),
                              uint16_t(recordSequence + 1), record);
    writing = true;
    writeStep = 0;
  }
  if (!elapsed(now, lastEeprom, 5) || !eeprom_is_ready())
    return;
  lastEeprom = now;
  const uint16_t base = destinationSlot * sizeof(record);
  if (writeStep == 0)
    EEPROM.update(base, 0);
  else if (writeStep < sizeof(record))
    EEPROM.update(base + writeStep, record[writeStep]);
  else if (writeStep == sizeof(record))
    EEPROM.update(base, record[0]);
  else {
    bool match = true;
    for (uint8_t i = 0; i < sizeof(record); ++i)
      if (EEPROM.read(base + i) != record[i])
        match = false;
    writing = false;
    if (match) {
      currentSlot = destinationSlot;
      ++recordSequence;
    }
    glove.finishSave(match);
    return;
  }
  ++writeStep;
}

void applyHapticOutputs() {
  const uint8_t desired = glove.outputMask();
  for (uint8_t i = 0; i < 5; ++i) {
    const uint8_t bit = uint8_t(1 << i);
    if ((desired ^ physicalMask) & bit)
      digitalWrite(motorPins[i], (desired & bit) ? HIGH : LOW);
  }
  physicalMask = desired;
}

void receiveBluetoothCommands() {
  for (uint8_t count = 0; count < 16 && bluetooth.available(); ++count) {
    lastRx = millis();
    glove.receive(char(bluetooth.read()), lastRx);
    applyHapticOutputs();
  }
  if (bluetooth.overflow())
    enqueueConstant(F("ERR,0,LINK,RX_OVERFLOW"));
}

void sampleSensors(uint32_t now) {
  uint16_t raw[6];
  for (uint8_t i = 0; i < 5; ++i)
    raw[i] = analogRead(flexPins[i]);
  raw[5] = analogRead(forcePin);
  glove.sample(raw, now);
}

void sendSensorFrame() {
  if (txCount || pendingTimeouts || writing || glove.receivingCommand())
    return;
  char line[32];
  glove.sensorCsv(line, sizeof(line));
  enqueue(line);
  if (Serial.availableForWrite() >= int(strlen(line) + 2))
    Serial.println(line);
}

void pumpTransmission(uint32_t now) {
  if (!elapsed(now, lastRx, 4) || bluetooth.available() ||
      glove.receivingCommand())
    return;
  if (pendingTimeouts && txCount < 3) {
    for (uint8_t i = 0; i < 5; ++i) {
      if (pendingTimeouts & (1 << i)) {
        char line[40];
        SG_SNPRINTF(line, sizeof(line), "EVT,VIB,%u,TIMEOUT,%u",
                    unsigned(i + 1), unsigned(glove.outputMask()));
        enqueue(line);
        pendingTimeouts &= uint8_t(~(1 << i));
        break;
      }
    }
  }
  if (txOverflow && txCount == 0) {
    txOverflow = false;
    enqueueConstant(F("ERR,0,LINK,TX_OVERFLOW"));
  }
  if (!txCount)
    return;
  // One byte per loop bounds each SoftwareSerial blind interval to ~1.04 ms.
  bluetooth.write(uint8_t(txQueue[txHead][txOffset++]));
  if (!txQueue[txHead][txOffset]) {
    txOffset = 0;
    txHead = (txHead + 1) % 3;
    --txCount;
  }
}

SensorFrame displayFrame;
uint8_t displayPage = 8, displayMask = 0;
bool displayManual = false, displayValid = false;
char displayPhase[12];

void updateDisplay(uint32_t now) {
  if (!display.active())
    return;
  if (displayPage >= 8 && display.rowDone()) {
    if (!elapsed(now, lastDisplay, displayInterval))
      return;
    lastDisplay = now;
    displayPage = 0;
    displayFrame = glove.frame();
    displayMask = glove.outputMask();
    displayManual = glove.manualMode();
    displayValid = glove.calibration().valid;
    strncpy(displayPhase, glove.phaseName(), sizeof(displayPhase) - 1);
  }
  if (display.rowDone()) {
    char row[22];
    if (displayPage == 0)
      SG_SNPRINTF(row, sizeof(row), "SG3 %s %s",
                  displayManual ? "MANUAL" : "AUTO",
                  elapsed(now, lastRx, 3000) ? "--" : "RX");
    else if (displayPage <= 5) {
      uint8_t i = displayPage - 1;
      SG_SNPRINTF(row, sizeof(row), "%c:%02u %c %c", "TIMRP"[i],
                  unsigned(displayFrame.angle[i]),
                  displayFrame.angle[i] >= GloveCore::bendOn ? 'B' : 'F',
                  displayMask & (1 << i) ? 'V' : '-');
    } else if (displayPage == 6)
      SG_SNPRINTF(row, sizeof(row), "G:%u D:%u", unsigned(displayFrame.grip),
                  unsigned(displayFrame.gripDelta));
    else
      SG_SNPRINTF(row, sizeof(row), "%s %s", displayPhase,
                  glove.timeoutMask() ? "TIMEOUT"
                  : displayValid      ? "OK"
                                      : "NEEDS CAL");
    display.setRow(displayPage++, row);
  }
  display.step();
}

void setup() {
  initializePins();
  Serial.begin(115200);
  bluetooth.begin(9600);
  loadCalibration();
  if (!display.begin())
    Serial.println(F("OLED unavailable; sensor/control operation continues"));
  const uint32_t now = millis();
  lastSample = now;
  lastSend = now;
  lastRx = now;
  Serial.println(
      F("Smart Glove App 3.0; calibrate OPEN, CLOSED, SAVE before recording"));
}

void loop() {
  receiveBluetoothCommands();
  uint32_t now = millis();
  glove.tick(now);
  applyHapticOutputs();
  if (elapsed(now, lastSample, GloveCore::sampleInterval)) {
    uint32_t periods = uint32_t(now - lastSample) / GloveCore::sampleInterval;
    missedSamples += periods - 1;
    lastSample += periods * GloveCore::sampleInterval;
    sampleSensors(now);
    applyHapticOutputs();
  }
  saveCalibration(millis());
  now = millis();
  if (elapsed(now, lastSend, sendInterval)) {
    lastSend = now;
    if (reportedMask != glove.outputMask() && txCount < 2) {
      char event[24];
      SG_SNPRINTF(event, sizeof(event), "EVT,OUTPUT,%u",
                  unsigned(glove.outputMask()));
      enqueue(event);
      reportedMask = glove.outputMask();
    }
    sendSensorFrame();
  }
  if (!txCount && !bluetooth.available() && !glove.receivingCommand() &&
      elapsed(now, lastRx, 4) && uint32_t(now - lastSample) < 15)
    updateDisplay(now);
  pumpTransmission(millis());
  receiveBluetoothCommands();
  glove.tick(millis());
  applyHapticOutputs();
  now = millis();
  if (elapsed(now, lastDiagnostics, 10000) &&
      Serial.availableForWrite() >= 32) {
    lastDiagnostics = now;
    char line[32];
    SG_SNPRINTF(line, sizeof(line), "DIAG,MISSED,%lu,OLED,%u",
                static_cast<unsigned long>(missedSamples),
                unsigned(display.active()));
    Serial.println(line);
  }
}

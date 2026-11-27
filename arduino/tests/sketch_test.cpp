#include "Arduino.h"
#include "EEPROM.h"
#include "Wire.h"
#include <cassert>
#include <iostream>
#include <sstream>

uint32_t testMillis = 0;
unsigned analogReads = 0;
std::array<uint16_t, 8> analogInputs = {{100, 100, 100, 100, 0, 0, 100, 100}};
std::array<bool, 20> pinOutputs = {};
TestSerial Serial;
TestEeprom EEPROM;
TestWire Wire;
#include "../smart_glove/smart_glove.ino"

static Calibration fixture() {
  Calibration c = {};
  for (int i = 0; i < 5; ++i) {
    c.open[i] = 100;
    c.closed[i] = 300;
  }
  c.gripBase = 100;
  c.gripOn = 80;
  c.gripOff = 40;
  c.valid = true;
  return c;
}
static void runFor(uint32_t ms) {
  uint32_t started = testMillis;
  while (uint32_t(testMillis - started) < ms) {
    ++testMillis;
    loop();
  }
}
static void rebootCore() {
  glove = GloveCore(sendAcknowledgement);
  currentSlot = -1;
  recordSequence = 0;
  txCount = txHead = txOffset = 0;
  pendingTimeouts = 0;
  writing = false;
  loadCalibration();
}

int main() {
  uint8_t first[34], second[34];
  CalibrationRecord::encode(fixture(), 1, first);
  CalibrationRecord::encode(fixture(), 2, second);
  for (int i = 0; i < 34; ++i) {
    EEPROM.data[i] = first[i];
    EEPROM.data[34 + i] = second[i];
  }
  EEPROM.data[44] ^= 1;
  pinOutputs.fill(true);
  setup();
  assert(glove.calibration().valid && currentSlot == 0 && recordSequence == 1);
  for (auto pin : motorPins)
    assert(!pinOutputs[pin]);
  bluetooth.inject("<Q:1:VIB:3,1>");
  runFor(100);
  assert(pinOutputs[9] &&
         bluetooth.tx.find("ACK,1,VIB,3,1,4\n") != std::string::npos);
  runFor(1100);
  assert(!pinOutputs[9]);
  assert(bluetooth.tx.find("EVT,VIB,3,TIMEOUT,0\n") != std::string::npos);
  // Actual sketch scheduler samples only once per interval; OLED/TX never read
  // ADC.
  unsigned before = analogReads;
  unsigned periodsBefore = lastSample;
  runFor(400);
  unsigned periods = uint32_t(lastSample - periodsBefore) / 20;
  assert(analogReads - before == periods * 6);
  assert(missedSamples == 0);
  std::istringstream received(bluetooth.tx);
  std::string line;
  unsigned frames = 0;
  while (std::getline(received, line)) {
    if (received.eof())
      break; // A final partial line is not a frame boundary.
    if (!line.empty() && line[0] >= '0' && line[0] <= '9') {
      assert(line == "0,0,0,0,0,100");
      ++frames;
    }
  }
  assert(frames >= 10);
  for (const auto &transaction : Wire.transactions)
    assert(transaction.size() <= 32);
  // Destination slot is invalid until the final commit; reboot keeps old data.
  bluetooth.inject("<Q:2:CAL:RESET>");
  runFor(50);
  assert(EEPROM.data[34] == 0 && EEPROM.data[0] == 0xA5);
  rebootCore();
  assert(glove.calibration().valid && recordSequence == 1);
  bluetooth.inject("<Q:3:CAL:RESET>");
  runFor(20);
  bluetooth.inject("<Q:4:MODE:MANUAL>");
  runFor(300);
  assert(!glove.calibration().valid);
  assert(bluetooth.tx.find("ACK,3,CAL,RESET\n") != std::string::npos);
  assert(bluetooth.tx.find("ERR,4,CMD,BUSY\n") != std::string::npos);
  unsigned writesBeforeRetry = EEPROM.writes;
  bluetooth.inject("<Q:3:CAL:RESET>");
  runFor(100);
  assert(EEPROM.writes == writesBeforeRetry);
  rebootCore();
  assert(!glove.calibration().valid && recordSequence == 2);
  Wire.fail = true;
  runFor(500);
  assert(!display.active());
  // Display failure does not stop command handling or sensor sampling.
  bluetooth.inject("<Q:5:VIB:1,1>");
  runFor(100);
  assert(pinOutputs[11]);
  EEPROM.data.fill(0xFF);
  rebootCore();
  assert(!glove.calibration().valid);
  // Reproduce a saturated AUTO request while old calibration is still active
  // during reset. No GPIO may come back on when the journal commits.
  glove.load(fixture());
  bluetooth.inject("<Q:6:MODE:AUTO>");
  for (auto pin : flexPins)
    analogInputs[pin] = 300;
  runFor(600);
  assert(physicalMask == 31);
  bluetooth.inject("<Q:7:CAL:RESET>");
  for (unsigned ms = 0; ms < 250; ++ms) {
    runFor(1);
    assert(physicalMask == 0);
  }
  assert(!glove.calibration().valid);
  std::cout << "Sketch integration: GPIO, scheduling, wire limits, EEPROM "
               "journal and display failure passed\n";
}

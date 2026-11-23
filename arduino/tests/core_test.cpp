#include "../smart_glove/glove_core.h"
#include <cassert>
#include <iostream>
#include <string>
#include <vector>

static std::vector<std::string> lines;
static void output(const char *line) { lines.emplace_back(line); }
static void command(GloveCore &glove, const char *text, uint32_t now = 0) {
  for (; *text; ++text)
    glove.receive(*text, now);
}
static Calibration validCalibration() {
  Calibration c = {};
  for (uint8_t i = 0; i < 5; ++i) {
    c.open[i] = 100;
    c.closed[i] = 300;
  }
  c.open[1] = 800;
  c.closed[1] = 600;
  c.gripBase = 100;
  c.gripOn = 80;
  c.gripOff = 40;
  c.valid = true;
  return c;
}
static void sample(GloveCore &g, uint16_t flex, uint16_t grip, uint32_t now) {
  const uint16_t raw[6] = {flex, 700, flex, flex, flex, grip};
  g.sample(raw, now);
}

int main() {
  GloveCore g(output);
  g.load(validCalibration());
  command(g, "noise<Q:1:VIB:3,");
  assert(g.outputMask() == 0);
  command(g, "1>");
  assert(g.manualMode() && g.outputMask() == 4);
  assert(lines.back() == "ACK,1,VIB,3,1,4");
  sample(g, 300, 900, 20);
  assert(g.outputMask() == 4); // Automatic requests cannot overwrite manual.
  command(g, "<Q:1:VIB:3,1>", 900);
  g.tick(1000);
  assert(g.outputMask() == 0); // Duplicate did not extend continuous-on time.
  assert(lines.back() == "EVT,VIB,3,TIMEOUT,0");
  command(g, "<VIB:3,1>", 1001);
  assert(g.outputMask() == 0); // Requires explicit OFF and cooldown.
  assert(lines.back() == "ERR,0,VIB,REARM_REQUIRED");
  command(g, "<VIB:ALL,0><VIB:6,1><VIB:2,x><VIB:01,1><VIB:1,1,0>", 1100);
  assert(g.outputMask() == 0);
  assert(lines.back() == "ERR,0,VIB,BAD_STATE");
  command(g, "<Q:1:VIB:1,1>", 1100);
  assert(lines.back() == "ERR,1,CMD,ID_REUSE");
  command(g, "<Q:2:MODE:AUTO>", 3100);
  sample(g, 300, 900, 3120);
  assert(g.outputMask() ==
         27); // Finger 3 remains latched until release/cooldown.
  command(g, "<Q:3:CAL:OPEN>", 3140);
  assert(g.outputMask() == 0 && g.calibrating());
  for (int i = 0; i < 64; ++i)
    sample(g, 200, 50, 3160 + i * 20);
  assert(std::string(g.phaseName()) == "OPEN_READY");
  command(g, "<Q:4:CAL:CLOSED>", 4500);
  for (int i = 0; i < 64; ++i)
    sample(g, 205, 50, 4520 + i * 20);
  assert(lines.back() == "EVT,CAL,CLOSED,INVALID_SPAN");
  assert(g.calibration().open[0] == 100); // Previous valid record survives.
  command(g, "<CAL:OPEN>", 6000);
  for (int i = 0; i < 64; ++i)
    sample(g, i == 20 ? 900 : 100, 100, 6020 + i * 20);
  assert(std::string(g.phaseName()) == "OPEN_READY"); // One spike trimmed.
  command(g, "<CAL:CLOSED>", 7400);
  for (int i = 0; i < 64; ++i) {
    const uint16_t raw[6] = {300, 500, 300, 300, 300, 100};
    g.sample(raw, 7420 + i * 20);
  }
  assert(std::string(g.phaseName()) == "READY");
  command(g, "<CAL:SAVE>", 8800);
  assert(g.saveRequested());
  g.finishSave(true);
  assert(g.calibration().open[0] == 100 && g.calibration().closed[0] == 300);
  assert(std::string(g.phaseName()) == "IDLE");

  GloveCore sensors(output);
  sensors.load(validCalibration());
  sample(sensors, 200, 150, 0);
  assert(sensors.frame().angle[0] == 45 && sensors.frame().angle[1] == 45);
  assert(sensors.frame().grip == 150 && sensors.frame().gripDelta == 50);
  char csv[32];
  sensors.sensorCsv(csv, sizeof(csv));
  assert(std::string(csv) == "45,45,45,45,45,150");
  sample(sensors, 1023, 1023, 20);
  assert(sensors.frame().angle[0] <= 90 && sensors.frame().grip <= 1023);
  // Filtering is initialized to the first reading, then responds gradually.
  assert(sensors.frame().filtered[0] > 200 &&
         sensors.frame().filtered[0] < 1023);

  GloveCore pressure(output);
  pressure.load(validCalibration());
  sample(pressure, 100, 190, 0);
  assert(pressure.gripActive());
  for (int i = 0; i < 80; ++i)
    sample(pressure, 100, 150, i * 20);
  assert(pressure.gripActive()); // Inside hysteresis band.
  for (int i = 0; i < 80; ++i)
    sample(pressure, 100, 130, i * 20);
  assert(!pressure.gripActive());

  GloveCore malformed(output);
  command(malformed, ("<" + std::string(100, 'X') + "><VIB:1,1>").c_str());
  assert(malformed.outputMask() == 1);
  command(malformed, "<VIB:2,1", 10);
  malformed.tick(300);
  assert(lines.back() == "ERR,0,CMD,INCOMPLETE");
  command(malformed, "><bad<VIB:ALL,0>", 310);
  assert(malformed.outputMask() == 0);
  command(malformed, "<VIB:1,1>", 0xFFFFFF00UL);
  malformed.tick(800);
  assert(malformed.outputMask() == 0); // Motor timeout across millis rollover.
  assert(elapsed(10, 0xFFFFFFF0UL, 20));

  GloveCore lease(output);
  command(lease, "<Q:9:MODE:MANUAL>", 0);
  lease.tick(3001);
  assert(lines.back() == "EVT,LINK,LEASE_EXPIRED,0");
  command(lease, "<VIB:1,1>", 3002);
  assert(lease.outputMask() == 1);

  uint8_t record[CalibrationRecord::size];
  CalibrationRecord::encode(validCalibration(), 42, record);
  Calibration decoded;
  uint16_t sequence = 0;
  assert(CalibrationRecord::decode(record, decoded, sequence) &&
         sequence == 42);
  record[9] ^= 0x80;
  assert(!CalibrationRecord::decode(record, decoded, sequence));
  for (auto &byte : record)
    byte = 0xFF;
  assert(!CalibrationRecord::decode(record, decoded, sequence));
  Calibration reset = {};
  reset.gripOn = 80;
  reset.gripOff = 40;
  CalibrationRecord::encode(reset, 43, record);
  assert(CalibrationRecord::decode(record, decoded, sequence) &&
         !decoded.valid);
  assert(CalibrationRecord::newer(0, 65535));

  GloveCore continuous(output);
  continuous.load(validCalibration());
  sample(continuous, 300, 900, 0);
  command(continuous, "<MODE:AUTO>", 900);
  continuous.tick(1000);
  assert(continuous.outputMask() == 0); // Mode commands cannot reset ON timer.

  GloveCore replay(output);
  command(replay, "<Q:17:VIB:1,1>", 0);
  replay.tick(1000);
  command(replay, "<Q:17:VIB:1,1>", 1100);
  assert(lines.back() == "ACK,17,VIB,1,1,0"); // Retry reports current output.
  GloveCore unstable(output);
  unstable.load(validCalibration());
  command(unstable, "<CAL:OPEN>");
  for (int i = 0; i < 64; ++i)
    sample(unstable, i % 2 ? 100 : 300, 100, i * 20);
  assert(lines.back() == "EVT,CAL,OPEN,UNSTABLE");
  assert(unstable.calibration().valid && unstable.calibration().open[0] == 100);
  command(unstable, "<CAL:CANCEL>", 1500);
  assert(std::string(unstable.phaseName()) == "IDLE");
  GloveCore fuzz(output);
  uint32_t random = 23;
  for (uint32_t i = 0; i < 10000; ++i) {
    random = random * 1664525UL + 1013904223UL;
    fuzz.receive(char(random >> 24), i);
    fuzz.tick(i);
    assert(fuzz.outputMask() <= 31);
  }
  command(fuzz, "<VIB:ALL,0>", 10001);
  assert(fuzz.outputMask() == 0);
  GloveCore statusReplay(output);
  command(statusReplay, "<Q:1:VIB:1,1>", 0);
  command(statusReplay, "<Q:2:STATUS>", 100);
  statusReplay.tick(1000);
  command(statusReplay, "<Q:2:STATUS>", 1100);
  assert(lines.back() == "ACK,2,STATUS,3.0,MANUAL,0,IDLE,0,0");
  std::cout << "Firmware core: parser, calibration, filtering, modes, safety, "
               "CSV and EEPROM passed\n";
}

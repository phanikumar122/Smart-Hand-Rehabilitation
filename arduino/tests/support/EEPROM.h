#pragma once
#include "Arduino.h"
struct TestEeprom {
  std::array<uint8_t, 1024> data;
  unsigned writes = 0;
  uint32_t busyUntil = 0;
  TestEeprom() { data.fill(0xFF); }
  uint8_t read(uint16_t address) { return data.at(address); }
  void update(uint16_t address, uint8_t value) {
    if (data.at(address) != value) {
      data[address] = value;
      ++writes;
      busyUntil = testMillis + 3;
    }
  }
};
extern TestEeprom EEPROM;

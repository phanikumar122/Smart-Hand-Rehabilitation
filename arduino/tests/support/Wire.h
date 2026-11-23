#pragma once
#include "Arduino.h"
struct TestWire {
  std::vector<uint8_t> current;
  std::vector<std::vector<uint8_t>> transactions;
  bool fail = false;
  void begin() {}
  void setClock(unsigned long) {}
  void setWireTimeout(unsigned long, bool) {}
  void beginTransmission(uint8_t address) {
    if (address != 0x3C)
      fail = true;
    current.clear();
  }
  void write(uint8_t b) { current.push_back(b); }
  uint8_t endTransmission() {
    transactions.push_back(current);
    testMillis += 2;
    return fail ? 4 : 0;
  }
  bool getWireTimeoutFlag() { return fail; }
  void clearWireTimeoutFlag() {}
};
extern TestWire Wire;

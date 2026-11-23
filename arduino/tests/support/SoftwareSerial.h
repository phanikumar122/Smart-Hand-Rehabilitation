#pragma once
#include "Arduino.h"
#include <deque>
struct SoftwareSerial {
  std::deque<uint8_t> rx;
  std::string tx;
  SoftwareSerial(int, int) {}
  void begin(int) {}
  bool available() { return !rx.empty(); }
  uint8_t read() {
    uint8_t b = rx.front();
    rx.pop_front();
    return b;
  }
  void write(uint8_t b) {
    tx += char(b);
    ++testMillis;
  }
  bool overflow() { return false; }
  void inject(const char *s) {
    while (*s)
      rx.push_back(uint8_t(*s++));
  }
};

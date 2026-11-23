#pragma once
#include <array>
#include <stdint.h>
#include <string.h>
#include <string>
#include <vector>
extern uint32_t testMillis;
extern unsigned analogReads;
extern std::array<uint16_t, 8> analogInputs;
extern std::array<bool, 20> pinOutputs;
static const uint8_t A0 = 0, A1 = 1, A2 = 2, A3 = 3, A6 = 6, A7 = 7;
static const uint8_t LOW = 0, HIGH = 1, OUTPUT = 1;
struct __FlashStringHelper {};
#define F(text) reinterpret_cast<const __FlashStringHelper *>(text)
inline uint32_t millis() { return testMillis; }
inline int analogRead(uint8_t pin) {
  ++analogReads;
  return analogInputs[pin];
}
inline void digitalWrite(uint8_t pin, uint8_t value) {
  pinOutputs[pin] = value != 0;
}
inline void pinMode(uint8_t, uint8_t) {}
struct TestSerial {
  std::vector<std::string> lines;
  void begin(int) {}
  int availableForWrite() { return 64; }
  void println(const char *text) { lines.emplace_back(text); }
  void println(const __FlashStringHelper *text) {
    println(reinterpret_cast<const char *>(text));
  }
};
extern TestSerial Serial;

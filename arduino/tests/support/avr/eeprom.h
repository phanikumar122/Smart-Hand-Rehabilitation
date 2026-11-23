#pragma once
#include "EEPROM.h"
inline bool eeprom_is_ready() {
  return int32_t(testMillis - EEPROM.busyUntil) >= 0;
}

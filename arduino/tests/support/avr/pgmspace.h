#pragma once
#include <string.h>
#define PROGMEM
using PGM_P = const char *;
inline uint8_t pgm_read_byte(const void *p) {
  return *static_cast<const uint8_t *>(p);
}
inline char *strcpy_P(char *dest, const char *source) {
  return strcpy(dest, source);
}

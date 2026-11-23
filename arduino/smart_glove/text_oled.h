#ifndef SMART_GLOVE_TEXT_OLED_H
#define SMART_GLOVE_TEXT_OLED_H
#include <Wire.h>
#include <avr/pgmspace.h>

// Five-column glyphs stored in flash. No framebuffer or dynamic allocation.
static const uint8_t SG_FONT[][5] PROGMEM = {{0x3E, 0x51, 0x49, 0x45, 0x3E},
                                             {0, 0x42, 0x7F, 0x40, 0},
                                             {0x42, 0x61, 0x51, 0x49, 0x46},
                                             {0x21, 0x41, 0x45, 0x4B, 0x31},
                                             {0x18, 0x14, 0x12, 0x7F, 0x10},
                                             {0x27, 0x45, 0x45, 0x45, 0x39},
                                             {0x3C, 0x4A, 0x49, 0x49, 0x30},
                                             {1, 0x71, 9, 5, 3},
                                             {0x36, 0x49, 0x49, 0x49, 0x36},
                                             {6, 0x49, 0x49, 0x29, 0x1E},
                                             {0x7E, 0x11, 0x11, 0x11, 0x7E},
                                             {0x7F, 0x49, 0x49, 0x49, 0x36},
                                             {0x3E, 0x41, 0x41, 0x41, 0x22},
                                             {0x7F, 0x41, 0x41, 0x22, 0x1C},
                                             {0x7F, 0x49, 0x49, 0x49, 0x41},
                                             {0x7F, 9, 9, 9, 1},
                                             {0x3E, 0x41, 0x49, 0x49, 0x7A},
                                             {0x7F, 8, 8, 8, 0x7F},
                                             {0, 0x41, 0x7F, 0x41, 0},
                                             {0x20, 0x40, 0x41, 0x3F, 1},
                                             {0x7F, 8, 0x14, 0x22, 0x41},
                                             {0x7F, 0x40, 0x40, 0x40, 0x40},
                                             {0x7F, 2, 0x0C, 2, 0x7F},
                                             {0x7F, 4, 8, 0x10, 0x7F},
                                             {0x3E, 0x41, 0x41, 0x41, 0x3E},
                                             {0x7F, 9, 9, 9, 6},
                                             {0x3E, 0x41, 0x51, 0x21, 0x5E},
                                             {0x7F, 9, 0x19, 0x29, 0x46},
                                             {0x46, 0x49, 0x49, 0x49, 0x31},
                                             {1, 1, 0x7F, 1, 1},
                                             {0x3F, 0x40, 0x40, 0x40, 0x3F},
                                             {0x1F, 0x20, 0x40, 0x20, 0x1F},
                                             {0x3F, 0x40, 0x38, 0x40, 0x3F},
                                             {0x63, 0x14, 8, 0x14, 0x63},
                                             {7, 8, 0x70, 8, 7},
                                             {0x61, 0x51, 0x49, 0x45, 0x43},
                                             {0, 0x36, 0x36, 0, 0},
                                             {8, 8, 8, 8, 8},
                                             {0x40, 0x40, 0x40, 0x40, 0x40}};

class TextOled {
public:
  bool begin() {
    Wire.begin();
    Wire.setClock(100000);
    Wire.setWireTimeout(2500, true);
    static const uint8_t init[] PROGMEM = {
        0xAE, 0xD5, 0x80, 0xA8, 0x3F, 0xD3, 0,    0x40, 0x8D,
        0x14, 0x20, 0x02, 0xA1, 0xC8, 0xDA, 0x12, 0x81, 0xCF,
        0xD9, 0xF1, 0xDB, 0x40, 0xA4, 0xA6, 0x2E, 0xAF};
    Wire.beginTransmission(0x3C);
    Wire.write(uint8_t(0));
    for (uint8_t i = 0; i < sizeof(init); ++i)
      Wire.write(pgm_read_byte(init + i));
    active_ = Wire.endTransmission() == 0;
    return active_;
  }
  bool active() const { return active_; }
  void setRow(uint8_t page, const char *text) {
    memset(row_, 0, sizeof(row_));
    strncpy(row_, text, sizeof(row_) - 1);
    column_ = 0;
    page_ = page;
  }
  bool rowDone() const { return column_ >= 128; }
  void step() {
    if (!active_ || rowDone())
      return;
    Wire.beginTransmission(0x3C);
    Wire.write(uint8_t(0));
    Wire.write(uint8_t(0xB0 | page_));
    Wire.write(uint8_t(column_ & 15));
    Wire.write(uint8_t(0x10 | (column_ >> 4)));
    if (Wire.endTransmission() != 0) {
      active_ = false;
      return;
    }
    Wire.beginTransmission(0x3C);
    Wire.write(uint8_t(0x40));
    for (uint8_t i = 0; i < 16; ++i) {
      uint8_t x = column_ + i, cell = x / 6, sub = x % 6, value = 0;
      if (cell < 21 && sub < 5) {
        char c = row_[cell];
        uint8_t glyph = 255;
        if (c >= '0' && c <= '9')
          glyph = c - '0';
        else if (c >= 'A' && c <= 'Z')
          glyph = c - 'A' + 10;
        else if (c == ':')
          glyph = 36;
        else if (c == '-')
          glyph = 37;
        else if (c == '_')
          glyph = 38;
        if (glyph != 255)
          value = pgm_read_byte(&SG_FONT[glyph][sub]);
      }
      Wire.write(value);
    }
    if (Wire.endTransmission() != 0 || Wire.getWireTimeoutFlag()) {
      active_ = false;
      Wire.clearWireTimeoutFlag();
    }
    column_ += 16;
  }

private:
  char row_[22] = {};
  uint8_t column_ = 128, page_ = 0;
  bool active_ = false;
};
#endif

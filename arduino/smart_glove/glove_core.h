#ifndef SMART_GLOVE_GLOVE_CORE_H
#define SMART_GLOVE_GLOVE_CORE_H

#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#ifdef __AVR__
#include <avr/pgmspace.h>
#define SG_P(text) PSTR(text)
#define SG_COMPARE(text, literal) strcmp_P(text, PSTR(literal))
#define SG_PREFIX(text, literal, count) strncmp_P(text, PSTR(literal), count)
#define SG_SNPRINTF(buffer, capacity, format, ...)                             \
  snprintf_P(buffer, capacity, PSTR(format), __VA_ARGS__)
#else
#define SG_P(text) (text)
#define SG_COMPARE(text, literal) strcmp(text, literal)
#define SG_PREFIX(text, literal, count) strncmp(text, literal, count)
#define SG_SNPRINTF(buffer, capacity, format, ...)                             \
  snprintf(buffer, capacity, format, __VA_ARGS__)
#endif

// This core has no Arduino, heap, GPIO or wall-clock dependency.
inline bool elapsed(uint32_t now, uint32_t then, uint32_t interval) {
  return uint32_t(now - then) >= interval;
}

struct Calibration {
  uint16_t open[5], closed[5];
  uint16_t gripBase, gripOn, gripOff;
  bool valid;
};

static const uint16_t minimumFlexSpan = 30;

inline bool validCalibration(const Calibration &c) {
  if (c.gripBase > 1023 || c.gripOn > 1023 || c.gripOn <= c.gripOff)
    return false;
  for (uint8_t i = 0; i < 5; ++i) {
    int16_t span = int16_t(c.closed[i]) - int16_t(c.open[i]);
    if (c.open[i] > 1023 || c.closed[i] > 1023 ||
        (span > -int16_t(minimumFlexSpan) && span < int16_t(minimumFlexSpan)))
      return false;
  }
  return true;
}

// Explicit little-endian format; never persist native struct padding.
struct CalibrationRecord {
  static const uint8_t size = 34;
  static uint16_t read16(const uint8_t *b) {
    return uint16_t(b[0]) | uint16_t(b[1]) << 8;
  }
  static void write16(uint8_t *b, uint16_t v) {
    b[0] = uint8_t(v);
    b[1] = uint8_t(v >> 8);
  }
  static uint16_t crc(const uint8_t *b, uint8_t count) {
    uint16_t value = 0xFFFF;
    while (count--) {
      value ^= uint16_t(*b++) << 8;
      for (uint8_t i = 0; i < 8; ++i)
        value = value & 0x8000 ? uint16_t((value << 1) ^ 0x1021)
                               : uint16_t(value << 1);
    }
    return value;
  }
  static bool newer(uint16_t a, uint16_t b) {
    return a != b && uint16_t(a - b) < 0x8000;
  }
  static void encode(const Calibration &c, uint16_t seq, uint8_t *b) {
    memset(b, 0, size);
    b[0] = 0xA5;
    b[1] = 0x4E;
    b[2] = 1;
    b[3] = c.valid ? 1 : 0;
    write16(b + 4, seq);
    for (uint8_t i = 0; i < 5; ++i) {
      write16(b + 6 + i * 2, c.open[i]);
      write16(b + 16 + i * 2, c.closed[i]);
    }
    write16(b + 26, c.gripBase);
    write16(b + 28, c.gripOn);
    write16(b + 30, c.gripOff);
    write16(b + 32, crc(b, 32));
  }
  static bool decode(const uint8_t *b, Calibration &c, uint16_t &seq) {
    if (b[0] != 0xA5 || b[1] != 0x4E || b[2] != 1 || b[3] > 1 ||
        read16(b + 32) != crc(b, 32))
      return false;
    Calibration parsed = {};
    parsed.valid = b[3] == 1;
    for (uint8_t i = 0; i < 5; ++i) {
      parsed.open[i] = read16(b + 6 + i * 2);
      parsed.closed[i] = read16(b + 16 + i * 2);
    }
    parsed.gripBase = read16(b + 26);
    parsed.gripOn = read16(b + 28);
    parsed.gripOff = read16(b + 30);
    if ((parsed.valid && !validCalibration(parsed)) || parsed.gripBase > 1023 ||
        parsed.gripOn > 1023 || parsed.gripOn <= parsed.gripOff)
      return false;
    c = parsed;
    seq = read16(b + 4);
    return true;
  }
};

struct SensorFrame {
  uint16_t raw[6], filtered[6];
  uint8_t angle[5];
  uint16_t grip, gripDelta;
};

class GloveCore {
public:
  static const uint16_t sampleInterval = 20;
  static const uint16_t motorLimit =
      1000; // Bench defaults, not clinical limits.
  static const uint16_t cooldown = 2000;
  static const uint16_t leaseLimit = 3000;
  static const uint8_t calibrationSamples = 64;
  static const uint8_t filterDivisor = 8; // EMA alpha = 1 / divisor.
  static_assert(calibrationSamples >= 50 && calibrationSamples <= 100,
                "Calibration requires 50..100 samples");
  static_assert(filterDivisor >= 2 && filterDivisor <= 64 &&
                    (filterDivisor & (filterDivisor - 1)) == 0,
                "EMA divisor must be a power of two in 2..64");
  static const uint8_t stableSpread = 25;
  static const uint8_t bendOn = 40, bendOff = 15;
  explicit GloveCore(void (*sink)(const char *)) : emit_(sink) {
    memset(&active_, 0, sizeof(active_));
    active_.gripOn = 80;
    active_.gripOff = 40;
    candidate_ = active_;
    memset(&frame_, 0, sizeof(frame_));
    memset(ema_, 0, sizeof(ema_));
    memset(onSince_, 0, sizeof(onSince_));
    memset(offSince_, 0, sizeof(offSince_));
    rx_[0] = previousCommand_[0] = previousReply_[0] = '\0';
  }
  void load(const Calibration &c) {
    active_ = c;
    if (active_.valid && !validCalibration(active_))
      active_.valid = false;
    candidate_ = active_;
    saved_ = active_.valid;
  }
  const SensorFrame &frame() const { return frame_; }
  bool telemetryReady() const { return filterReady_; }
  const Calibration &calibration() const { return active_; }
  const Calibration &pendingCalibration() const { return candidate_; }
  bool manualMode() const { return manual_; }
  bool gripActive() const { return gripActive_; }
  uint8_t outputMask() const { return effective_; }
  uint8_t timeoutMask() const { return tripped_; }
  bool calibrating() const {
    return phase_ == Open || phase_ == Closed || phase_ == Saving;
  }
  bool saveRequested() const { return saveRequested_; }
  bool receivingCommand() const { return receiving_; }
  const char *phaseName() const {
    switch (phase_) {
    case Open:
      return "OPEN";
    case Closed:
      return "CLOSED";
    case OpenReady:
      return "OPEN_READY";
    case Ready:
      return "READY";
    case Saving:
      return "SAVING";
    case Failed:
      return "FAILED";
    default:
      return "IDLE";
    }
  }
  void sensorCsv(char *b, size_t capacity) const {
    SG_SNPRINTF(b, capacity, "%u,%u,%u,%u,%u,%u", unsigned(frame_.angle[0]),
                unsigned(frame_.angle[1]), unsigned(frame_.angle[2]),
                unsigned(frame_.angle[3]), unsigned(frame_.angle[4]),
                unsigned(frame_.grip));
  }
  void receive(char byte, uint32_t now) {
    if (byte == '<') {
      if (receiving_)
        rawError("MALFORMED");
      receiving_ = true;
      overflow_ = false;
      length_ = 0;
      rxTime_ = now;
      return;
    }
    if (!receiving_)
      return;
    rxTime_ = now;
    if (byte == '>') {
      receiving_ = false;
      if (overflow_) {
        rawError("OVERSIZED");
        return;
      }
      rx_[length_] = '\0';
      handle(rx_, now);
      return;
    }
    if (byte < 32 || byte > 126 || length_ >= sizeof(rx_) - 1) {
      overflow_ = true;
      return;
    }
    if (!overflow_)
      rx_[length_++] = byte;
  }
  void tick(uint32_t now) {
    if (receiving_ && elapsed(now, rxTime_, 250)) {
      receiving_ = false;
      length_ = 0;
      rawError("INCOMPLETE");
    }
    if (manual_ && leaseArmed_ && elapsed(now, leaseTime_, leaseLimit)) {
      manualRequest_ = 0;
      leaseArmed_ = false;
      effective_ = 0;
      emitConstant(SG_P("EVT,LINK,LEASE_EXPIRED,0"));
    }
    apply(now);
  }
  void sample(const uint16_t *raw, uint32_t now) {
    for (uint8_t i = 0; i < 6; ++i) {
      frame_.raw[i] = raw[i] > 1023 ? 1023 : raw[i];
      if (!filterReady_)
        ema_[i] = frame_.raw[i] * filterDivisor;
      else
        ema_[i] =
            uint16_t(ema_[i] - (ema_[i] + filterDivisor / 2) / filterDivisor +
                     frame_.raw[i]);
      frame_.filtered[i] = (ema_[i] + filterDivisor / 2) / filterDivisor;
    }
    filterReady_ = true;
    for (uint8_t i = 0; i < 5; ++i) {
      int32_t angle = 0;
      if (active_.valid)
        angle = (int32_t(frame_.filtered[i]) - active_.open[i]) * 90 /
                (int32_t(active_.closed[i]) - active_.open[i]);
      frame_.angle[i] = angle < 0 ? 0 : angle > 90 ? 90 : uint8_t(angle);
    }
    frame_.grip = frame_.filtered[5];
    frame_.gripDelta =
        frame_.grip > active_.gripBase ? frame_.grip - active_.gripBase : 0;
    if (frame_.gripDelta >= active_.gripOn)
      gripActive_ = true;
    else if (frame_.gripDelta <= active_.gripOff)
      gripActive_ = false;
    for (uint8_t i = 0; i < 5; ++i) {
      uint8_t bit = uint8_t(1 << i);
      if (!active_.valid)
        automatic_ &= uint8_t(~bit);
      else if (gripActive_ || frame_.angle[i] >= bendOn)
        automatic_ |= bit;
      else if (frame_.angle[i] <= bendOff)
        automatic_ &= uint8_t(~bit);
    }
    if (phase_ == Open || phase_ == Closed)
      collectCalibration();
    tick(now);
  }
  void finishSave(bool success) {
    commandId_ = savingId_;
    saveRequested_ = false;
    if (success) {
      active_ = candidate_;
      saved_ = active_.valid;
      phase_ = Idle;
      // Sampling during the write used the old calibration. Do not apply
      // those requests or publish that frame under the newly committed state.
      automatic_ = 0;
      gripActive_ = false;
      filterReady_ = false;
      reply("ACK", "CAL", resetting_ ? "RESET" : "SAVED", true);
    } else {
      phase_ = Failed;
      reply("ERR", "CAL", "EEPROM", true);
    }
  }

private:
  enum Phase : uint8_t { Idle, Open, Closed, OpenReady, Ready, Saving, Failed };
  Calibration active_, candidate_;
  SensorFrame frame_;
  uint16_t ema_[6];
  uint32_t sums_[6];
  uint16_t low_[6], low2_[6], high_[6], high2_[6];
  uint32_t onSince_[5], offSince_[5], leaseTime_ = 0, rxTime_ = 0;
  char rx_[32], previousCommand_[32], previousReply_[64];
  uint16_t commandId_ = 0, previousId_ = 0, savingId_ = 0;
  uint8_t length_ = 0, count_ = 0, automatic_ = 0, manualRequest_ = 0,
          effective_ = 0, tripped_ = 0;
  bool manual_ = false, saved_ = false, filterReady_ = false,
       gripActive_ = false;
  bool receiving_ = false, overflow_ = false, leaseArmed_ = false,
       saveRequested_ = false, resetting_ = false;
  Phase phase_ = Idle;
  void (*emit_)(const char *);

  void emitConstant(const char *text) {
#ifdef __AVR__
    char line[64];
    strcpy_P(line, text);
    emit_(line);
#else
    emit_(text);
#endif
  }
  void replyConstant(const char *type, const char *topic, const char *detail,
                     bool remember = true) {
    char line[64];
#ifdef __AVR__
    snprintf_P(line, sizeof(line), PSTR("%S,%u,%S,%S"), type,
               unsigned(commandId_), topic, detail);
#else
    snprintf(line, sizeof(line), "%s,%u,%s,%s", type, unsigned(commandId_),
             topic, detail);
#endif
    if (remember && commandId_) {
      strcpy(previousReply_, line);
    }
    emit_(line);
  }
  void rawError(const char *reason) {
    char line[48];
    SG_SNPRINTF(line, sizeof(line), "ERR,0,CMD,%s", reason);
    emit_(line);
  }
  void sendStatus() {
    char detail[48];
    SG_SNPRINTF(detail, sizeof(detail), "3.0,%s,%u,%s,%u,%u",
                manual_ ? "MANUAL" : "AUTO", unsigned(active_.valid),
                phaseName(), unsigned(saved_), unsigned(effective_));
    reply("ACK", "STATUS", detail);
  }
  void reply(const char *type, const char *topic, const char *detail,
             bool remember = true) {
    char line[64];
    SG_SNPRINTF(line, sizeof(line), "%s,%u,%s,%s", type, unsigned(commandId_),
                topic, detail);
    if (remember && commandId_) {
      strncpy(previousReply_, line, sizeof(previousReply_) - 1);
      previousReply_[sizeof(previousReply_) - 1] = '\0';
    }
    emit_(line);
  }
  void apply(uint32_t now) {
    uint8_t requested = phase_ != Idle ? 0
                        : manual_      ? manualRequest_
                        : active_.valid && filterReady_ ? automatic_
                                                        : 0;
    for (uint8_t i = 0; i < 5; ++i) {
      const uint8_t bit = uint8_t(1 << i);
      if ((effective_ & bit) && elapsed(now, onSince_[i], motorLimit)) {
        effective_ &= uint8_t(~bit);
        tripped_ |= bit;
        offSince_[i] = now;
        char line[48];
        SG_SNPRINTF(line, sizeof(line), "EVT,VIB,%u,TIMEOUT,%u",
                    unsigned(i + 1), unsigned(effective_));
        emit_(line);
      }
      if (!(requested & bit)) {
        effective_ &= uint8_t(~bit);
        if ((tripped_ & bit) && elapsed(now, offSince_[i], cooldown))
          tripped_ &= uint8_t(~bit);
      } else if (!(tripped_ & bit) && !(effective_ & bit)) {
        effective_ |= bit;
        onSince_[i] = now;
      }
    }
  }
  void startCalibration(Phase phase) {
    phase_ = phase;
    manualRequest_ = 0;
    automatic_ = 0;
    effective_ = 0;
    count_ = 0;
    memset(sums_, 0, sizeof(sums_));
    for (uint8_t i = 0; i < 6; ++i) {
      low_[i] = low2_[i] = 1023;
      high_[i] = high2_[i] = 0;
    }
  }
  void collectCalibration() {
    for (uint8_t i = 0; i < 6; ++i) {
      uint16_t v = frame_.raw[i];
      sums_[i] += v;
      if (v <= low_[i]) {
        low2_[i] = low_[i];
        low_[i] = v;
      } else if (v < low2_[i])
        low2_[i] = v;
      if (v >= high_[i]) {
        high2_[i] = high_[i];
        high_[i] = v;
      } else if (v > high2_[i])
        high2_[i] = v;
    }
    if (++count_ < calibrationSamples)
      return;
    bool open = phase_ == Open;
    for (uint8_t i = 0; i < (open ? 6 : 5); ++i) {
      if (high2_[i] - low2_[i] > stableSpread) {
        phase_ = Failed;
        emitConstant(open ? SG_P("EVT,CAL,OPEN,UNSTABLE")
                          : SG_P("EVT,CAL,CLOSED,UNSTABLE"));
        return;
      }
    }
    Calibration next = candidate_;
    for (uint8_t i = 0; i < 5; ++i) {
      uint16_t avg =
          uint16_t((sums_[i] - low_[i] - high_[i]) / (calibrationSamples - 2));
      if (open)
        next.open[i] = avg;
      else
        next.closed[i] = avg;
    }
    if (open) {
      next.gripBase =
          uint16_t((sums_[5] - low_[5] - high_[5]) / (calibrationSamples - 2));
      candidate_ = next;
      phase_ = OpenReady;
      emitConstant(SG_P("EVT,CAL,OPEN,DONE"));
    } else if (!validCalibration(next)) {
      phase_ = OpenReady;
      emitConstant(SG_P("EVT,CAL,CLOSED,INVALID_SPAN"));
    } else {
      next.valid = true;
      candidate_ = next;
      phase_ = Ready;
      emitConstant(SG_P("EVT,CAL,CLOSED,DONE"));
    }
  }
  void handle(char *text, uint32_t now) {
    commandId_ = 0;
    char *payload = text;
    if (SG_PREFIX(text, "Q:", 2) == 0) {
      char *p = text + 2;
      uint32_t id = 0;
      uint8_t digits = 0;
      while (*p >= '0' && *p <= '9' && digits < 5) {
        id = id * 10 + uint8_t(*p++ - '0');
        ++digits;
      }
      if (!digits || *p != ':' || id == 0 || id > 65535) {
        rawError("BAD_ID");
        return;
      }
      commandId_ = uint16_t(id);
      payload = p + 1;
      if (commandId_ == previousId_) {
        if (strcmp(previousCommand_, payload) != 0) {
          replyConstant(SG_P("ERR"), SG_P("CMD"), SG_P("ID_REUSE"), false);
          return;
        }
        leaseTime_ = now;
        if (SG_COMPARE(payload, "STATUS") == 0 ||
            SG_COMPARE(payload, "CAL:STATUS") == 0 ||
            SG_COMPARE(payload, "PING") == 0) {
          sendStatus();
          return;
        }
        if (previousReply_[0]) {
          // Cached acceptance must not resurrect a state that has timed out.
          if (SG_PREFIX(previousReply_, "ACK,", 4) == 0 &&
              (SG_PREFIX(payload, "VIB:", 4) == 0 ||
               SG_PREFIX(payload, "MODE:", 5) == 0)) {
            char *lastComma = strrchr(previousReply_, ',');
            if (lastComma)
              SG_SNPRINTF(lastComma + 1,
                          size_t(previousReply_ + sizeof(previousReply_) -
                                 lastComma - 1),
                          "%u", unsigned(effective_));
          }
          emit_(previousReply_);
        }
        return;
      }
      if (phase_ == Saving && SG_COMPARE(payload, "VIB:ALL,0") != 0) {
        replyConstant(SG_P("ERR"), SG_P("CMD"), SG_P("BUSY"), false);
        return;
      }
      if (phase_ != Saving) {
        previousId_ = commandId_;
        strcpy(previousCommand_, payload);
        previousReply_[0] = '\0';
      }
    }
    if (phase_ == Saving && SG_COMPARE(payload, "VIB:ALL,0") != 0) {
      replyConstant(SG_P("ERR"), SG_P("CMD"), SG_P("BUSY"));
      return;
    }
    if (SG_COMPARE(payload, "STATUS") == 0 ||
        SG_COMPARE(payload, "CAL:STATUS") == 0 ||
        SG_COMPARE(payload, "PING") == 0) {
      leaseTime_ = now;
      sendStatus();
      return;
    }
    if (SG_COMPARE(payload, "MODE:AUTO") == 0 ||
        SG_COMPARE(payload, "MODE:MANUAL") == 0) {
      manual_ = SG_COMPARE(payload, "MODE:MANUAL") == 0;
      manualRequest_ = 0;
      leaseArmed_ = manual_;
      leaseTime_ = now;
      // Changing modes must not clear a safety trip.
      apply(now);
      char detail[20];
      SG_SNPRINTF(detail, sizeof(detail), "%s,%u", manual_ ? "MANUAL" : "AUTO",
                  unsigned(effective_));
      reply("ACK", "MODE", detail);
      return;
    }
    if (SG_PREFIX(payload, "VIB:", 4) == 0) {
      char *target = payload + 4;
      char *comma = strchr(target, ',');
      if (!comma) {
        replyConstant(SG_P("ERR"), SG_P("VIB"), SG_P("BAD_TARGET"));
        return;
      }
      uint8_t mask = 0;
      size_t targetSize = size_t(comma - target);
      if (targetSize == 3 && SG_PREFIX(target, "ALL", 3) == 0)
        mask = 31;
      else if (targetSize == 1 && target[0] >= '1' && target[0] <= '5')
        mask = uint8_t(1 << (target[0] - '1'));
      else {
        replyConstant(SG_P("ERR"), SG_P("VIB"), SG_P("BAD_TARGET"));
        return;
      }
      if ((comma[1] != '0' && comma[1] != '1') || comma[2] != '\0') {
        replyConstant(SG_P("ERR"), SG_P("VIB"), SG_P("BAD_STATE"));
        return;
      }
      const bool on = comma[1] == '1';
      if (phase_ != Idle && (on || mask != 31)) {
        replyConstant(SG_P("ERR"), SG_P("VIB"), SG_P("CALIBRATING"));
        return;
      }
      if (on && (mask & tripped_)) {
        replyConstant(SG_P("ERR"), SG_P("VIB"), SG_P("REARM_REQUIRED"));
        return;
      }
      if (!manual_)
        manualRequest_ = 0;
      manual_ = true;
      leaseArmed_ = true;
      leaseTime_ = now;
      if (on)
        manualRequest_ |= mask;
      else
        manualRequest_ &= uint8_t(~mask);
      apply(now);
      char detail[24];
      // AVR libc does not support '*' precision in printf formats.
      if (mask == 31)
        SG_SNPRINTF(detail, sizeof(detail), "ALL,%c,%u", comma[1],
                    unsigned(effective_));
      else
        SG_SNPRINTF(detail, sizeof(detail), "%c,%c,%u", target[0], comma[1],
                    unsigned(effective_));
      // All-off is allowed during a save without evicting its replay entry.
      reply("ACK", "VIB", detail, phase_ != Saving);
      return;
    }
    if (SG_COMPARE(payload, "CAL:OPEN") == 0) {
      if (calibrating()) {
        replyConstant(SG_P("ERR"), SG_P("CAL"), SG_P("BUSY"));
        return;
      }
      candidate_ = active_;
      startCalibration(Open);
      replyConstant(SG_P("ACK"), SG_P("CAL"), SG_P("OPEN,STARTED"));
      return;
    }
    if (SG_COMPARE(payload, "CAL:CLOSED") == 0) {
      if (phase_ != OpenReady) {
        replyConstant(SG_P("ERR"), SG_P("CAL"), SG_P("OPEN_REQUIRED"));
        return;
      }
      startCalibration(Closed);
      replyConstant(SG_P("ACK"), SG_P("CAL"), SG_P("CLOSED,STARTED"));
      return;
    }
    if (SG_COMPARE(payload, "CAL:SAVE") == 0) {
      if (phase_ != Ready || !validCalibration(candidate_)) {
        replyConstant(SG_P("ERR"), SG_P("CAL"), SG_P("INVALID_SPAN"));
        return;
      }
      resetting_ = false;
      savingId_ = commandId_;
      phase_ = Saving;
      saveRequested_ = true;
      effective_ = 0;
      return;
    }
    if (SG_COMPARE(payload, "CAL:RESET") == 0) {
      if (calibrating()) {
        replyConstant(SG_P("ERR"), SG_P("CAL"), SG_P("BUSY"));
        return;
      }
      memset(&candidate_, 0, sizeof(candidate_));
      candidate_.gripOn = 80;
      candidate_.gripOff = 40;
      manualRequest_ = automatic_ = effective_ = 0;
      resetting_ = true;
      savingId_ = commandId_;
      phase_ = Saving;
      saveRequested_ = true;
      return;
    }
    if (SG_COMPARE(payload, "CAL:CANCEL") == 0) {
      candidate_ = active_;
      phase_ = Idle;
      manualRequest_ = automatic_ = effective_ = 0;
      replyConstant(SG_P("ACK"), SG_P("CAL"), SG_P("CANCELLED"));
      return;
    }
    replyConstant(SG_P("ERR"), SG_P("CMD"), SG_P("UNKNOWN"));
  }
};
#endif

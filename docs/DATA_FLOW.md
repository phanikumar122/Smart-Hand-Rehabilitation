# Data flow and runtime state

## Firmware boundary

`smart_glove.ino` owns actual ADC, GPIO, SoftwareSerial, Wire, EEPROM and USB diagnostic operations. `glove_core.h` owns bounded framing, complete command validation, filtering, signed movement mapping, calibration, automatic/manual requests, effective outputs, timers and record encoding. It has no Arduino dependency or heap allocation and is executed directly in host tests. `text_oled.h` streams text to the SSD1306 in 16-column slices, retaining only one 22-byte text row and a cached display snapshot.

Runtime pipeline:

```text
ADC six-channel acquisition (20 ms nominal)
    -> independently initialized integer EMA
    -> one SensorFrame: raw, filtered, movement, grip ADC, grip delta
        -> automatic haptic requests -> mode/safety arbitration -> GPIO writer
        -> CSV serialization / Bluetooth and USB diagnostics
        -> snapshot used by all eight OLED text rows
```

Only acquisition reads the ADC. Bluetooth/OLED/haptic functions consume cached values. Display snapshots can be older than the latest transmitted frame because the display refresh is slower; compare the same acquisition values rather than assuming simultaneous displays.

## Scheduling and backpressure

| Work | Schedule |
|---|---|
| Sample/filter/map/haptics | Every 20 ms nominal, phase retained by unsigned subtraction |
| Bluetooth commands | Every loop, at most 16 buffered bytes per receive pass |
| Haptic safety/GPIO | Before/after loop work and after processing commands/samples |
| Sensor telemetry | Every 100 ms nominal, skipped when control traffic or saving occupies TX |
| OLED snapshot | Every 250 ms nominal, transfer one slice during idle windows |
| EEPROM | At most one update per 5 ms pass, only when hardware ready |
| USB diagnostics | Every 10 s, `DIAG,MISSED,count,OLED,0|1` |

Scheduler skips missed acquisition periods and counts them instead of emitting artificial catch-up samples. All timing comparisons use unsigned subtraction and are rollover-safe at supported intervals. There are no normal-operation delay calls. SoftwareSerial byte transmission and Wire calls still occupy CPU time; they are bounded, not hardware full-duplex or hard real-time guarantees. Firmware avoids TX while receiving a marked command. The app prefers receive windows following complete telemetry frames, with bounded fallback/retry offsets.

Three fixed 64-byte outgoing slots bound response memory. Sensor frames never form a backlog. Timeout events are coalesced per finger outside the FIFO and eventually emit the current output mask. FIFO overflow drops the excess response and later emits a LINK error; the app shows unknown output until refreshed. Malformed serial traffic cannot bypass motor safety.

The OLED initializes at 0x3C/100 kHz and uses AVR Wire's 2500 microsecond timeout. A failed initialization/transfer disables display work while sensors/control continue. RX indicator means recently received serial bytes, not confirmed physical Bluetooth connection. Increase I2C speed only after measuring the installed bus.

## Memory and persistence

Firmware uses fixed arrays and fixed-width arithmetic; no recurring Arduino String, substring, heap allocation or concatenation. Protocol comparisons/formats and long constant responses are stored in AVR flash; OLED glyphs/init data are in PROGMEM. TX lines, parser and replay data are bounded. Debug strings use F(). The original full OLED framebuffer is removed.

Compile for the selected Nano variant and record the flash/SRAM figures printed by Arduino CLI. Static headroom is not proof of worst-case stack behavior. Host AddressSanitizer/UndefinedBehaviorSanitizer tests verify the exercised memory/arithmetic paths. Measure stack headroom and reset behavior on AVR under malformed RX, five motor trips, calibration, EEPROM saves and OLED faults before qualification.

EEPROM records have explicit little-endian encoding, version, sequence, CRC and commit-last magic. Two slots preserve the prior record if the destination save is interrupted. Reset commits a newer invalid/default record. See calibration guide for layout and recovery rules.

## App connection and protocol lifecycle

`GloveConnection` still isolates the existing flutter_classic_bluetooth transport. `GloveDataProvider` bounds/assembles byte lines and dispatches sensor frames separately from ACK/ERR/EVT. After connection it requests STATUS, and polls once per second when the command slot is idle. Requested motor bits and firmware-reported output bits are separate; writing/flushing is not confirmation.

Only an ACK matching request ID and expected command fields completes a pending command. Error/timeout/disconnect fails it without assuming requested output occurred. Native write/flush has a one-second deadline; a transport stall closes/quarantines the link because Dart Future.timeout does not cancel an underlying native operation. Retry uses the same ID and up to three attempts; firmware duplicate suppression does not extend motor timers or redo captures/saves. Reconnection reads authoritative status and does not replay old pending ON commands. Manual lease expires in firmware if refresh stops.

If initial STATUS fails, sensor streaming remains visible but upgraded recording/haptic controls remain gated. Explicit legacy mode in Settings restores the old six-field recording and exact VIB-byte behavior without claiming ACK support. It is cleared on disconnect.

## Live data, sessions and storage

Existing semantics are retained:

- A connection is live only after a valid six-field sensor frame less than 1.5 seconds old; watchdog runs every 500 ms.
- ACK/status/timeout traffic never refreshes sensor freshness or enters measured history.
- History is an immutable view of at most 3000 readings/five minutes.
- Sessions require fresh signal, no active/saving session and, for upgraded firmware, a sample received after valid IDLE calibration was confirmed. A stale signal, invalid/unknown calibration or disconnect ends an active session at its last accepted reading. Recording does not resume automatically.
- Calibration commands are blocked during app recording. Only frames received after session start contribute to metrics.
- Maximum grip is maximum filtered ADC; average movement is the integer mean across five fingers and received frames. Six-field order/ranges and stored schema remain compatible.
- Zero-reading sessions are discarded; navigation does not reset provider-owned timers.
- Disconnect clears signal/history/buffers and pending commands, stops recording and saves only sessions with readings.
- Existing reconnect preference/retry limit (three attempts, two seconds apart) and SharedPreferences storage remain. Malformed or out-of-range saved records are skipped, deletion reports persistent storage failure, and the Android backup/transfer rules exclude these preferences.

Settings exposes firmware version, validity and guided capture/save/reset/cancel. Haptic panel shows requested state while sending and output reported by ACK/events/status. Safety/errors use text and accessible live-region feedback. Wrap/scroll layouts preserve large-text behavior.

## Automated coverage versus hardware

`arduino/tests/run_tests.py` runs the real core and real sketch with doubles only for electrical/runtime boundaries. It tests parsing/recovery/fuzz, calibration/noise/spans, filtering/direction/ranges, hysteresis, manual separation, rearm/lease/timer rollover, duplicate semantics, GPIO mapping, scheduling, bounded Wire writes, display failure, CRC and interrupted EEPROM journaling. Firmware compilation separately checks AVR compatibility.

Flutter tests cover split/interleaved lines, matching and malformed responses, pending/confirmed/error/timeout/disconnect states, calibration gating/workflow, missing status, stale-signal behavior, measured history/session storage/reconnect and widget/large-text layouts. These do not reproduce HC-05/HC-06 interrupt timing or actual analog/electrical behavior. Physical qualification is defined in the bench guide.

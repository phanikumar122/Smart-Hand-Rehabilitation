# Glove calibration and tuning

Use the assembled glove only after its motor-driver wiring and supplies have passed the hardware checks. This workflow measures each sensor's relative movement range; it does not establish clinical joint angles or force in newtons.

## First use

1. Fit the glove and route wires with strain relief. Verify each channel responds to its intended finger and unloaded grip is stable.
2. Pair/connect the Bluetooth module. Open app Settings and find **Glove calibration**. Firmware should report `3.0`.
3. Hold a comfortable open hand with no pressure on the FSR. Tap **Capture open hand** and hold still until completion, approximately 1.3 seconds.
4. Bend each finger through a comfortable intended exercise range. Do not force a fully closed hand. Tap **Capture bent hand** and hold still until completion.
5. Tap **Save calibration**. Wait for confirmed saving and then refreshed valid firmware status.
6. Move each finger independently, check open near 0 and calibrated bend near 90, then verify grip response. Recording is available only with fresh sensor data, valid active calibration and an IDLE calibration workflow.

All motors are inhibited while capturing, waiting between captures, saving or handling a failed workflow. Stop a recording before starting calibration. **Cancel calibration** discards the candidate and restores the previous active calibration; there is no EEPROM write. **Reset calibration** writes an invalid/default record and requires a new open/bent/save workflow. Boot never assumes fabricated finger endpoints are valid.

## Capture validation

Each capture collects 64 samples per channel at a nominal 20 ms interval. It sums raw readings, removes one minimum and one maximum sample, and averages the remaining 62. The second-lowest/second-highest spread must be <=25 ADC counts, allowing one obvious high/low spike while rejecting sustained movement. The open capture includes the unloaded FSR; bent capture validates five flex channels without requiring stable grip pressure.

Every flex endpoint is `0..1023`; absolute open-to-bent span must be >=30 ADC counts. Both increasing and decreasing sensor directions work. A failed bent span retains the open candidate for retry. An unstable capture requires a new open capture or cancel. Previous valid active/EEPROM calibration remains intact until a successfully validated candidate is committed.

Mapping per finger is signed `(filtered - open) * 90 / (closed - open)`, constrained to `0..90`. A limited comfortable calibration range can map to 90 without implying 90 degrees of anatomical motion. Recalibrate after changing sensor position, glove fit, dividers, user or supply characteristics. Calibration has no user identity association in EEPROM.

## Persistence

EEPROM uses two 34-byte records at addresses 0 and 34: magic `A5 4E`, version 1, validity byte, 16-bit sequence, five open endpoints, five bent endpoints, grip baseline/ON/OFF deltas, CRC-16/CCITT-FALSE (initial FFFF, polynomial 1021), all multibyte values little endian. CRC covers bytes 0–31.

The inactive destination is invalidated before its body is written and its first magic byte is committed last. Writes use `EEPROM.update`, at most one byte per scheduled 5 ms pass while EEPROM is ready. Final readback precedes the save/reset ACK. A reset is a newer invalid record, so reboot does not resurrect an older valid calibration. Invalid magic/version/CRC/spans are rejected; newest validly encoded record is selected, or safe uncalibrated defaults are used. Power-loss recovery is tested with a hardware double and still requires physical power-interruption tests.

## Tuning defaults

| Parameter | Starting value | Where/meaning |
|---|---:|---|
| Sampling | 20 ms | `GloveCore::sampleInterval` |
| EMA smoothing | 1/8 | `filterDivisor = 8`, scaled integer accumulator, initialized from first sample |
| Samples/capture | 64 | `calibrationSamples`; compile-time constrained to 50–100 |
| Stable trimmed spread | 25 ADC | `stableSpread` |
| Minimum flex span | 30 ADC | `minimumFlexSpan` |
| Bend ON/OFF | 40/15 | Normalized movement hysteresis |
| Grip ON/OFF | 80/40 ADC delta | Constructor/reset defaults and EEPROM fields |
| Continuous motor ON | 1000 ms | `motorLimit` |
| Rearm cooldown | 2000 ms | `cooldown` |
| Manual lease | 3000 ms | `leaseLimit` |

At 50 Hz, EMA 1/8 has an approximately 150 ms time constant and 450 ms 95% step-settling time. Small ADC quantization/rounding remains. Measure unloaded noise and loaded step response before adjusting. Grip ON must exceed OFF, and both must be physically reachable above the installed baseline. The documented FSR divider increases ADC with pressure; reverse-polarity grip wiring needs a coordinated calculation change, not guessed absolute values.

Do not tune haptics by leaving motors continuously energized. Start with low-current bench checks, verify limits and temperature, and choose exercise thresholds/durations with appropriate electrical and rehabilitation expertise.

## Troubleshooting

- **UNSTABLE:** hold still; check motor noise, loose wiring, ground routing, supply stability and sensor mounting. Do not simply increase spread until a noisy circuit is accepted.
- **INVALID_SPAN:** check the appropriate channel and mounting; increase the comfortable test movement or correct divider selection. Do not invent a 150-count range.
- **EEPROM:** keep power stable; cancel/retry only after the save has finished; inspect reboot/readback behavior.
- **Firmware status unavailable:** check baud, wiring and firmware version; refresh/reconnect. Do not enable legacy mode to mask failures in a 3.0 glove.
- **REARM_REQUIRED:** release bend/grip in AUTO, or send OFF in MANUAL; wait at least two seconds after the trip, then request ON again.

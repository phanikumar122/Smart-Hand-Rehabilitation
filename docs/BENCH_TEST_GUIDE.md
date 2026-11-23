# Bench and long-duration qualification

Compilation and host/app tests are separate from testing the assembled glove. No physical-glove test has been performed for this upgrade. Record board/bootloader, sensor/divider parts, motor/driver/diode parts, regulator/battery ratings, firmware/app revisions, phone/module versions, ambient temperature and measurement equipment before starting.

## Electrical bench sequence

1. Disable motor power; inspect all five protected driver circuits, diode orientation, pulldowns, grounds and insulation. Measure actual logic/module supply rails and GPIO voltage levels.
2. Confirm motor-rated supply voltage/current capacity from datasheets and measured startup current. Verify default OFF at power-on/reset and during boot/upload.
3. Capture raw ADC noise and open/bent range per finger and unloaded/loaded FSR values. Exercise each channel alone to detect wiring swaps/crosstalk. Use USB diagnostics plus an instrumented ADC log or debugger for raw readings; the six-field production packet carries normalized movement/filtered grip only.
4. Test each motor individually using MANUAL and then all five together. Scope motor rail, Nano rail, switch node and HC-05 RX divider. Verify flyback behavior and no brownouts/resets. Measure driver/motor/regulator temperatures over repeated pulses within ratings.
5. Test with OLED absent and with I2C fault injection appropriate to the hardware. Sensor/control operation must continue. Do not short a supply to create a bus fault.

## Functional and timing tests

Use a physical Android device and a logic analyzer/oscilloscope on D2/D3 and driver GPIO. For sampling timing, use a debugger or a temporary instrumented spare-pin sample marker; this must be reviewed against the pin map and removed from the production build. USB packets alone measure transmission, not 50 Hz acquisition timing.

| Test | Required observation |
|---|---|
| Open/bent/save | Stable independent endpoints, both sensor directions where installed, correct finger order, valid status after save/reboot |
| Unstable capture/short span | Candidate rejected, previous valid calibration retained, app explains recovery |
| Corrupt EEPROM/interrupted save | Latest complete record or previous complete record selected; reset remains invalid after reboot |
| AUTO | Bend/grip hysteresis without chatter; motor output and bend text independent |
| MANUAL | Sensor changes cannot overwrite manual output requests |
| Repeated ON/mode/retry | Continuous motor ON limit cannot be extended by repeated commands |
| Timeout/rearm | GPIO turns off at limit plus measured loop latency; ON cannot resume until release/cooldown |
| Calibration phases | All motors OFF during capture, between captures, failure and saving |
| Link loss/app background/kill | Motor pulses remain bounded; MANUAL lease expires; app invalidates pending/confirmed state as appropriate |
| Split/malformed/burst RX | Strict errors/recovery without resets, starvation or unexpected motor activation |
| Full load | Sampling/transmission jitter and command retries remain within accepted limits with five motors/OLED active |
| Freshness | ACK/status-only traffic cannot keep stale sensor values visible or start a session |
| Reconnect | Pending ON commands are not replayed; authoritative mode/calibration/output status replaces guesses |

Start with engineering targets and record actual distributions, not just one successful interaction. Suggested initial bench targets: approximately 20 ms sampling with no skipped periods in steady nominal operation; sustained telemetry near 10 Hz outside control bursts; command ACK 95th percentile under 250 ms and no unexplained timeout in 1000 paced command transactions. These are qualification targets, not measured guarantees. Log max sample gap, lost/skipped frames, retry count, median/95th/max command latency, resets and temperature. If the existing SoftwareSerial link cannot meet the chosen limits, revise the UART/controller architecture rather than calling it deterministic hard real-time.

Every 10 seconds USB emits `DIAG,MISSED,count,OLED,0|1`. MISSED counts scheduler periods skipped rather than sampled; it is not an end-to-end Bluetooth loss counter. An absent display deliberately reports OLED=0. These lines are USB-only and do not alter Bluetooth sensor packets.

## Long-duration soak

Run at least 24 hours as an initial engineering trial, then 72 hours under the intended use conditions if temperatures/duty limits permit. Exercise sensor traffic and paced commands continuously, with controlled motor pulses respecting ratings, repeated reconnects, app background/resume, low-battery/regulator transitions and OLED faults. Do not leave a powered wearable on a person for the soak test.

Measure minimum stack headroom/high-water usage on AVR with appropriate instrumentation, not only static linker SRAM figures. Stress maximum-length malformed input, response queues, five simultaneous trips, calibration and EEPROM saving. Record SRAM margin, MCU resets/watchdog behavior, skipped samples, radio errors, unacknowledged commands, rail voltages and temperatures throughout. EEPROM endurance testing should not repeatedly save at sampling rate; normal code only writes on explicit save/reset and suppresses duplicate transactions.

Acceptance requires no unexplained reset, unexpected energization, progressive memory deterioration or unbounded queue growth, and recorded timing/noise/temperature limits appropriate to the verified hardware. Any failure needs a reproducible log and a regression test where feasible.

## Professional review and known limits

Electrical component/current/thermal/battery validation and clinical suitability remain independent work. Flex calibration normalizes relative sensor response; mounting, user motion, sensor hysteresis and supply variation affect accuracy. FSR is not a calibrated clinical pressure/force instrument. SoftwareSerial is half duplex with possible collision/loss; ACK GPIO confirmation is not motor-motion feedback. Link lease detects app traffic, not exact radio disconnection. No firmware hardware watchdog has been added, so externally induced CPU lockup/reset electrical OFF behavior must be checked. Firmware/application changes alone do not establish medical safety certification.

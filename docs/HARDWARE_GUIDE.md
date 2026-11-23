# Smart Glove App hardware guide — Classic Nano glove

This guide documents the firmware's pin map and the circuits required to build it. Repository documents identify the intended Nano, sensors, HC-05/HC-06 and SSD1306, but do **not** establish the installed motor model/current, exact supply rating, MOSFET/transistor part numbers, battery protection or physical bootloader. Verify those details on the actual assembly and record measurements in the bench log.

## Firmware and app used with this wiring

Upload the complete `arduino/smart_glove` folder: `smart_glove.ino`, `glove_core.h` and `text_oled.h` are all required. The firmware targets the Classic Nano/ATmega328P; select the actual board's modern or old bootloader in Arduino IDE/CLI. It uses the AVR core's Wire, EEPROM and SoftwareSerial libraries; external Adafruit display libraries are not required.

On startup, motor outputs are initialized OFF before peripherals, then stored calibration is checked. There is no single-reading, three-second startup calibration. With **Smart Glove App**, connect the glove and use **Settings → Glove calibration** to capture open hand with unloaded FSR, capture comfortable bent hand, and save. Outputs remain inhibited throughout the calibration workflow. Use the updated app's AUTO/MANUAL controls; the OLED's `SG3` label identifies the 3.0 firmware.

Before the first powered motor test, disable the motor supply and verify all five driver circuits below. After confirming voltage/current ratings and electrical OFF behavior, enable the supply and follow the [bench procedure](BENCH_TEST_GUIDE.md). The complete [setup guide](SETUP_GUIDE.md) covers upload, Android installation and pairing.

## Controller and complete pin map

Use a Classic Nano or ATmega328P-compatible board with A6 and A7 physically exposed. SRAM is 2 KB. A board with only A0–A5 cannot accommodate this map unchanged.

| Signal | Nano pin | Notes |
|---|---|---|
| Thumb flex | A0 | ADC voltage divider |
| Index flex | A1 | ADC voltage divider |
| Middle flex | A2 | ADC voltage divider |
| Ring flex | A3 | ADC voltage divider |
| Pinky flex | A6 | Analog-only input on Classic Nano |
| Grip FSR | A7 | Analog-only input on Classic Nano |
| Bluetooth module TXD | D2 | SoftwareSerial receive |
| Bluetooth module RXD | D3 | SoftwareSerial transmit, protected divider |
| OLED SDA | A4 | I2C |
| OLED SCL | A5 | I2C |
| Thumb motor driver | D11 | ON/OFF control, not direct motor power |
| Index motor driver | D10 | Independent driver |
| Middle motor driver | D9 | Independent driver |
| Ring motor driver | D6 | Independent driver |
| Pinky motor driver | D5 | Independent driver |
| USB diagnostics/upload | D0/D1 hardware UART | Bluetooth uses D2/D3, not these pins |

A4/A5 are reserved for the OLED. Verify board markings and finger order before wiring.

## Sensor dividers

The documented starting circuit is:

```text
regulated sensor supply ── sensor ──+── ADC input
                                   |
                                 10 kΩ
                                   |
                                  GND
```

10 kΩ is a starting divider value, not a universal requirement. Select from actual sensor resistance curves to obtain a stable, unsaturated ADC span. Confirm voltage never exceeds the MCU supply/reference range. Keep the analog source impedance within the ADC datasheet's acquisition requirements or add suitable settling/buffering. Measure channel-to-channel coupling before accepting the sampling rate.

Flex ADC can increase or decrease with bending; signed two-point calibration handles both. With the FSR in the shown top position, falling resistance under load normally raises ADC. Firmware grip logic assumes that increasing direction and computes positive delta above an averaged unloaded baseline. Reverse wiring requires a deliberate calculation change. Do not claim force units without an independent load-cell/reference calibration.

Use short analog wires, secure connectors and strain relief. Avoid sharp flex-sensor creases or mounting that restricts joint motion.

## Bluetooth

| Module pin | Connection |
|---|---|
| VCC | Supply specified for the actual breakout; regulator-equipped boards often accept 5 V, bare modules may not |
| GND | Shared ground |
| TXD | Nano D2 |
| RXD | Nano D3 via divider |

A common 5 V TX protection divider:

```text
Nano D3 ── 1 kΩ ──+── module RXD
                   |
                  2 kΩ
                   |
                  GND
```

This divides 5 V to approximately 3.33 V. Verify the module's RX absolute maximum and HIGH threshold, actual resistor tolerances and line waveform. Module TX is generally 3.3 V; confirm that it meets the ATmega328P input HIGH threshold for the installed voltage.

Set the module's **data-mode UART** baud to 9600. HC-05 AT-command baud can differ from data-mode baud; follow the exact module documentation. The STATE pin is not used. OLED RX indication and manual-control lease show recent app/serial activity, not an electrically measured Bluetooth connection.

## OLED

SSD1306 128×64, I2C address 0x3C, SDA A4, SCL A5. Check module supply and pull-up voltage requirements. Firmware uses 100 kHz and a bounded Wire timeout; inspect rise times and existing parallel pull-ups before considering 400 kHz. OLED initialization/transfer failure disables display work without stopping sensor/control operation.

Rows show mode/activity, five finger movement/bend/output values, grip ADC/delta and calibration/timeout status. `B/F` derives from movement threshold; `V/-` derives from effective motor output, independently.

## Five independent motor drivers

**Never power a vibration motor directly from GPIO. Never assume the Nano's small regulator can supply all five motors.** Replicate the following low-side circuit for D11, D10, D9, D6 and D5:

```text
motor-rated supply + ─────+────────── motor +
                         |              motor
                   diode cathode        motor - ───+── MOSFET drain
                         |                           |
                    flyback diode ─── diode anode ───+

Nano GPIO ── gate resistor ── MOSFET gate
                               |
                         gate pulldown
                               |
MOSFET source ──────────────────+── common GND
```

The flyback diode is directly across the motor: **cathode/stripe to supply positive, anode to switched motor negative/drain**. It is reverse biased during normal operation. Place diode and local decoupling close to the driver/motor loop.

Use a logic-level N-channel MOSFET with RDS(on) specified at the actual gate voltage (approximately 5 V for this Nano), not merely a low gate-threshold voltage. Select drain voltage rating with transient margin, continuous/pulsed current ratings above measured start/stall demand, safe operating area and thermal resistance suitable for the enclosure. Estimate conduction loss as `I² × RDS(on)` at worst-case temperature; verify case/junction temperature experimentally. A small logic-level part such as an AO3400-family device can be considered only after checking the exact manufacturer's datasheet and actual load/thermal layout; it is not a blanket rating recommendation.

Gate resistor 100–330 Ω and pulldown 47–100 kΩ are typical starting ranges for slow ON/OFF control; verify switching waveform, GPIO current and EMI. Pulldown must hold the gate OFF during reset/disconnected control. Firmware startup OFF complements, but does not replace, this electrical OFF state.

A suitable BJT (for example an appropriately rated BC337/PN2222A variant) is an alternative for small verified loads. Size base current for saturation at worst start/stall current using the device datasheet's forced gain, then `Rbase ≈ (Vgpio − VBE(sat)) / Ibase`. Check GPIO per-pin/group/chip current limits and BJT heating (`VCE(sat) × I`). Use an emitter-to-ground connection and base pulldown. Prefer MOSFETs if required base currents burden the MCU. Part labels across vendors do not guarantee identical ratings.

Diode selection must cover repetitive motor current/freewheel energy, reverse voltage and temperature. Fast or Schottky devices may suit small motors when their exact ratings fit. Do not select solely by appearance or an assumed universal motor current.

## Supply, ground and decoupling

Record each motor's rated voltage, running current, measured start/stall current and duty/temperature constraints. Size the supply for simultaneous startup of **all five** motors plus electronics and a justified transient margin. AUTO grip activation can switch all five together. Use motor-rated voltage regulation; do not apply 5 V to an unverified 3 V motor.

All logic, sensor, Bluetooth, OLED, driver and motor-supply grounds must share a reference. Route high-current motor returns directly toward the supply/star ground, not through thin analog/MCU ground paths. Keep motor leads away from flex/FSR wiring; twisting motor pairs and short switching loops reduce noise. Verify voltage drop with all motors active.

Use local ceramic decoupling (100 nF is a typical starting value) near logic/module supplies, with low-ESR bulk capacitance on the motor rail sized from measured transient demand. A first estimate is `C >= ΔI × Δt / allowed ΔV`; ESR adds immediate voltage drop. Values such as 100–470 µF are only initial bench choices, not substitutes for a supply that can support startup current. Suppression at motor terminals and optional analog RC filtering require measured noise/latency tuning.

If using a battery, verify chemistry, protection/BMS, fuse/current limiting, charging circuit, enclosure and regulator voltage/current/thermal ratings. An unregulated single cell is not automatically a suitable Nano sensor/reference supply. VIN linear-regulator dissipation is approximately `(VIN − 5 V) × logic current`; motor power must not pass through an inadequate Nano regulator. Follow the board's external-power/USB backfeed guidance before connecting both supplies.

## Assembly and verification order

1. Identify the actual board/module/motor/supply components from markings and datasheets.
2. With motor supply disabled, verify supply rails, shorts, polarity and default driver OFF states.
3. Validate one sensor channel, then all six, including ADC span/noise/crosstalk.
4. Verify OLED address and Bluetooth 9600 data-mode link.
5. Test one driver/current/diode waveform, then replicate and test all five independently.
6. Verify combined-start supply behavior, MCU resets and analog noise.
7. Perform open/bent/save calibration, then haptic mode/rearm/disconnect checks.
8. Mount on a glove only after bench electrical tests; insulate exposed nodes and add strain relief.

See [Bench Test Guide](BENCH_TEST_GUIDE.md) for acceptance measurements and [Calibration Guide](CALIBRATION_GUIDE.md) for fitting/tuning. Qualified electrical review and appropriate clinical review remain necessary before supervised rehabilitation deployment; this project has no medical certification.

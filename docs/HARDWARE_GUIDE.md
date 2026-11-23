# NerveLink Hardware and Wiring Guide

This guide documents the hardware expected by `arduino/smart_glove/smart_glove.ino`.

> **Safety notice:** This is a prototype, not a certified medical device. Disconnect power while wiring. Use motor driver transistors and flyback protection; do not connect vibration motors directly to microcontroller GPIO pins. Use a regulated, current-appropriate power source.

## 1. Bill of materials

| Component | Quantity | Purpose |
|---|---:|---|
| Arduino Nano-compatible board with A6/A7 | 1 | Sensor processing and control |
| HC-05 or HC-06 Bluetooth module | 1 | Android Bluetooth Classic SPP link |
| Flex sensor | 5 | One per finger |
| Force-sensitive resistor (FSR) | 1 | Grip pressure input |
| 10 kΩ resistor | 6 | Flex/FSR voltage dividers |
| Coin vibration motor | 5 | One per finger |
| Logic-level transistor/MOSFET | 5 | Motor drivers |
| Flyback diode suitable for the motor | 5 | Motor transient protection |
| Gate/base resistor and pull-down as needed | 5 sets | Stable motor switching |
| SSD1306 128×64 I²C OLED | 1 | Local glove status |
| 1 kΩ and 2 kΩ resistors | 1 each | HC-05 RX voltage divider when using a 5 V board |
| Regulated USB power bank or suitable battery system | 1 | Portable power |
| Glove, flexible wire, connectors, insulation | As needed | Wearable assembly |

The earlier one-motor circuit is not sufficient for this firmware: it controls five independent motor outputs.

## 2. Firmware pin map

### Analog sensors

| Input | Arduino pin |
|---|---|
| Thumb flex | A0 |
| Index flex | A1 |
| Middle flex | A2 |
| Ring flex | A3 |
| Pinky flex | A6 |
| Grip FSR | A7 |

Each sensor uses a voltage divider:

```text
5 V ── sensor ──┬── analog input
                │
               10 kΩ
                │
               GND
```

Sensor orientation and resistor value can affect whether bending increases or decreases the ADC reading. The firmware uses the absolute difference from startup baseline.

### Bluetooth module

| HC-05/HC-06 pin | Arduino connection |
|---|---|
| VCC | Supply required by the module breakout (commonly 5 V) |
| GND | Common GND |
| TXD | D2 — SoftwareSerial RX |
| RXD | D3 — SoftwareSerial TX through a voltage divider on 5 V boards |

The firmware does not use the module’s STATE pin.

Logic-level protection for HC-05 RX:

```text
Arduino D3 ── 1 kΩ ──┬── HC-05 RXD
                     │
                    2 kΩ
                     │
                    GND
```

The HC-05 TXD signal can normally connect directly to a 5 V Arduino input because its 3.3 V HIGH is recognized.

### OLED display

| OLED pin | Arduino Nano pin |
|---|---|
| VCC | Module-rated supply |
| GND | Common GND |
| SDA | A4 |
| SCL | A5 |

The firmware expects I²C address `0x3C`.

### Vibration motors

| Finger | Control pin |
|---|---|
| Thumb | D11 |
| Index | D10 |
| Middle | D9 |
| Ring | D6 |
| Pinky | D5 |

Recommended low-side driver per motor:

```text
Motor supply + ── motor ──┬── transistor drain/collector
                          │
                    flyback diode
                          │
GPIO ── resistor ── gate/base
Transistor source/emitter ── GND
```

Connect all grounds together. Size the power supply and wiring for the combined current when all five motors are active.

## 3. Assembly sequence

1. Prototype one flex sensor and confirm stable analog readings.
2. Add all flex sensors and the FSR with a common ground.
3. Add the OLED and confirm address `0x3C`.
4. Test the HC-05/HC-06 at 9600 baud.
5. Build and test one protected motor driver.
6. Replicate the driver for all five motors.
7. Upload the firmware and verify USB debug frames.
8. Mount electronics on the glove only after bench testing.
9. Add strain relief and insulate all exposed connections.

## 4. Sensor placement

- Mount flex sensors along the back of each finger.
- Do not sharply crease or puncture a flex sensor.
- Place the active bending region over the finger joints.
- Route wires toward the wrist with enough slack for safe movement.
- Place the FSR where the selected exercise applies pressure, typically the palm or a grip contact point.
- Position vibration motors where feedback is clear without restricting circulation or joint movement.

## 5. Startup calibration

On power-up, the OLED displays:

```text
CALIBRATING...
Keep hand FLAT
```

Keep every finger in the neutral flat position for three seconds. The firmware captures one baseline value per flex sensor. Restart the glove if the hand moved during this step.

The current firmware does not persist calibration across restarts and does not average several baseline samples.

## 6. Firmware behavior

- HC-05/HC-06 baud: `9600`
- USB debug baud: `115200`
- Sensor frames: every `100 ms`
- OLED refresh: every `200 ms`
- Finger angles: mapped to `0..90`
- Grip value: raw ADC `0..1023`

The force threshold is `50`. When pressure exceeds the threshold, the firmware activates all five motors. Otherwise, each motor uses bend hysteresis:

- Turn on at delta `40` or greater
- Turn off at delta `15` or less

App commands can also set individual or all motor outputs. Because automatic sensor logic continues every loop, it may subsequently change a commanded motor state.

## 7. Bench verification

Open Serial Monitor at 115200 baud. After calibration, expect output similar to:

```text
USB Debug: 0,5,14,8,2,37
```

Confirm:

- Six values appear on each line.
- The first five remain within `0..90`.
- Grip remains within `0..1023`.
- Each flex value responds to the correct finger.
- Motor commands target the correct output.
- OLED readings match serial readings.

## 8. Troubleshooting

### OLED does not initialize

- Confirm SDA is A4 and SCL is A5.
- Scan for the actual I²C address; change `0x3C` if necessary.
- Check supply voltage requirements.

### Bluetooth pairs but sends no data

- Confirm module baud is 9600.
- Cross TX/RX correctly: module TXD → Arduino D2, module RXD ← Arduino D3.
- Verify common ground.
- Confirm valid output in USB Serial Monitor first.

### A finger stays near 0° or 90°

- Check its voltage divider and A0/A1/A2/A3/A6 pin.
- Restart with the hand flat.
- Inspect for a damaged or sharply bent sensor.
- Adjust the firmware’s `map(delta, 0, 150, 0, 90)` range for the installed sensor.

### Motors reset the board or disturb readings

- Do not power motors from GPIO.
- Use a separate adequately rated motor supply with common ground.
- Add flyback diodes and local decoupling.
- Keep motor wiring away from analog sensor wiring.

### Upload fails

- Select the correct board, processor, and COM port.
- Close Serial Monitor before upload.
- D2/D3 SoftwareSerial normally does not interfere with USB upload, but disconnect the Bluetooth module if power or wiring problems persist.

## 9. Recommended improvements

For a more robust future revision:

- Average multiple calibration samples.
- Store calibration ranges in EEPROM.
- Replace dynamic Arduino `String` construction with fixed buffers.
- Add acknowledgements for haptic commands.
- Separate automatic haptic behavior from remote-control mode.
- Add battery monitoring and electrical isolation review.
- Validate the complete system with qualified rehabilitation professionals before clinical use.
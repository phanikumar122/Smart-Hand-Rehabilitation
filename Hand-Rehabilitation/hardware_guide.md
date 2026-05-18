# Smart Assistive Glove - Hardware & Wiring Guide

This document contains all the necessary instructions to physically build the Smart Assistive Glove. 

## 1. Component List

| Component | Quantity | Purpose |
| :--- | :--- | :--- |
| **Arduino Nano** | 1 | Microcontroller to process analog signals and send data via Bluetooth. |
| **HC-05 Bluetooth Module** | 1 | Serial Bluetooth communication to Android device. |
| **Flex Sensors (2.2" or 4.5")** | 5 | Measure the bend of the 5 fingers. |
| **FSR (Force Sensitive Resistor)**| 1 | Measure grip pressure in the palm or fingertips. |
| **10kΩ Resistors** | 6 | Pull-down resistors for the 5 flex sensors and 1 FSR. |
| **Vibration Motor (Coin Type)** | 1 | Haptic feedback for rehabilitation targets. |
| **2N2222 NPN Transistor** | 1 | To safely drive the vibration motor. |
| **1N4001 Diode (or similar)** | 1 | Flyback diode to protect the Arduino from voltage spikes from the motor. |
| **1kΩ & 2kΩ Resistors** | 1 each | Voltage divider for the HC-05 RX pin. |
| **1kΩ Resistor** | 1 | Base resistor for the transistor. |
| **Battery Pack (e.g. 9V or Powerbank)**| 1 | Portable power for the glove. |
| **Glove & Wires** | 1 set | Mounting substrate and connections. |

## 2. Wiring & Pin Mapping

> [!WARNING]
> Ensure all power is disconnected while wiring to prevent short circuits.

### Flex Sensors & FSR (Analog Inputs)
Each flex sensor and the FSR requires a voltage divider circuit.
- Connect **one pin** of the sensor to Arduino **5V**.
- Connect the **other pin** of the sensor to an **Analog Pin** AND to a **10kΩ resistor** connected to **GND**.

| Sensor | Arduino Pin | Resistor to GND |
| :--- | :--- | :--- |
### OLED Display (0.96" SSD1306)
The OLED provides real-time status feedback directly on the glove.

| OLED Pin | Arduino Pin |
| :--- | :--- |
| VCC | 5V |
| GND | GND |
| SCL | A5 |
| SDA | A4 |

### HC-05 Bluetooth Module
| HC-05 Pin | Connection |
| :--- | :--- |
| VCC | 5V |
| GND | GND |
| TX | Arduino **D2** (Software RX) |
| RX | Arduino **D3** (Software TX) via Voltage Divider |
| STATE | Arduino **D4** (Connection Check) |

### 5-Finger Vibration Feedback Circuit
- **Thumb Motor**  -> Arduino **D11**
- **Index Motor**  -> Arduino **D10**
- **Middle Motor** -> Arduino **D9**
- **Ring Motor**   -> Arduino **D6**
- **Pinky Motor**  -> Arduino **D5**

*Note: Connect the positive side of all motors to 5V, and the negative side to the Transistor collector.*

## 3. Power Management

- If powering via USB from a PC, the 5V line will provide adequate power for testing.
- For portable operation, a standard USB Powerbank connected to the Arduino Nano's Mini-B USB port is the safest and most reliable option. 
- Alternatively, you can use a 9V battery connected to the **VIN** and **GND** pins, but powerbanks are recommended due to higher current capacity and rechargeability.

## 4. Sensor Placement on Glove

1. **Flex Sensors**: Sew or glue small pockets onto the back of each finger of the glove. Slide the flex sensors inside. Ensure the active bending portion of the sensor aligns with the finger joints. 
2. **FSR**: Place the FSR on the palm or the inside tips of the index/middle fingers, depending on the specific grip exercise you want to monitor.
3. **Vibration Motor**: Mount the motor on the back of the hand or near the wrist strap. Ensure it sits tightly against the user's skin/glove for clear feedback.

## 5. Troubleshooting Tips

- **Bluetooth won't pair**: The default PIN for HC-05 is usually `1234` or `0000`.
- **Sensors read 0 or 1023 constantly**: Check for a disconnected wire or a missing 10kΩ pull-down resistor.
- **Code upload fails**: Disconnect the HC-05 from pins D0 and D1 while uploading. Reconnect after the upload finishes.
- **Values fluctuate wildly**: Check all ground connections. Ensure a single common ground across the entire circuit.

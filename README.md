# Smart Assistive Glove — Hand Rehabilitation & Movement Monitoring

An embedded rehabilitation system using flex sensors, vibration feedback, OLED monitoring, and Bluetooth communication.

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Hardware Components](#hardware-components)
- [System Architecture](#system-architecture)
- [Working Principle](#working-principle)
- [Bluetooth Data Format](#bluetooth-data-format)
- [Project Structure](#project-structure)

---

## Overview

The Smart Hand Rehabilitation Glove is a wearable embedded system designed to help users monitor finger movements and improve hand rehabilitation exercises through sensor-based interaction and haptic feedback.

The glove detects finger bending using flex sensors, measures grip pressure using a force sensor, and provides real-time vibration feedback to assist rehabilitation. The system communicates with a companion mobile application over Bluetooth, enabling live monitoring and remote control.

## Features

### Finger Movement Detection
- Individual finger tracking
- Real-time flex sensor monitoring
- Angle-based finger movement calculation
- Movement calibration support

### Haptic Feedback System
- Five-finger vibration motor support
- Pressure-triggered feedback
- Finger-specific vibration control
- Full-hand vibration mode

### OLED Display Integration
- Real-time glove status
- Finger angle visualization
- Pressure monitoring
- Active vibration indicators

### Bluetooth Communication
- Two-way communication
- Real-time sensor data transmission
- Mobile app integration
- Command-based vibration control

### Embedded System Features
- Auto-calibration on startup
- Stable sensor data flow
- Efficient CSV-based data transmission
- Real-time processing loop

## Hardware Components

| Component | Purpose |
|---|---|
| Arduino / ESP32 | Main controller |
| Flex Sensors | Finger bend detection |
| Force Sensor | Pressure sensing |
| Vibration Motors | Haptic feedback |
| OLED Display (SSD1306) | Live monitoring |
| HC-05 / HC-06 Bluetooth Module | Wireless communication |
| Battery Module | Power supply |

## System Architecture

**Movement sensing path:**
```
Flex Sensors
    ↓
Arduino / ESP32
    ↓
Sensor Processing
    ↓
Bluetooth Transmission
    ↓
Mobile Application
```

**Feedback path:**
```
Force Sensor
    ↓
Haptic Feedback System
    ↓
Vibration Motors
```

## Working Principle

1. **Finger Detection** — Flex sensors detect finger bending and generate analog output values.
2. **Signal Processing** — The Arduino/ESP32 processes raw sensor values and converts them into movement angles.
3. **Feedback System** — When movement or pressure thresholds are reached, the vibration motors activate and the OLED display updates with the current status.
4. **Bluetooth Communication** — Sensor data is transmitted to the mobile application in CSV format for live monitoring.

## Bluetooth Data Format

Sensor readings are transmitted as a comma-separated string:

```
Thumb,Index,Middle,Ring,Pinky,Pressure
```

Each field represents the corresponding sensor's current reading, sent continuously during operation.

## Project Structure

```
smart-hand-rehabilitation/
│
├── hardware/
│   ├── glove_circuit/
│   ├── sensor_modules/
│   ├── vibration_system/
│   └── arduino_code/
│
├── mobile_app/
│   ├── lib/
│   ├── screens/
│   ├── widgets/
│   └── bluetooth_services/
│
├── assets/
├── docs/
├── README.md
└── pubspec.yaml
```

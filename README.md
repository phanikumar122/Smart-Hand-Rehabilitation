Smart Assistive Glove for Hand Rehabilitation & Movement Monitoring

An embedded rehabilitation system using flex sensors, vibration feedback, OLED monitoring, and Bluetooth communication.

📌 Overview
The Smart Hand Rehabilitation Glove is a wearable embedded system designed to help users monitor finger movements and improve hand rehabilitation exercises through sensor-based interaction and haptic feedback.

The glove detects finger bending using flex sensors, measures pressure using a force sensor, and provides real-time vibration feedback for rehabilitation assistance.

The system communicates with a mobile application through Bluetooth, enabling live monitoring and control.

✨ Features:
🖐️ Finger Movement Detection

Individual finger tracking
Real-time flex sensor monitoring
Angle-based finger movement calculation
Movement calibration support

📳 Haptic Feedback System

5-finger vibration motor support
Pressure-triggered feedback
Finger-specific vibration control
Full-hand vibration mode

📟 OLED Display Integration

Real-time glove status
Finger angle visualization
Pressure monitoring
Active vibration indicators

📡 Bluetooth Communication

Two-way communication
Real-time sensor data transmission
Mobile app integration
Command-based vibration control

⚙️ Embedded System Features

Auto calibration on startup
Stable sensor data flow
Efficient CSV data transmission
Real-time processing loop


🛠️ Hardware Components
Component	Purpose
Arduino / ESP32	Main controller
Flex Sensors	Finger bend detection
Force Sensor	Pressure sensing
Vibration Motors	Haptic feedback
OLED Display (SSD1306)	Live monitoring
HC-05 / HC-06 Bluetooth	Wireless communication
Battery Module	Power supply


🔌 System Architecture
Flex Sensors
      ↓
Arduino / ESP32
      ↓
Sensor Processing
      ↓
Bluetooth Transmission
      ↓
Mobile Application

Force Sensor
      ↓
Haptic Feedback System
      ↓
Vibration Motors


📂 Project Structure
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


⚙️ Working Principle
1️⃣ Finger Detection

Flex sensors detect finger bending and generate analog values.

2️⃣ Signal Processing

Arduino processes sensor values and converts them into movement angles.

3️⃣ Feedback System

If movement or pressure thresholds are reached:

vibration motors activate
OLED updates live status
4️⃣ Bluetooth Communication

Sensor data is transmitted to the mobile application in CSV format.

📡 Bluetooth Data Format
Thumb,Index,Middle,Ring,Pinky,Pressure

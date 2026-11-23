# Smart Hand Rehabilitation

The app provides live biofeedback, guided recording sessions, progress charts, local session history, and direct haptic controls in an accessible light/dark interface.

> **Project status:** Functional prototype. It is intended for learning, experimentation, and supervised rehabilitation research—not diagnosis or unsupervised medical treatment.

## Highlights

- Five-finger bend tracking from `0°` to `90°`
- Grip pressure monitoring from `0` to `1023`
- Bluetooth Classic SPP connection on Android
- Live hand visualization and sensor detail
- Guided rehabilitation sessions with elapsed time and reading count
- Maximum grip and average movement summaries
- Local session history using SharedPreferences
- Finger-specific and all-hand haptic commands
- Automatic reconnect option
- Adaptive System / Light / Dark themes
- Responsive layouts and large-text support
- Stale-signal protection: old values are never presented as live data

## App navigation

| Destination | Purpose |
|---|---|
| **Today** | Connection status, live summary, finger mobility, and session shortcut |
| **Live** | Animated hand visualization, grip feedback, and individual sensor readings |
| **Session** | Start/stop recording, timer, live grip, and reading count |
| **Progress** | Live charts and saved rehabilitation sessions |

## Hardware

| Component | Quantity | Purpose |
|---|---:|---|
| Arduino Nano-compatible board | 1 | Reads sensors and runs glove firmware |
| HC-05 or HC-06 | 1 | Bluetooth Classic serial communication |
| Flex sensors | 5 | Thumb-to-pinky bend measurement |
| Force-sensitive resistor (FSR) | 1 | Grip pressure measurement |
| Vibration motors | 5 | Per-finger haptic feedback |
| SSD1306 OLED, 128×64 | 1 | On-glove status display |
| Driver transistors, flyback diodes, resistors | 5 sets | Safe motor switching |
| Glove, wiring, and suitable power source | 1 set | Wearable assembly |

See [Hardware Guide](docs/HARDWARE_GUIDE.md) for the complete pin map, wiring notes, calibration flow, and safety guidance.

## Bluetooth protocol

### Glove → app

The firmware sends one newline-terminated CSV frame every 100 ms:

```text
thumb,index,middle,ring,pinky,grip\n
```

Example:

```text
12,28,40,33,18,642
```

Validation rules:

- Exactly six decimal integers
- Each finger angle: `0..90`
- Grip pressure: `0..1023`
- Each frame ends with `\n`; `\r\n` is also accepted

### App → glove

Commands use start/end markers:

```text
<VIB:ALL,1>  # all motors on
<VIB:ALL,0>  # all motors off
<VIB:3,1>    # middle-finger motor on
<VIB:3,0>    # middle-finger motor off
```

Finger IDs are `1` through `5`: Thumb, Index, Middle, Ring, Pinky.

For buffering, validation, stale-data, reconnect, and session details, read [Data Flow](docs/DATA_FLOW.md).

## Requirements

- Flutter `3.50.1` or a compatible stable version
- Dart `3.14.0` or a compatible version allowed by `pubspec.yaml`
- Android Studio/SDK with Java 17
- Android device running API 24 or newer
- Data-capable USB cable for development
- Paired HC-05/HC-06 glove for live hardware testing
- Arduino IDE and the Adafruit GFX/SSD1306 libraries for firmware upload

The mobile connection uses Bluetooth Classic and is designed for a physical Android device. Chrome and Windows are useful for limited UI development but cannot validate the real HC-05/HC-06 workflow.

## Quick start

### 1. Clone and install dependencies

```bash
git clone https://github.com/phanikumar122/Smart-Hand-Rehabilitation.git
cd Smart-Hand-Rehabilitation
flutter pub get
```

### 2. Verify the project

```bash
flutter doctor -v
dart analyze lib test
flutter test
```

### 3. Connect an Android phone

1. Enable **Developer options** by tapping **Build number** seven times.
2. Enable **USB debugging**.
3. Connect the phone with a data-capable USB cable.
4. Select **File transfer** and accept the debugging authorization prompt.
5. Confirm detection:

```bash
flutter devices
```

### 4. Run the app

```bash
flutter run
```

If multiple devices are available:

```bash
flutter run -d <device-id>
```

For detailed setup and APK installation instructions, see [Setup Guide](docs/SETUP_GUIDE.md).

## Build an APK

Debug build:

```bash
flutter build apk --debug
```

Output:

```text
build/app/outputs/flutter-apk/app-debug.apk
```

Install through ADB:

```bash
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

> Release builds currently use the debug signing configuration. Configure a private release keystore before distributing the app publicly.

## Connect the glove

1. Power the glove while keeping the hand flat during the three-second calibration.
2. Pair the HC-05/HC-06 in Android Bluetooth settings. Common PINs are `1234` and `0000`.
3. Open NerveLink and grant Nearby devices/Bluetooth permissions.
4. Tap **Scan** or refresh paired devices.
5. Select the glove and tap **Connect**.
6. Wait for **Live signal** before starting a session.

The app intentionally blocks rehabilitation sessions until a valid recent sensor packet is received.

## Development commands

```bash
# Fetch dependencies
flutter pub get

# Format source and tests
dart format lib test

# Static analysis
dart analyze lib test

# Run every test
flutter test

# Build a debug Android package
flutter build apk --debug
```

## Project structure

```text
Smart-Hand-Rehabilitation/
├── android/                         # Android host project and permissions
├── arduino/
│   └── smart_glove/
│       └── smart_glove.ino          # Glove firmware
├── docs/
│   ├── DATA_FLOW.md                 # Protocol and runtime state flow
│   ├── HARDWARE_GUIDE.md            # Hardware, wiring, safety, calibration
│   └── SETUP_GUIDE.md               # Flutter and phone installation setup
├── lib/
│   ├── models/                      # Sensor and saved-session models
│   ├── providers/                   # Connection, parsing, and session state
│   ├── screens/                     # Connection and four app destinations
│   ├── services/                    # Bluetooth boundary and local storage
│   ├── theme/                       # Adaptive clinical design system
│   ├── widgets/                     # Reusable UI and haptic controls
│   └── main.dart
├── test/                            # Protocol, provider, and widget tests
├── .gitignore
├── pubspec.yaml
└── README.md
```

## Architecture

```text
Flex sensors + FSR
        │
        ▼
Arduino firmware ─────► OLED + vibration motors
        │
        │ newline-delimited CSV / Bluetooth Classic SPP
        ▼
GloveConnection service
        │
        ▼
GloveDataProvider
  ├── frame buffering and validation
  ├── live/stale signal state
  ├── reconnect lifecycle
  ├── haptic commands
  └── rehabilitation session metrics
        │
        ▼
Flutter UI + local session storage
```

## Troubleshooting

### Phone is not shown by `flutter devices`

- Use a data-capable cable and select File transfer.
- Keep the phone unlocked and accept the USB debugging prompt.
- Revoke USB debugging authorizations and reconnect.
- Install the manufacturer’s Windows USB driver if required.

### Glove is paired but not listed

- Grant Nearby devices permissions.
- Enable Bluetooth and, on Android 11 or earlier, Location services.
- Tap refresh after pairing in Android settings.
- Confirm the module supports Bluetooth Classic SPP.

### Connected but “No signal” remains

- Confirm the module is configured for 9600 baud.
- Use USB Serial Monitor at 115200 baud to verify six-value CSV output.
- Check that every frame ends with a newline.
- Verify all finger values are within `0..90` and grip within `0..1023`.

### Sensor readings are unstable

- Use a common ground for every sensor, motor driver, display, and Bluetooth module.
- Keep the hand flat during startup calibration.
- Inspect voltage dividers and loose flex-sensor connections.

## Privacy and limitations

- Session summaries are stored locally on the phone using SharedPreferences.
- The app does not currently provide cloud sync, user accounts, or clinician sharing.
- The firmware does not acknowledge motor state; the app displays the last command sent.
- A stale sensor packet is removed from the live UI after 1.5 seconds.
- Use suitable motor drivers and never power motors directly from GPIO pins.

## License

No open-source license has been added yet. Unless a license is provided, normal copyright restrictions apply.

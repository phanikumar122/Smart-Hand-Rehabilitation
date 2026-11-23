# Smart Glove App — Smart Hand Rehabilitation

Smart Glove App combines an Arduino Nano sensor glove and an Android Flutter app: five flex sensors, an FSR, five independently driven vibration motors, an SSD1306 OLED and HC-05/HC-06 Bluetooth Classic SPP.

**Status:** Engineering/research system with a coordinated 3.0 firmware protocol upgrade. Compilation and automated tests do not establish physical reliability, clinical accuracy or medical certification. Complete the bench and long-duration checks before describing this system as ready for deployment.

## Implemented behavior

- One cached six-sensor snapshot, lightweight independent filtering and nominal 50 Hz acquisition.
- Independent open/bent finger calibration; unloaded grip baseline; two-slot CRC-protected EEPROM persistence.
- AUTO/MANUAL haptic separation, bounded continuous ON time, release/cooldown rearming and manual app-activity lease.
- Strict bounded command parser and request-ID acknowledgements, errors and events.
- Unchanged six-integer sensor frames at nominal 10 Hz; grip remains filtered ADC `0..1023`.
- Incremental 128×64 OLED text without a 1024-byte framebuffer; movement and output state displayed independently.
- App requested/confirmed output separation, retries/timeouts, guided calibration and firmware status.
- Existing live-signal watchdog, measured history, recording metrics, local session storage, reconnection and accessible light/dark UI retained.

Finger values `0..90` are normalized sensor movement estimates, not independently validated joint angles. FSR ADC is not pressure/force in clinical units.

## Guides

| Guide | Contents |
|---|---|
| [Hardware](docs/HARDWARE_GUIDE.md) | Exact pin map, five protected drivers, supplies, component-selection calculations |
| [Setup](docs/SETUP_GUIDE.md) | Flutter/Android setup, exact Nano compile/upload choices, running/installing the app |
| [Calibration](docs/CALIBRATION_GUIDE.md) | Open/bent/save workflow, failure recovery, persistence and tuning |
| [Protocol](docs/PROTOCOL.md) | Complete sensor, command, ACK/ERR/EVT formats and mode/safety semantics |
| [Data flow](docs/DATA_FLOW.md) | Scheduling, memory, app lifecycle and session compatibility |
| [Bench and soak tests](docs/BENCH_TEST_GUIDE.md) | Physical acceptance measurements and long-duration qualification |

## Requirements and development

Flutter 3.50.1 / Dart 3.14.0 (or compatible versions allowed by pubspec), Android SDK and Java 17, physical Android device API 24+, Arduino CLI/IDE with Arduino AVR core 1.8.6, Classic Nano/ATmega328P exposing A6/A7. Firmware depends only on core EEPROM, SoftwareSerial and Wire; Adafruit GFX/SSD1306 packages are no longer required.

```powershell
flutter pub get
dart format lib test
dart analyze lib test
flutter test
flutter build apk --debug
arduino-cli core install arduino:avr@1.8.6
arduino-cli compile --fqbn arduino:avr:nano:cpu=atmega328 --warnings all arduino/smart_glove
```

For an old-bootloader Nano, select `arduino:avr:nano:cpu=atmega328old`. Do not guess the bootloader or COM port; see the setup guide. Host firmware tests require Python 3 and a GNU-compatible C++ compiler:

```bash
python3 arduino/tests/run_tests.py
```

On Windows with Ubuntu WSL and g++ installed, from this repository:

```powershell
wsl -d Ubuntu -- python3 arduino/tests/run_tests.py
```

APK output is `build/app/outputs/flutter-apk/app-debug.apk` (ignored by Git). Install/run:

```powershell
adb install -r build/app/outputs/flutter-apk/app-debug.apk
flutter devices
flutter run
```

## First connection

1. Verify the protected motor-driver circuits and power supply on the bench. Never power a motor directly from GPIO or assume the Nano regulator can supply five motors.
2. Upload firmware and power the glove. Pins start OFF; valid stored calibration is loaded. There is no blind three-second startup baseline capture.
3. Pair HC-05/HC-06 in Android settings and connect in Smart Glove App. Grant Bluetooth/Nearby devices permissions (and Location when required on older Android).
4. In app Settings, confirm firmware status, capture open hand with unloaded FSR, capture comfortable bent hand and save.
5. Wait for valid status and Live signal before recording. Use Manual mode for direct motor checks; release/OFF and wait after a timeout.

Navigation remains Today, Live, Session and Progress; calibration/connection preferences are in Settings. Session summaries stay local in SharedPreferences with their existing schema. Nothing is uploaded to a server.

## Compatibility and limitations

The sensor frame is still `thumb,index,middle,ring,pinky,grip\n`, with exactly six integers. Original VIB commands remain accepted and now select MANUAL. New commands use an optional request-ID envelope documented in the protocol guide.

Old app/new firmware: live sensor parsing and original VIB bytes continue working, but calibration must be performed through the upgraded app or a suitable SPP terminal. New app/old firmware: live signals parse, but legacy sessions/commands require explicit Settings legacy mode and remain unconfirmed. Lost ACKs never silently enable legacy mode.

SoftwareSerial is not full duplex. Firmware is cooperatively scheduled soft real-time; sensor transmission can be skipped for control traffic. Real timing, analog noise, supply behavior, motor temperatures, stack headroom and radio loss need assembled-glove measurements. AUTO haptics run locally; the manual lease detects app inactivity rather than the physical Bluetooth STATE pin. An ACK confirms firmware output state, not independently measured motor motion.

Release Android builds currently use debug signing. Configure a private keystore before public distribution. Never commit keys, local SDK paths, generated files, APKs or IDE state. No open-source license has been added; normal copyright restrictions apply.

# Smart Glove App Setup Guide

This guide covers Flutter setup, Android-device deployment, APK installation, Bluetooth pairing, and common Windows troubleshooting.

## 1. Install the development tools

Install:

1. Flutter stable SDK
2. Android Studio and Android SDK Platform Tools
3. Java 17
4. Git
5. Arduino IDE for glove firmware development

Add `flutter/bin` and the Android platform-tools directory to your `PATH`.

Verify the environment:

```bash
flutter doctor -v
```

Resolve Android toolchain errors before continuing. Accept Android licenses when requested:

```bash
flutter doctor --android-licenses
```

## 2. Prepare the project

```bash
git clone https://github.com/phanikumar122/Smart-Hand-Rehabilitation.git
cd Smart-Hand-Rehabilitation
flutter pub get
```

Run validation:

```bash
dart format --output=none --set-exit-if-changed lib test
dart analyze lib test
flutter test
```

## 3. Enable Android developer access

On the phone:

1. Open **Settings → About phone**.
2. Tap **Build number** seven times.
3. Open **Developer options**.
4. Enable **USB debugging**.
5. Connect the phone with a USB data cable.
6. Choose **File transfer** when Android asks for the USB mode.
7. Accept **Allow USB debugging?** and optionally select **Always allow from this computer**.

Check detection:

```bash
flutter devices
```

Expected output includes an Android entry similar to:

```text
Pixel 8 • ABC123 • android-arm64 • Android 15
```

## 4. Run during development

```bash
flutter run
```

If more than one target is available:

```bash
flutter run -d ABC123
```

Useful terminal commands while the app runs:

- `r` — hot reload
- `R` — hot restart
- `q` — stop

Bluetooth Classic must be tested on a physical Android device. Desktop and browser targets do not reproduce the HC-05/HC-06 serial workflow.

## 5. Build and install an APK

Create a debug APK:

```bash
flutter build apk --debug
```

The file is created at:

```text
build/app/outputs/flutter-apk/app-debug.apk
```

### Install with ADB

```bash
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

### Install manually

1. Copy `app-debug.apk` to the phone’s Downloads folder.
2. Open the file using Android Files.
3. If prompted, allow installation from that source.
4. Tap **Install**, then open **Smart Glove App**.

## 6. Upload the glove firmware

Firmware path:

```text
arduino/smart_glove/smart_glove.ino
```

Use Arduino AVR core **1.8.6**. EEPROM, SoftwareSerial and Wire are included in the core; external Adafruit display libraries are no longer needed. Open the sketch folder with its two supporting headers present.

Arduino IDE: choose **Arduino Nano**, **ATmega328P** (or **ATmega328P (Old Bootloader)** only for that variant), and the actual board COM port. Upload with the motor supply disabled for the first electrical check.

Arduino CLI, from the repository root:

```powershell
arduino-cli core update-index
arduino-cli core install arduino:avr@1.8.6
arduino-cli board list
arduino-cli compile --fqbn arduino:avr:nano:cpu=atmega328 --warnings all arduino/smart_glove
```

Upload example (replace COM5 with the port reported for your physical Nano):

```powershell
arduino-cli upload --fqbn arduino:avr:nano:cpu=atmega328 --port COM5 arduino/smart_glove
```

For a confirmed old-bootloader board, both commands use `--fqbn arduino:avr:nano:cpu=atmega328old`. Compilation cannot determine which bootloader is physically installed. No firmware upload has been performed as part of local software verification.

If native Windows execution is blocked or Arduino CLI is unavailable, Arduino IDE is an alternative. This upgrade was compiled using Arduino CLI in Ubuntu WSL. Host tests can be run in WSL from the project directory with `wsl -d Ubuntu -- python3 arduino/tests/run_tests.py` when Python and g++ are installed. USB upload from WSL requires the device to be attached to that environment; otherwise upload through Windows Arduino IDE/CLI. Do not assume a Windows COM name is a WSL serial device.

Firmware rates: USB debug 115200, Bluetooth 9600, sampling 50 Hz nominal, telemetry 10 Hz nominal, OLED snapshot 4 Hz nominal. Serial Monitor shows six-value sensor lines and occasional `DIAG,MISSED,...,OLED,...` diagnostics. Motors start off; valid EEPROM calibration loads automatically. There is no three-second startup capture. Perform open/bent/save in app Settings; see [Calibration Guide](CALIBRATION_GUIDE.md).

## 7. Pair and connect the glove

1. Power the glove.
2. In Android Bluetooth settings, pair the HC-05/HC-06.
3. Try PIN `1234` or `0000` if asked.
4. Open Smart Glove App.
5. Grant Nearby devices/Bluetooth permissions.
6. Tap **Scan** or refresh paired devices.
7. Tap **Connect** for the glove.
8. Confirm firmware status in Settings, complete open/bent/save calibration and wait for **Live signal** before recording.
9. Test AUTO and MANUAL mode on the bench before wearing the powered glove.

Use **Settings → Use legacy firmware** only for an older glove without this protocol. Missing ACKs on a 3.0 glove require link/firmware troubleshooting, not legacy fallback. Legacy mode is cleared on disconnect.

On Android 11 and earlier, Bluetooth discovery may also require Location permission and Location services.

## 8. Release preparation

The current Android configuration signs release builds with the debug key for local testing. Do not distribute that build publicly.

Before publishing:

1. Choose a permanent application ID.
2. Create a private release keystore.
3. Store signing credentials outside Git.
4. Configure release signing in Gradle.
5. Update the application version in `pubspec.yaml`.
6. Build an app bundle:

```bash
flutter build appbundle --release
```

Never commit `.jks`, `.keystore`, `key.properties`, API keys, or SDK paths.

## 9. Windows troubleshooting

### Android phone not detected

```bash
adb devices
flutter devices
```

If the device is `unauthorized`, unlock it and accept the debugging prompt. If it is absent:

- Replace charge-only cables.
- Try a different USB port.
- Restart ADB with `adb kill-server` followed by `adb start-server`.
- Install the phone manufacturer’s USB driver.

### Gradle or SDK path errors

`android/local.properties` is generated per machine and is intentionally ignored by Git. Running `flutter pub get` or a Flutter build normally creates it. If needed, regenerate the Android project metadata using your local Flutter installation rather than copying another developer’s paths.

### Installation blocked

- Remove an older app signed with a different key.
- Enable installation from the Files app when installing manually.
- Confirm the phone runs Android API 24 or newer.

### Bluetooth permission denied permanently

Open Android **Settings → Apps → Smart Glove App → Permissions** and enable Nearby devices, then reopen the app.
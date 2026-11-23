# NerveLink Setup Guide

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
4. Tap **Install**, then open **NerveLink Rehab**.

## 6. Upload the glove firmware

Firmware path:

```text
arduino/smart_glove/smart_glove.ino
```

Install these Arduino libraries:

- Adafruit GFX Library
- Adafruit SSD1306

Select the correct board and serial port, then upload. The firmware uses:

- USB debug serial: `115200`
- HC-05/HC-06 serial: `9600`
- Calibration delay: three seconds after power-on
- Sensor transmission: every 100 ms

Keep the hand flat until the OLED finishes showing `CALIBRATING...`.

## 7. Pair and connect the glove

1. Power the glove.
2. In Android Bluetooth settings, pair the HC-05/HC-06.
3. Try PIN `1234` or `0000` if asked.
4. Open NerveLink.
5. Grant Nearby devices/Bluetooth permissions.
6. Tap **Scan** or refresh paired devices.
7. Tap **Connect** for the glove.
8. Wait for **Live signal**.

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

Open Android **Settings → Apps → NerveLink Rehab → Permissions** and enable Nearby devices, then reopen the app.
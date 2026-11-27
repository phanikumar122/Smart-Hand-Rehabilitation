import 'package:material_ui/material_ui.dart';

import 'generated/app_localizations.dart';
import 'generated/app_localizations_en.dart';

final _english = AppLocalizationsEn();

extension AppStrings on BuildContext {
  AppLocalizations get strings => AppLocalizations.of(this) ?? _english;
  String message(Object value) => localizedMessage(strings, value);
}

extension FingerStrings on AppLocalizations {
  List<String> get fingerNames => [
    thumb,
    indexFinger,
    middleFinger,
    ringFinger,
    pinky,
  ];
  String fingerName(int finger) => fingerNames[finger];
}

/// Protocol and storage messages remain independent of the selected UI language.
/// Unknown platform diagnostics are shown as a translated recovery message.
String localizedMessage(AppLocalizations strings, Object value) {
  final raw = value.toString().replaceFirst(RegExp(r'^Bad state: '), '');
  final exact = switch (raw) {
    'Bluetooth permission is required to connect the glove.' =>
      strings.permissionRequired,
    'Bluetooth permission denied. Enable Nearby devices in app settings.' =>
      strings.permissionDenied,
    'Enable Bluetooth before scanning.' => strings.enableBeforeScan,
    'Enable system Location to scan on Android 11 or earlier.' =>
      strings.locationRequired,
    'Glove connection closed before it was ready.' =>
      strings.connectionNotReady,
    'Glove connection closed.' => strings.connectionClosed,
    'Glove is disconnected.' => strings.gloveDisconnected,
    'Connect the glove first.' => strings.connectFirst,
    'Could not save auto-reconnect setting.' => strings.autoReconnectSaveFailed,
    'Could not save the language setting.' => strings.languageSaveFailed,
    'Firmware status unavailable. Check the glove firmware and link. Enable legacy mode in Settings only for older firmware.' =>
      strings.firmwareUnavailable,
    'Glove disconnected before acknowledgement.' =>
      strings.disconnectedBeforeAck,
    'Session discarded: no sensor readings were recorded.' =>
      strings.sessionDiscarded,
    'Session stopped.' => strings.sessionStopped,
    'Stop the recording session before calibration.' =>
      strings.stopBeforeCalibration,
    'Upgrade glove firmware to use this feature.' => strings.upgradeRequired,
    'Sent; legacy firmware cannot confirm motor state.' =>
      strings.legacyCommandSent,
    'This glove supports the upgraded protocol. Legacy mode is for older firmware only.' =>
      strings.legacyNotNeeded,
    'Stop the session and wait for pending commands.' =>
      strings.waitAfterSession,
    'Legacy mode: no output confirmation or calibration. Firmware auto haptics may overwrite motor commands.' =>
      strings.legacyModeHint,
    'Reading firmware status' => strings.readingDeviceStatus,
    'Wait for the current command.' => strings.waitForCommand,
    'Sending' => strings.sending,
    'Confirmed' => strings.confirmed,
    'Glove connection changed during write.' => strings.connectionChanged,
    'Manual control expired; all motors stopped.' => strings.manualExpired,
    'Readings moved too much. Hold the hand still and retry.' =>
      strings.unstableReadings,
    'Open and bent readings are too close. Check sensor placement and retry the bent capture.' =>
      strings.invalidSpan,
    'Glove communication overflow. Output state is unknown; refresh status.' =>
      strings.communicationOverflow,
    'Cannot save a session without sensor readings.' =>
      strings.cannotSaveEmptySession,
    'Session storage failed.' => strings.storageFailed,
    _ => null,
  };
  if (exact != null) return exact;
  final saved = RegExp(r'^Session saved \((\d+) readings\)\.$').firstMatch(raw);
  if (saved != null) return strings.sessionSaved(int.parse(saved[1]!));
  final interrupted = RegExp(
    r'^Recording interrupted\. Saved (\d+) readings\.$',
  ).firstMatch(raw);
  if (interrupted != null) {
    return strings.sessionInterrupted(int.parse(interrupted[1]!));
  }
  final limit = RegExp(r'^Finger ([1-5]) stopped:').firstMatch(raw);
  if (limit != null) {
    return strings.fingerTimedOut(strings.fingerName(int.parse(limit[1]!) - 1));
  }
  if (raw.startsWith('Could not save session:')) {
    return strings.sessionSaveFailed;
  }
  if (raw.startsWith('Could not clear history:')) {
    return strings.historyClearFailed;
  }
  if (raw.startsWith('Glove status unavailable:')) {
    return strings.deviceStatusUnavailable;
  }
  if (raw.contains('TimeoutException')) return strings.commandTimedOut;
  if (raw.contains('UNSTABLE')) return strings.unstableReadings;
  if (raw.contains('INVALID_SPAN')) return strings.invalidSpan;
  if (raw.contains('OVERFLOW')) return strings.communicationOverflow;
  if (raw.contains('BUSY')) return strings.waitForCommand;
  if (RegExp(r'^(VIB|MODE|CAL|LINK|STATUS):').hasMatch(raw)) {
    return strings.commandRejected;
  }
  // English diagnostics retain their original detail for compatibility.
  return strings.localeName.startsWith('en') ? raw : strings.operationFailed;
}

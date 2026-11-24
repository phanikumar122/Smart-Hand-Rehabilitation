// ignore_for_file: deprecated_member_use

// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Smart Glove App';

  @override
  String get appSubtitle => 'SMART REHABILITATION';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get deviceLanguage => 'Device language';

  @override
  String get appearance => 'Appearance';

  @override
  String get systemTheme => 'System';

  @override
  String get lightTheme => 'Light';

  @override
  String get darkTheme => 'Dark';

  @override
  String get connection => 'Connection';

  @override
  String get autoReconnect => 'Auto Reconnect';

  @override
  String get autoReconnectHint => 'Reconnect after a dropped connection.';

  @override
  String get legacyFirmware => 'Use legacy firmware';

  @override
  String get legacyFirmwareHint =>
      'Older gloves only. Commands and calibration cannot be confirmed.';

  @override
  String get disconnectGlove => 'Disconnect Glove';

  @override
  String get connectedDevice => 'Connected device';

  @override
  String get dataPrivacy => 'Data & privacy';

  @override
  String get storedOnDevice => 'Stored on this device';

  @override
  String get clearSessionData => 'Clear All Session Data';

  @override
  String get clearSessionDataHint =>
      'Permanently delete saved rehabilitation history';

  @override
  String get clearData => 'Clear Data';

  @override
  String get cannotUndo => 'This action cannot be undone.';

  @override
  String get cancel => 'Cancel';

  @override
  String get clear => 'Clear';

  @override
  String get historyCleared => 'Session history cleared.';

  @override
  String get historyClearFailed => 'Could not clear history. Please try again.';

  @override
  String get today => 'Today';

  @override
  String get live => 'Live';

  @override
  String get noSignal => 'No signal';

  @override
  String get session => 'Session';

  @override
  String get progress => 'Progress';

  @override
  String get sessionInProgress => 'Session in progress';

  @override
  String get startASession => 'Start a session';

  @override
  String get startSession => 'Start Session';

  @override
  String get viewSession => 'View Session';

  @override
  String get stopSession => 'Stop Session';

  @override
  String get latestReadings => 'Latest readings';

  @override
  String get averageBend => 'Average bend';

  @override
  String get grip => 'Grip';

  @override
  String get liveGrip => 'Live grip';

  @override
  String get liveHand => 'Live hand';

  @override
  String get viewProgress => 'View progress';

  @override
  String get vibration => 'Vibration';

  @override
  String get movement => 'Movement';

  @override
  String get tapFinger => 'Tap a finger to inspect';

  @override
  String get all => 'All';

  @override
  String get thumb => 'Thumb';

  @override
  String get indexFinger => 'Index';

  @override
  String get middleFinger => 'Middle';

  @override
  String get ringFinger => 'Ring';

  @override
  String get pinky => 'Pinky';

  @override
  String fingerBend(String finger) {
    return '$finger bend';
  }

  @override
  String get gripHint => 'Grip sensor reading, 0–1023';

  @override
  String get handNoSignal => 'Hand diagram. No signal.';

  @override
  String get handLiveHint =>
      'Live finger movement. Use the finger buttons to inspect a reading.';

  @override
  String handInspected(String finger) {
    return '$finger selected for inspection. Live finger movement.';
  }

  @override
  String get recording => 'Recording';

  @override
  String get elapsedTime => 'Elapsed time';

  @override
  String get saving => 'Saving…';

  @override
  String get calibrateInSettings => 'Complete calibration in Settings.';

  @override
  String get connectToBegin => 'Connect your glove to begin.';

  @override
  String get openSettings => 'Open settings';

  @override
  String get sessionStopped => 'Session stopped.';

  @override
  String get liveTrends => 'Live trends';

  @override
  String get sessions => 'Sessions';

  @override
  String get connectForTrends => 'Connect your glove to see live trends.';

  @override
  String get oneMinute => '1 min';

  @override
  String get fiveMinutes => '5 min';

  @override
  String get sensorReading => 'Sensor reading';

  @override
  String get degrees => 'Degrees';

  @override
  String get clearHistory => 'Clear History';

  @override
  String get clearHistoryConfirm =>
      'Delete every saved rehabilitation session? This cannot be undone.';

  @override
  String get noSessions => 'No sessions saved yet.';

  @override
  String get completeSessionHint => 'Complete a session to save your progress.';

  @override
  String get sessionHistory => 'Session History';

  @override
  String completedSessions(int count) {
    return 'Completed sessions: $count';
  }

  @override
  String sessionDuration(int minutes, int seconds) {
    return '${minutes}m ${seconds}s';
  }

  @override
  String get maxGrip => 'Max grip';

  @override
  String get averageMovement => 'Avg movement';

  @override
  String get readings => 'Readings';

  @override
  String get connectGlove => 'Connect Glove';

  @override
  String get nearbyDevices => 'Nearby devices';

  @override
  String get scan => 'Scan';

  @override
  String get refreshDevices => 'Refresh paired devices';

  @override
  String get reconnecting => 'Reconnecting to glove…';

  @override
  String get noDevices => 'No devices found';

  @override
  String get pairGloveHint =>
      'Pair your glove in Bluetooth settings, then scan.';

  @override
  String get bluetoothEnabled => 'Bluetooth enabled';

  @override
  String get bluetoothDisabled => 'Bluetooth disabled';

  @override
  String get scanOrSelect => 'Scan or select a paired glove.';

  @override
  String get turnOnToConnect => 'Turn on to connect your glove.';

  @override
  String get enable => 'Enable';

  @override
  String get connect => 'Connect';

  @override
  String get gloveCalibration => 'Glove calibration';

  @override
  String get holdOpen =>
      'Hold your hand open without pressing the grip sensor.';

  @override
  String get holdBent => 'Hold a comfortable bend until capture finishes.';

  @override
  String get openCaptured =>
      'Open hand captured. Capture a comfortable bend next.';

  @override
  String get positionsCaptured => 'Both positions captured. Save to apply.';

  @override
  String get savingCalibration =>
      'Saving calibration. Keep the glove powered on.';

  @override
  String get captureFailed =>
      'Capture failed. Retry, or cancel to keep the previous calibration.';

  @override
  String get calibratedHint =>
      'Calibrated. To recalibrate, open your hand without pressing the grip sensor.';

  @override
  String get captureOpenHint =>
      'Open your hand without pressing the grip sensor, then capture.';

  @override
  String get calibrationNeedsUpgrade =>
      'Guided calibration requires updated firmware.';

  @override
  String get connectToCalibrate => 'Connect your glove to calibrate.';

  @override
  String firmwareStatus(String version, String status) {
    return 'Device version $version · $status';
  }

  @override
  String get calibrationSaved => 'Saved calibration';

  @override
  String get calibrationNotSaved => 'Calibration not saved';

  @override
  String get stopBeforeCalibration =>
      'Stop the recording session before calibrating.';

  @override
  String get captureOpen => 'Capture open hand';

  @override
  String get captureBent => 'Capture bent hand';

  @override
  String get saveCalibration => 'Save calibration';

  @override
  String get cancelCalibration => 'Cancel calibration';

  @override
  String get resetCalibration => 'Reset calibration';

  @override
  String get refreshStatus => 'Refresh status';

  @override
  String get vibrationControls => 'Vibration Controls';

  @override
  String get legacyUnconfirmed => 'Legacy mode: output state is unconfirmed.';

  @override
  String get motorManualHint =>
      'Motor controls switch the glove to Manual mode.';

  @override
  String modeLabel(String mode) {
    return 'Mode: $mode';
  }

  @override
  String get unknown => 'Unknown';

  @override
  String get manual => 'Manual';

  @override
  String get automatic => 'Automatic';

  @override
  String get allOn => 'All on';

  @override
  String get allOff => 'All off';

  @override
  String get unconfirmed => 'Unconfirmed';

  @override
  String get on => 'On';

  @override
  String get off => 'Off';

  @override
  String requestedState(String state) {
    return 'Requested: $state';
  }

  @override
  String get operationFailed =>
      'Could not complete the action. Please try again.';

  @override
  String get languageSaveFailed => 'Could not save the language setting.';

  @override
  String get permissionRequired =>
      'Bluetooth permission is required to connect the glove.';

  @override
  String get permissionDenied =>
      'Bluetooth permission denied. Enable Nearby devices in app settings.';

  @override
  String get enableBeforeScan => 'Enable Bluetooth before scanning.';

  @override
  String get locationRequired =>
      'Enable system Location to scan on Android 11 or earlier.';

  @override
  String get connectionNotReady =>
      'Glove connection closed before it was ready.';

  @override
  String get connectionClosed => 'Glove connection closed.';

  @override
  String get gloveDisconnected => 'Glove is disconnected.';

  @override
  String get connectFirst => 'Connect the glove first.';

  @override
  String get autoReconnectSaveFailed =>
      'Could not save auto-reconnect setting.';

  @override
  String get deviceStatusUnavailable =>
      'Glove status unavailable. Check the glove and connection.';

  @override
  String get firmwareUnavailable =>
      'Firmware status unavailable. Check the glove firmware and link. Enable legacy mode in Settings only for older firmware.';

  @override
  String get disconnectedBeforeAck =>
      'Glove disconnected before acknowledgement.';

  @override
  String get sessionDiscarded =>
      'Session discarded: no sensor readings were recorded.';

  @override
  String sessionSaved(int count) {
    return 'Session saved ($count readings).';
  }

  @override
  String get sessionSaveFailed => 'Could not save session. Please try again.';

  @override
  String get upgradeRequired => 'Upgrade glove firmware to use this feature.';

  @override
  String get legacyCommandSent =>
      'Sent; legacy firmware cannot confirm motor state.';

  @override
  String get legacyNotNeeded =>
      'This glove supports the upgraded protocol. Legacy mode is for older firmware only.';

  @override
  String get waitAfterSession =>
      'Stop the session and wait for pending commands.';

  @override
  String get legacyModeHint =>
      'Legacy mode: no output confirmation or calibration. Firmware auto haptics may overwrite motor commands.';

  @override
  String get readingDeviceStatus => 'Reading firmware status';

  @override
  String get waitForCommand => 'Wait for the current command.';

  @override
  String get sending => 'Sending';

  @override
  String get confirmed => 'Confirmed';

  @override
  String get commandTimedOut =>
      'The glove did not respond. Check the connection and try again.';

  @override
  String get connectionChanged => 'Glove connection changed during write.';

  @override
  String fingerTimedOut(String finger) {
    return '$finger stopped: vibration time limit reached. Turn it off and wait 2 seconds before rearming.';
  }

  @override
  String get manualExpired => 'Manual control expired; all motors stopped.';

  @override
  String get unstableReadings =>
      'Readings moved too much. Hold the hand still and retry.';

  @override
  String get invalidSpan =>
      'Open and bent readings are too close. Check sensor placement and retry the bent capture.';

  @override
  String get communicationOverflow =>
      'Glove communication overflow. Output state is unknown; refresh status.';

  @override
  String get cannotSaveEmptySession =>
      'Cannot save a session without sensor readings.';

  @override
  String get storageFailed => 'Session storage failed.';

  @override
  String get commandRejected =>
      'The glove could not complete the command. Check its status and try again.';
}

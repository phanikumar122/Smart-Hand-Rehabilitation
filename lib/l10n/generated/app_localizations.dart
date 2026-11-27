// ignore_for_file: deprecated_member_use
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_te.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('te'),
    Locale('hi'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Smart Glove App'**
  String get appTitle;

  /// No description provided for @appSubtitle.
  ///
  /// In en, this message translates to:
  /// **'SMART REHABILITATION'**
  String get appSubtitle;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @deviceLanguage.
  ///
  /// In en, this message translates to:
  /// **'Device language'**
  String get deviceLanguage;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @systemTheme.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemTheme;

  /// No description provided for @lightTheme.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lightTheme;

  /// No description provided for @darkTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get darkTheme;

  /// No description provided for @connection.
  ///
  /// In en, this message translates to:
  /// **'Connection'**
  String get connection;

  /// No description provided for @autoReconnect.
  ///
  /// In en, this message translates to:
  /// **'Auto Reconnect'**
  String get autoReconnect;

  /// No description provided for @autoReconnectHint.
  ///
  /// In en, this message translates to:
  /// **'Reconnect after a dropped connection.'**
  String get autoReconnectHint;

  /// No description provided for @legacyFirmware.
  ///
  /// In en, this message translates to:
  /// **'Use legacy firmware'**
  String get legacyFirmware;

  /// No description provided for @legacyFirmwareHint.
  ///
  /// In en, this message translates to:
  /// **'Older gloves only. Commands and calibration cannot be confirmed.'**
  String get legacyFirmwareHint;

  /// No description provided for @disconnectGlove.
  ///
  /// In en, this message translates to:
  /// **'Disconnect Glove'**
  String get disconnectGlove;

  /// No description provided for @connectedDevice.
  ///
  /// In en, this message translates to:
  /// **'Connected device'**
  String get connectedDevice;

  /// No description provided for @dataPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Data & privacy'**
  String get dataPrivacy;

  /// No description provided for @storedOnDevice.
  ///
  /// In en, this message translates to:
  /// **'Stored on this device'**
  String get storedOnDevice;

  /// No description provided for @clearSessionData.
  ///
  /// In en, this message translates to:
  /// **'Clear All Session Data'**
  String get clearSessionData;

  /// No description provided for @clearSessionDataHint.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete saved rehabilitation history'**
  String get clearSessionDataHint;

  /// No description provided for @clearData.
  ///
  /// In en, this message translates to:
  /// **'Clear Data'**
  String get clearData;

  /// No description provided for @cannotUndo.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get cannotUndo;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @historyCleared.
  ///
  /// In en, this message translates to:
  /// **'Session history cleared.'**
  String get historyCleared;

  /// No description provided for @historyClearFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not clear history. Please try again.'**
  String get historyClearFailed;

  /// No description provided for @historyLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load session history. Please try again.'**
  String get historyLoadFailed;

  /// No description provided for @retryHistory.
  ///
  /// In en, this message translates to:
  /// **'Reload history'**
  String get retryHistory;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @live.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get live;

  /// No description provided for @noSignal.
  ///
  /// In en, this message translates to:
  /// **'No signal'**
  String get noSignal;

  /// No description provided for @session.
  ///
  /// In en, this message translates to:
  /// **'Session'**
  String get session;

  /// No description provided for @progress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progress;

  /// No description provided for @sessionInProgress.
  ///
  /// In en, this message translates to:
  /// **'Session in progress'**
  String get sessionInProgress;

  /// No description provided for @startASession.
  ///
  /// In en, this message translates to:
  /// **'Start a session'**
  String get startASession;

  /// No description provided for @startSession.
  ///
  /// In en, this message translates to:
  /// **'Start Session'**
  String get startSession;

  /// No description provided for @viewSession.
  ///
  /// In en, this message translates to:
  /// **'View Session'**
  String get viewSession;

  /// No description provided for @stopSession.
  ///
  /// In en, this message translates to:
  /// **'Stop Session'**
  String get stopSession;

  /// No description provided for @latestReadings.
  ///
  /// In en, this message translates to:
  /// **'Latest readings'**
  String get latestReadings;

  /// No description provided for @averageBend.
  ///
  /// In en, this message translates to:
  /// **'Average bend'**
  String get averageBend;

  /// No description provided for @grip.
  ///
  /// In en, this message translates to:
  /// **'Grip'**
  String get grip;

  /// No description provided for @liveGrip.
  ///
  /// In en, this message translates to:
  /// **'Live grip'**
  String get liveGrip;

  /// No description provided for @liveHand.
  ///
  /// In en, this message translates to:
  /// **'Live hand'**
  String get liveHand;

  /// No description provided for @viewProgress.
  ///
  /// In en, this message translates to:
  /// **'View progress'**
  String get viewProgress;

  /// No description provided for @vibration.
  ///
  /// In en, this message translates to:
  /// **'Vibration'**
  String get vibration;

  /// No description provided for @movement.
  ///
  /// In en, this message translates to:
  /// **'Movement'**
  String get movement;

  /// No description provided for @tapFinger.
  ///
  /// In en, this message translates to:
  /// **'Tap a finger to inspect'**
  String get tapFinger;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @thumb.
  ///
  /// In en, this message translates to:
  /// **'Thumb'**
  String get thumb;

  /// No description provided for @indexFinger.
  ///
  /// In en, this message translates to:
  /// **'Index'**
  String get indexFinger;

  /// No description provided for @middleFinger.
  ///
  /// In en, this message translates to:
  /// **'Middle'**
  String get middleFinger;

  /// No description provided for @ringFinger.
  ///
  /// In en, this message translates to:
  /// **'Ring'**
  String get ringFinger;

  /// No description provided for @pinky.
  ///
  /// In en, this message translates to:
  /// **'Pinky'**
  String get pinky;

  /// {finger} bend
  ///
  /// In en, this message translates to:
  /// **'{finger} bend'**
  String fingerBend(String finger);

  /// No description provided for @gripHint.
  ///
  /// In en, this message translates to:
  /// **'Grip sensor reading, 0–1023'**
  String get gripHint;

  /// No description provided for @handNoSignal.
  ///
  /// In en, this message translates to:
  /// **'Hand diagram. No signal.'**
  String get handNoSignal;

  /// No description provided for @handLiveHint.
  ///
  /// In en, this message translates to:
  /// **'Live finger movement. Use the finger buttons to inspect a reading.'**
  String get handLiveHint;

  /// {finger} selected for inspection. Live finger movement.
  ///
  /// In en, this message translates to:
  /// **'{finger} selected for inspection. Live finger movement.'**
  String handInspected(String finger);

  /// No description provided for @recording.
  ///
  /// In en, this message translates to:
  /// **'Recording'**
  String get recording;

  /// No description provided for @elapsedTime.
  ///
  /// In en, this message translates to:
  /// **'Elapsed time'**
  String get elapsedTime;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get saving;

  /// No description provided for @calibrateInSettings.
  ///
  /// In en, this message translates to:
  /// **'Complete calibration in Settings.'**
  String get calibrateInSettings;

  /// No description provided for @connectToBegin.
  ///
  /// In en, this message translates to:
  /// **'Connect your glove to begin.'**
  String get connectToBegin;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get openSettings;

  /// No description provided for @sessionStopped.
  ///
  /// In en, this message translates to:
  /// **'Session stopped.'**
  String get sessionStopped;

  /// No description provided for @liveTrends.
  ///
  /// In en, this message translates to:
  /// **'Live trends'**
  String get liveTrends;

  /// No description provided for @sessions.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get sessions;

  /// No description provided for @connectForTrends.
  ///
  /// In en, this message translates to:
  /// **'Connect your glove to see live trends.'**
  String get connectForTrends;

  /// No description provided for @oneMinute.
  ///
  /// In en, this message translates to:
  /// **'1 min'**
  String get oneMinute;

  /// No description provided for @fiveMinutes.
  ///
  /// In en, this message translates to:
  /// **'5 min'**
  String get fiveMinutes;

  /// No description provided for @sensorReading.
  ///
  /// In en, this message translates to:
  /// **'Sensor reading'**
  String get sensorReading;

  /// No description provided for @movementScale.
  ///
  /// In en, this message translates to:
  /// **'Normalized movement (0–90), not joint angle'**
  String get movementScale;

  /// No description provided for @clearHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear History'**
  String get clearHistory;

  /// No description provided for @clearHistoryConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete every saved rehabilitation session? This cannot be undone.'**
  String get clearHistoryConfirm;

  /// No description provided for @noSessions.
  ///
  /// In en, this message translates to:
  /// **'No sessions saved yet.'**
  String get noSessions;

  /// No description provided for @completeSessionHint.
  ///
  /// In en, this message translates to:
  /// **'Complete a session to save your progress.'**
  String get completeSessionHint;

  /// No description provided for @sessionHistory.
  ///
  /// In en, this message translates to:
  /// **'Session History'**
  String get sessionHistory;

  /// Completed sessions: {count}
  ///
  /// In en, this message translates to:
  /// **'Completed sessions: {count}'**
  String completedSessions(int count);

  /// {minutes}m {seconds}s
  ///
  /// In en, this message translates to:
  /// **'{minutes}m {seconds}s'**
  String sessionDuration(int minutes, int seconds);

  /// No description provided for @maxGrip.
  ///
  /// In en, this message translates to:
  /// **'Max grip'**
  String get maxGrip;

  /// No description provided for @averageMovement.
  ///
  /// In en, this message translates to:
  /// **'Avg movement'**
  String get averageMovement;

  /// No description provided for @readings.
  ///
  /// In en, this message translates to:
  /// **'Readings'**
  String get readings;

  /// No description provided for @connectGlove.
  ///
  /// In en, this message translates to:
  /// **'Connect Glove'**
  String get connectGlove;

  /// No description provided for @nearbyDevices.
  ///
  /// In en, this message translates to:
  /// **'Nearby devices'**
  String get nearbyDevices;

  /// No description provided for @scan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get scan;

  /// No description provided for @refreshDevices.
  ///
  /// In en, this message translates to:
  /// **'Refresh paired devices'**
  String get refreshDevices;

  /// No description provided for @reconnecting.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting to glove…'**
  String get reconnecting;

  /// No description provided for @noDevices.
  ///
  /// In en, this message translates to:
  /// **'No devices found'**
  String get noDevices;

  /// No description provided for @pairGloveHint.
  ///
  /// In en, this message translates to:
  /// **'Pair your glove in Bluetooth settings, then scan.'**
  String get pairGloveHint;

  /// No description provided for @bluetoothEnabled.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth enabled'**
  String get bluetoothEnabled;

  /// No description provided for @bluetoothDisabled.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth disabled'**
  String get bluetoothDisabled;

  /// No description provided for @scanOrSelect.
  ///
  /// In en, this message translates to:
  /// **'Scan or select a paired glove.'**
  String get scanOrSelect;

  /// No description provided for @turnOnToConnect.
  ///
  /// In en, this message translates to:
  /// **'Turn on to connect your glove.'**
  String get turnOnToConnect;

  /// No description provided for @enable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get enable;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @gloveCalibration.
  ///
  /// In en, this message translates to:
  /// **'Glove calibration'**
  String get gloveCalibration;

  /// No description provided for @holdOpen.
  ///
  /// In en, this message translates to:
  /// **'Hold your hand open without pressing the grip sensor.'**
  String get holdOpen;

  /// No description provided for @holdBent.
  ///
  /// In en, this message translates to:
  /// **'Hold a comfortable bend until capture finishes.'**
  String get holdBent;

  /// No description provided for @openCaptured.
  ///
  /// In en, this message translates to:
  /// **'Open hand captured. Capture a comfortable bend next.'**
  String get openCaptured;

  /// No description provided for @positionsCaptured.
  ///
  /// In en, this message translates to:
  /// **'Both positions captured. Save to apply.'**
  String get positionsCaptured;

  /// No description provided for @savingCalibration.
  ///
  /// In en, this message translates to:
  /// **'Saving calibration. Keep the glove powered on.'**
  String get savingCalibration;

  /// No description provided for @captureFailed.
  ///
  /// In en, this message translates to:
  /// **'Capture failed. Retry, or cancel to keep the previous calibration.'**
  String get captureFailed;

  /// No description provided for @calibratedHint.
  ///
  /// In en, this message translates to:
  /// **'Calibrated. To recalibrate, open your hand without pressing the grip sensor.'**
  String get calibratedHint;

  /// No description provided for @captureOpenHint.
  ///
  /// In en, this message translates to:
  /// **'Open your hand without pressing the grip sensor, then capture.'**
  String get captureOpenHint;

  /// No description provided for @calibrationNeedsUpgrade.
  ///
  /// In en, this message translates to:
  /// **'Guided calibration requires updated firmware.'**
  String get calibrationNeedsUpgrade;

  /// No description provided for @connectToCalibrate.
  ///
  /// In en, this message translates to:
  /// **'Connect your glove to calibrate.'**
  String get connectToCalibrate;

  /// Device version {version} · {status}
  ///
  /// In en, this message translates to:
  /// **'Device version {version} · {status}'**
  String firmwareStatus(String version, String status);

  /// No description provided for @calibrationSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved calibration'**
  String get calibrationSaved;

  /// No description provided for @calibrationNotSaved.
  ///
  /// In en, this message translates to:
  /// **'Calibration not saved'**
  String get calibrationNotSaved;

  /// No description provided for @stopBeforeCalibration.
  ///
  /// In en, this message translates to:
  /// **'Stop the recording session before calibrating.'**
  String get stopBeforeCalibration;

  /// No description provided for @captureOpen.
  ///
  /// In en, this message translates to:
  /// **'Capture open hand'**
  String get captureOpen;

  /// No description provided for @captureBent.
  ///
  /// In en, this message translates to:
  /// **'Capture bent hand'**
  String get captureBent;

  /// No description provided for @saveCalibration.
  ///
  /// In en, this message translates to:
  /// **'Save calibration'**
  String get saveCalibration;

  /// No description provided for @cancelCalibration.
  ///
  /// In en, this message translates to:
  /// **'Cancel calibration'**
  String get cancelCalibration;

  /// No description provided for @resetCalibration.
  ///
  /// In en, this message translates to:
  /// **'Reset calibration'**
  String get resetCalibration;

  /// No description provided for @refreshStatus.
  ///
  /// In en, this message translates to:
  /// **'Refresh status'**
  String get refreshStatus;

  /// No description provided for @vibrationControls.
  ///
  /// In en, this message translates to:
  /// **'Vibration Controls'**
  String get vibrationControls;

  /// No description provided for @legacyUnconfirmed.
  ///
  /// In en, this message translates to:
  /// **'Legacy mode: output state is unconfirmed.'**
  String get legacyUnconfirmed;

  /// No description provided for @motorManualHint.
  ///
  /// In en, this message translates to:
  /// **'Motor controls switch the glove to Manual mode.'**
  String get motorManualHint;

  /// Mode: {mode}
  ///
  /// In en, this message translates to:
  /// **'Mode: {mode}'**
  String modeLabel(String mode);

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @manual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get manual;

  /// No description provided for @automatic.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get automatic;

  /// No description provided for @allOn.
  ///
  /// In en, this message translates to:
  /// **'All on'**
  String get allOn;

  /// No description provided for @allOff.
  ///
  /// In en, this message translates to:
  /// **'All off'**
  String get allOff;

  /// No description provided for @releaseMotor.
  ///
  /// In en, this message translates to:
  /// **'Send OFF to {finger}'**
  String releaseMotor(String finger);

  /// No description provided for @unconfirmed.
  ///
  /// In en, this message translates to:
  /// **'Unconfirmed'**
  String get unconfirmed;

  /// No description provided for @on.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get on;

  /// No description provided for @off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get off;

  /// Requested: {state}
  ///
  /// In en, this message translates to:
  /// **'Requested: {state}'**
  String requestedState(String state);

  /// No description provided for @operationFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not complete the action. Please try again.'**
  String get operationFailed;

  /// No description provided for @languageSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the language setting.'**
  String get languageSaveFailed;

  /// No description provided for @permissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth permission is required to connect the glove.'**
  String get permissionRequired;

  /// No description provided for @permissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth permission denied. Enable Nearby devices in app settings.'**
  String get permissionDenied;

  /// No description provided for @enableBeforeScan.
  ///
  /// In en, this message translates to:
  /// **'Enable Bluetooth before scanning.'**
  String get enableBeforeScan;

  /// No description provided for @locationRequired.
  ///
  /// In en, this message translates to:
  /// **'Enable system Location to scan on Android 11 or earlier.'**
  String get locationRequired;

  /// No description provided for @connectionNotReady.
  ///
  /// In en, this message translates to:
  /// **'Glove connection closed before it was ready.'**
  String get connectionNotReady;

  /// No description provided for @connectionClosed.
  ///
  /// In en, this message translates to:
  /// **'Glove connection closed.'**
  String get connectionClosed;

  /// No description provided for @gloveDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Glove is disconnected.'**
  String get gloveDisconnected;

  /// No description provided for @connectFirst.
  ///
  /// In en, this message translates to:
  /// **'Connect the glove first.'**
  String get connectFirst;

  /// No description provided for @autoReconnectSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save auto-reconnect setting.'**
  String get autoReconnectSaveFailed;

  /// No description provided for @deviceStatusUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Glove status unavailable. Check the glove and connection.'**
  String get deviceStatusUnavailable;

  /// No description provided for @firmwareUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Firmware status unavailable. Check the glove firmware and link. Enable legacy mode in Settings only for older firmware.'**
  String get firmwareUnavailable;

  /// No description provided for @disconnectedBeforeAck.
  ///
  /// In en, this message translates to:
  /// **'Glove disconnected before acknowledgement.'**
  String get disconnectedBeforeAck;

  /// No description provided for @sessionDiscarded.
  ///
  /// In en, this message translates to:
  /// **'Session discarded: no sensor readings were recorded.'**
  String get sessionDiscarded;

  /// No description provided for @sessionInterrupted.
  ///
  /// In en, this message translates to:
  /// **'Recording interrupted. Saved {count} readings.'**
  String sessionInterrupted(int count);

  /// Session saved ({count} readings).
  ///
  /// In en, this message translates to:
  /// **'Session saved ({count} readings).'**
  String sessionSaved(int count);

  /// No description provided for @sessionSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save session. Please try again.'**
  String get sessionSaveFailed;

  /// No description provided for @upgradeRequired.
  ///
  /// In en, this message translates to:
  /// **'Upgrade glove firmware to use this feature.'**
  String get upgradeRequired;

  /// No description provided for @legacyCommandSent.
  ///
  /// In en, this message translates to:
  /// **'Sent; legacy firmware cannot confirm motor state.'**
  String get legacyCommandSent;

  /// No description provided for @legacyNotNeeded.
  ///
  /// In en, this message translates to:
  /// **'This glove supports the upgraded protocol. Legacy mode is for older firmware only.'**
  String get legacyNotNeeded;

  /// No description provided for @waitAfterSession.
  ///
  /// In en, this message translates to:
  /// **'Stop the session and wait for pending commands.'**
  String get waitAfterSession;

  /// No description provided for @legacyModeHint.
  ///
  /// In en, this message translates to:
  /// **'Legacy mode: no output confirmation or calibration. Firmware auto haptics may overwrite motor commands.'**
  String get legacyModeHint;

  /// No description provided for @readingDeviceStatus.
  ///
  /// In en, this message translates to:
  /// **'Reading firmware status'**
  String get readingDeviceStatus;

  /// No description provided for @waitForCommand.
  ///
  /// In en, this message translates to:
  /// **'Wait for the current command.'**
  String get waitForCommand;

  /// No description provided for @sending.
  ///
  /// In en, this message translates to:
  /// **'Sending'**
  String get sending;

  /// No description provided for @confirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get confirmed;

  /// No description provided for @commandTimedOut.
  ///
  /// In en, this message translates to:
  /// **'The glove did not respond. Check the connection and try again.'**
  String get commandTimedOut;

  /// No description provided for @connectionChanged.
  ///
  /// In en, this message translates to:
  /// **'Glove connection changed during write.'**
  String get connectionChanged;

  /// {finger} stopped: vibration time limit reached. Turn it off and wait 2 seconds before rearming.
  ///
  /// In en, this message translates to:
  /// **'{finger} stopped: vibration time limit reached. Turn it off and wait 2 seconds before rearming.'**
  String fingerTimedOut(String finger);

  /// No description provided for @manualExpired.
  ///
  /// In en, this message translates to:
  /// **'Manual control expired; all motors stopped.'**
  String get manualExpired;

  /// No description provided for @unstableReadings.
  ///
  /// In en, this message translates to:
  /// **'Readings moved too much. Hold the hand still and retry.'**
  String get unstableReadings;

  /// No description provided for @invalidSpan.
  ///
  /// In en, this message translates to:
  /// **'Open and bent readings are too close. Check sensor placement and retry the bent capture.'**
  String get invalidSpan;

  /// No description provided for @communicationOverflow.
  ///
  /// In en, this message translates to:
  /// **'Glove communication overflow. Output state is unknown; refresh status.'**
  String get communicationOverflow;

  /// No description provided for @cannotSaveEmptySession.
  ///
  /// In en, this message translates to:
  /// **'Cannot save a session without sensor readings.'**
  String get cannotSaveEmptySession;

  /// No description provided for @storageFailed.
  ///
  /// In en, this message translates to:
  /// **'Session storage failed.'**
  String get storageFailed;

  /// No description provided for @commandRejected.
  ///
  /// In en, this message translates to:
  /// **'The glove could not complete the command. Check its status and try again.'**
  String get commandRejected;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi', 'te'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'te':
      return AppLocalizationsTe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

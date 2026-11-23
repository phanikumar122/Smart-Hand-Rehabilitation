import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_classic_bluetooth/flutter_classic_bluetooth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/sensor_data.dart';
import '../models/rehab_session.dart';
import '../models/firmware_status.dart';
import '../services/glove_connection.dart';
import '../services/storage_service.dart';

class GloveDataProvider extends ChangeNotifier {
  GloveDataProvider({this.connector = connectGlove, DateTime Function()? now})
    : _now = now ?? DateTime.now {
    settingsReady = _loadSettings();
  }
  final GloveConnector connector;
  final DateTime Function() _now;
  final StorageService _storageService = StorageService();
  late final Future<void> settingsReady;
  GloveConnection? _connection;
  StreamSubscription<Uint8List>? _inputSubscription;
  StreamSubscription<BtcConnectionState>? _stateSubscription;
  Timer? _watchdog, _sessionTimer, _reconnectTimer;
  bool _disposed = false, _isConnecting = false, _reconnecting = false;
  int _generation = 0, _reconnectAttempts = 0;
  BtcDevice? _connectedDevice;
  SensorData? _currentData;
  DateTime? _lastPacket;
  final List<SensorData> _history = [];
  final List<int> _buffer = [];
  bool _discardFrame = false, _autoReconnect = false;
  String? _connectionError, _sessionMessage;
  bool _isSessionActive = false, _isSavingSession = false;
  DateTime? _sessionStartTime;
  Duration _sessionElapsed = Duration.zero;
  int? _sessionMaxGrip;
  int _movementTotal = 0, _sessionReadingCount = 0;
  FirmwareStatus? _firmware;
  CalibrationPhase _calibrationPhase = CalibrationPhase.idle;
  HapticMode? _hapticMode;
  int? _confirmedMotorMask;
  int _requestedMotorMask = 0, _nextCommandId = 1;
  bool _legacyFirmware = false;
  bool _supportsProtocol = false;
  _PendingCommand? _pending;
  Completer<void>? _sensorWindow;
  Timer? _statusTimer;
  CommandState _commandState = CommandState.idle;
  String? _commandMessage, _calibrationError, _safetyMessage;

  FirmwareStatus? get firmware => _firmware;
  CalibrationPhase get calibrationPhase => _calibrationPhase;
  HapticMode? get hapticMode => _hapticMode;
  bool get legacyFirmware => _legacyFirmware;
  bool get supportsProtocol => _supportsProtocol;
  bool get commandPending => _pending != null;
  CommandState get commandState => _commandState;
  String? get commandMessage => _commandMessage;
  String? get calibrationError => _calibrationError;
  String? get safetyMessage => _safetyMessage;
  int? get confirmedMotorMask => _confirmedMotorMask;
  int get requestedMotorMask => _requestedMotorMask;
  bool get calibrationValid => _firmware?.valid ?? false;
  bool get calibrationActive => [
    CalibrationPhase.open,
    CalibrationPhase.closed,
    CalibrationPhase.saving,
  ].contains(_calibrationPhase);

  bool get isConnected => _connection != null;
  bool get isConnecting => _isConnecting;
  bool get autoReconnect => _autoReconnect;
  bool get isReconnecting => _reconnecting || _reconnectTimer != null;
  String? get connectionError => _connectionError;
  String? get sessionMessage => _sessionMessage;
  BtcDevice? get connectedDevice => _connectedDevice;
  SensorData? get currentData => hasLiveData ? _currentData : null;
  List<SensorData> get history => UnmodifiableListView(_history);
  bool get isSessionActive => _isSessionActive;
  bool get isSavingSession => _isSavingSession;
  DateTime? get sessionStartTime => _sessionStartTime;
  Duration get sessionElapsed => _sessionElapsed;
  int get sessionReadingCount => _sessionReadingCount;
  bool get hasLiveData =>
      isConnected &&
      _currentData != null &&
      _lastPacket != null &&
      _now().difference(_lastPacket!) < const Duration(milliseconds: 1500);
  bool get canStartSession =>
      hasLiveData &&
      !_isSessionActive &&
      !_isSavingSession &&
      !(_pending?.payload.startsWith('CAL:') ?? false) &&
      (_legacyFirmware ||
          (calibrationValid && _calibrationPhase == CalibrationPhase.idle));
  String get status => _isConnecting
      ? 'Connecting'
      : hasLiveData
      ? 'Live signal'
      : 'No signal';
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (_disposed) return;
    _autoReconnect = prefs.getBool('auto_reconnect') ?? false;
    _notify();
  }

  Future<void> setAutoReconnect(bool enabled) async {
    await settingsReady;
    if (_disposed) return;
    _autoReconnect = enabled;
    if (!enabled) {
      _reconnectTimer?.cancel();
      _reconnectTimer = null;
      if (_reconnecting) {
        _generation++;
        _isConnecting = false;
        _reconnecting = false;
      }
    }
    _notify();
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setBool('auto_reconnect', enabled)) {
      throw StateError('Could not save auto-reconnect setting.');
    }
  }

  Future<bool> connectToDevice(BtcDevice device) async {
    await settingsReady;
    if (_disposed || _isConnecting || isConnected) return false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectAttempts = 0;
    return _connect(device);
  }

  Future<bool> _connect(BtcDevice device) async {
    final generation = ++_generation;
    _isConnecting = true;
    _connectionError = null;
    _notify();
    try {
      final connection = await connector(device);
      if (_disposed || generation != _generation) {
        await connection.close();
        return false;
      }
      _connection = connection;
      _connectedDevice = device;
      _reconnectAttempts = 0;
      _buffer.clear();
      _discardFrame = false;
      _inputSubscription = connection.input.listen(
        _onDataReceived,
        onDone: () => _linkLost(device),
        onError: (Object error) => _linkLost(device, error),
        cancelOnError: true,
      );
      _stateSubscription = connection.states.listen((state) {
        if (state == BtcConnectionState.disconnected) _linkLost(device);
      }, onError: (Object error) => _linkLost(device, error));
      _watchdog = Timer.periodic(const Duration(milliseconds: 500), (_) {
        if (!hasLiveData) _currentData = null;
        _pruneHistory();
        _notify();
      });
      // A transport write is never treated as a firmware acknowledgement.
      try {
        await _sendPayload('STATUS', quiet: true);
      } catch (_) {
        if (generation != _generation || _disposed) return false;
        _legacyFirmware = false;
        _commandMessage = 'Firmware status unavailable. Check the glove firmware and link. Enable legacy mode in Settings only for older firmware.';
      }
      if (generation != _generation || _disposed) return false;
      _statusTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_pending == null && !_legacyFirmware && isConnected) {
          unawaited(
            _sendPayload('STATUS', quiet: true).catchError((Object error) {
              _confirmedMotorMask = null;
              _firmware = null;
              _hapticMode = null;
              _safetyMessage = 'Glove status unavailable: $error';
              _notify();
            }),
          );
        }
      });
      return true;
    } catch (error) {
      if (generation == _generation && !_disposed) {
        _connectionError = error.toString();
      }
      return false;
    } finally {
      if (generation == _generation && !_disposed) {
        _isConnecting = false;
        _notify();
      }
    }
  }

  void _linkLost(BtcDevice device, [Object? error]) {
    if (_disposed || !isConnected) return;
    _connectionError = error?.toString() ?? 'Glove connection closed.';
    final cleanup = disconnect(manual: false);
    final generation = _generation;
    unawaited(
      cleanup.then((_) {
        if (!_disposed && _autoReconnect && generation == _generation) {
          _scheduleReconnect(device);
        }
      }),
    );
  }

  void _scheduleReconnect(BtcDevice device) {
    if (_disposed ||
        !_autoReconnect ||
        isConnected ||
        _isConnecting ||
        _reconnectAttempts >= 3) {
      return;
    }
    final generation = _generation;
    _reconnectTimer = Timer(const Duration(seconds: 2), () async {
      _reconnectTimer = null;
      if (_disposed || !_autoReconnect || generation != _generation) return;
      _reconnectAttempts++;
      _reconnecting = true;
      final connected = await _connect(device);
      _reconnecting = false;
      if (!connected &&
          !_disposed &&
          _autoReconnect &&
          generation + 1 == _generation) {
        _scheduleReconnect(device);
      }
      _notify();
    });
    _notify();
  }

  Future<void> disconnect({bool manual = true}) async {
    _generation++;
    _statusTimer?.cancel();
    _statusTimer = null;
    _failPending(StateError('Glove disconnected before acknowledgement.'));
    _sensorWindow?.complete();
    _sensorWindow = null;
    _firmware = null;
    _hapticMode = null;
    _confirmedMotorMask = null;
    _requestedMotorMask = 0;
    _legacyFirmware = false;
    _supportsProtocol = false;
    _calibrationPhase = CalibrationPhase.idle;
    _calibrationError = null;
    _safetyMessage = null;
    _watchdog?.cancel();
    _watchdog = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnecting = false;
    _isConnecting = false;
    final connection = _connection;
    final input = _inputSubscription;
    final states = _stateSubscription;
    _connection = null;
    _inputSubscription = null;
    _stateSubscription = null;
    _connectedDevice = null;
    _currentData = null;
    _lastPacket = null;
    _history.clear();
    _buffer.clear();
    _discardFrame = false;
    if (manual) _connectionError = null;
    final sessionEnd = _isSessionActive ? stopSession() : Future.value(false);
    _sessionTimer?.cancel();
    _sessionTimer = null;
    _notify();
    await input?.cancel();
    await states?.cancel();
    try {
      await connection?.close();
    } catch (error) {
      _connectionError = error.toString();
    }
    await sessionEnd;
    _notify();
  }

  void _onDataReceived(Uint8List bytes) {
    if (!isConnected || _disposed) return;
    for (final byte in bytes) {
      if (byte == 10) {
        if (!_discardFrame && _buffer.isNotEmpty) {
          _processLine(String.fromCharCodes(_buffer));
        }
        _buffer.clear();
        _discardFrame = false;
      } else if (!_discardFrame) {
        if (byte > 127 ||
            (byte < 32 && byte != 13 && byte != 9) ||
            _buffer.length >= 2048) {
          _buffer.clear();
          _discardFrame = true;
        } else {
          _buffer.add(byte);
        }
      }
    }
  }

  void _processLine(String line) {
    if (line.startsWith('ACK,') ||
        line.startsWith('ERR,') ||
        line.startsWith('EVT,')) {
      _processResponse(line.trim());
      return;
    }
    final data = SensorData.fromCsv(line, timestamp: _now());
    if (data == null) return;
    _lastPacket = data.timestamp;
    _sensorWindow?.complete();
    _sensorWindow = null;
    _currentData = data;
    _history.add(data);
    _pruneHistory();
    if (_isSessionActive) {
      _sessionMaxGrip = _sessionMaxGrip == null || data.grip > _sessionMaxGrip!
          ? data.grip
          : _sessionMaxGrip;
      _movementTotal +=
          data.thumb + data.index + data.middle + data.ring + data.pinky;
      _sessionReadingCount++;
    }
    _notify();
  }

  void _pruneHistory() {
    final cutoff = _now().subtract(const Duration(minutes: 5));
    _history.removeWhere((data) => data.timestamp.isBefore(cutoff));
    if (_history.length > 3000) _history.removeRange(0, _history.length - 3000);
  }

  bool startSession() {
    if (!canStartSession) return false;
    _isSessionActive = true;
    _sessionStartTime = _now();
    _sessionElapsed = Duration.zero;
    _sessionReadingCount = 0;
    _movementTotal = 0;
    _sessionMaxGrip = null;
    _sessionMessage = null;
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _sessionElapsed = _now().difference(_sessionStartTime!);
      _notify();
    });
    _notify();
    return true;
  }

  Future<bool> stopSession() async {
    if (!_isSessionActive || _sessionStartTime == null) return false;
    _isSessionActive = false;
    _sessionTimer?.cancel();
    _sessionTimer = null;
    _sessionElapsed = _now().difference(_sessionStartTime!);
    if (_sessionReadingCount == 0) {
      _sessionMessage = 'Session discarded: no sensor readings were recorded.';
      _notify();
      return false;
    }
    final session = RehabSession(
      id: _now().microsecondsSinceEpoch.toString(),
      startTime: _sessionStartTime!,
      duration: _sessionElapsed,
      maxGrip: _sessionMaxGrip!,
      averageMovement: _movementTotal ~/ (_sessionReadingCount * 5),
      readingCount: _sessionReadingCount,
    );
    _isSavingSession = true;
    _notify();
    try {
      await _storageService.saveSession(session);
      _sessionMessage = 'Session saved (${session.readingCount} readings).';
      return true;
    } catch (error) {
      _sessionMessage = 'Could not save session: $error';
      return false;
    } finally {
      _isSavingSession = false;
      _notify();
    }
  }

  Future<void> sendCommand(String command) async {
    if (!RegExp(
      r'^<(VIB:(ALL|[1-5]),[01]|MODE:(AUTO|MANUAL)|CAL:(OPEN|CLOSED|SAVE|RESET|STATUS|CANCEL)|STATUS)>$',
    ).hasMatch(command)) {
      throw ArgumentError.value(command, 'command', 'Invalid glove command');
    }
    final payload = command.substring(1, command.length - 1);
    if (payload.startsWith('CAL:') && _isSessionActive) {
      throw StateError('Stop the recording session before calibration.');
    }
    if (_legacyFirmware) {
      if (!payload.startsWith('VIB:')) {
        throw StateError('Upgrade glove firmware to use this feature.');
      }
      final connection = _connection;
      if (connection == null) throw StateError('Glove is disconnected.');
      await _writeCommand(connection, command);
      final fields = payload.substring(4).split(',');
      final mask = fields[0] == 'ALL' ? 31 : 1 << (int.parse(fields[0]) - 1);
      _requestedMotorMask = fields[1] == '1'
          ? _requestedMotorMask | mask
          : _requestedMotorMask & ~mask;
      _commandState = CommandState.sentUnconfirmed;
      _commandMessage = 'Sent; legacy firmware cannot confirm motor state.';
      _notify();
      return;
    }
    await _sendPayload(payload);
  }

  Future<void> setHapticMode(HapticMode mode) =>
      sendCommand('<MODE:${mode == HapticMode.manual ? 'MANUAL' : 'AUTO'}>');
  Future<void> calibrateOpen() => sendCommand('<CAL:OPEN>');
  Future<void> calibrateClosed() => sendCommand('<CAL:CLOSED>');
  Future<void> saveCalibration() => sendCommand('<CAL:SAVE>');
  Future<void> resetCalibration() => sendCommand('<CAL:RESET>');
  Future<void> cancelCalibration() => sendCommand('<CAL:CANCEL>');
  Future<void> refreshFirmwareStatus() => sendCommand('<STATUS>');

  Future<void> setLegacyFirmwareMode(bool enabled) async {
    if (!isConnected) throw StateError('Connect the glove first.');
    if (enabled && _supportsProtocol) {
      throw StateError(
        'This glove supports the upgraded protocol. Legacy mode is for older firmware only.',
      );
    }
    if (_pending != null || _isSessionActive) {
      throw StateError('Stop the session and wait for pending commands.');
    }
    _legacyFirmware = enabled;
    _firmware = null;
    _confirmedMotorMask = null;
    _hapticMode = null;
    _calibrationPhase = CalibrationPhase.idle;
    _commandMessage = enabled
        ? 'Legacy mode: commands and calibration are unconfirmed. Automatic haptics may overwrite motor commands.'
        : 'Reading firmware status';
    _notify();
    if (!enabled) await _sendPayload('STATUS', quiet: true);
  }

  Future<void> _sendPayload(String payload, {bool quiet = false}) {
    if (!isConnected || _disposed) {
      return Future.error(StateError('Glove is disconnected.'));
    }
    if (_pending != null) {
      return Future.error(StateError('Wait for the current command.'));
    }
    final id = _nextCommandId;
    _nextCommandId = id == 65535 ? 1 : id + 1;
    final pending = _PendingCommand(id, payload, quiet, _generation);
    _pending = pending;
    if (!quiet) {
      _commandState = CommandState.sending;
      _commandMessage = 'Sending';
      if (payload.startsWith('CAL:')) _calibrationError = null;
      if (payload.startsWith('MODE:')) _requestedMotorMask = 0;
      if (payload.startsWith('VIB:')) {
        final fields = payload.substring(4).split(',');
        final mask = fields[0] == 'ALL' ? 31 : 1 << (int.parse(fields[0]) - 1);
        _requestedMotorMask = fields[1] == '1'
            ? _requestedMotorMask | mask
            : _requestedMotorMask & ~mask;
      }
      _notify();
    }
    unawaited(_writePending(pending));
    return pending.completer.future;
  }

  Future<void> _writePending(_PendingCommand pending) async {
    try {
      // Prefer the receive window immediately following a complete sensor line.
      // Retries drift relative to the 100 ms telemetry period to avoid phase lock.
      if (pending.attempts > 0) {
        await Future<void>.delayed(
          Duration(milliseconds: 25 + pending.attempts * 13),
        );
      }
      if (_lastPacket != null &&
          _now().difference(_lastPacket!) > const Duration(milliseconds: 30)) {
        final window = Completer<void>();
        _sensorWindow = window;
        final fallback = Timer(const Duration(milliseconds: 130), () {
          if (_sensorWindow == window) {
            _sensorWindow = null;
            window.complete();
          }
        });
        await window.future;
        fallback.cancel();
      }
      if (_pending != pending || pending.generation != _generation) return;
      final connection = _connection;
      if (connection == null) throw StateError('Glove is disconnected.');
      pending.attempts++;
      await _writeCommand(connection, '<Q:${pending.id}:${pending.payload}>');
      if (_pending != pending) return;
      pending.timer = Timer(const Duration(milliseconds: 850), () {
        if (_pending != pending) return;
        if (pending.attempts < 3) {
          unawaited(_writePending(pending));
        } else {
          _confirmedMotorMask = null;
          _failPending(
            TimeoutException('Glove did not acknowledge ${pending.payload}.'),
          );
        }
      });
    } catch (error) {
      if (_pending == pending) {
        _confirmedMotorMask = null;
        _failPending(error);
      }
    }
  }

  Future<void> _writeCommand(GloveConnection connection, String command) async {
    try {
      await (() async {
        await connection.write(Uint8List.fromList(ascii.encode(command)));
        if (!identical(connection, _connection)) {
          throw StateError('Glove connection changed during write.');
        }
        await connection.flush();
      })().timeout(const Duration(seconds: 1));
    } on TimeoutException catch (error) {
      // Future.timeout does not cancel native queued writes. Quarantine the link.
      if (identical(connection, _connection)) {
        _confirmedMotorMask = null;
        _failPending(error);
        final device = _connectedDevice;
        if (device != null) _linkLost(device, error);
      }
      rethrow;
    }
  }

  void _failPending(Object error) {
    final pending = _pending;
    if (pending == null) return;
    _pending = null;
    pending.timer?.cancel();
    if (!pending.quiet) {
      _commandState = CommandState.failed;
      _commandMessage = error.toString();
      if (pending.payload.startsWith('CAL:')) {
        _calibrationError = error.toString();
        _firmware = null;
      }
    }
    pending.completer.completeError(error);
    _notify();
  }

  void _processResponse(String line) {
    final fields = line.split(',');
    if (fields.first == 'EVT') {
      if (fields.length == 5 &&
          fields[1] == 'VIB' &&
          fields[3] == 'TIMEOUT' &&
          RegExp(r'^[1-5]$').hasMatch(fields[2])) {
        final mask = _parseMask(fields[4]);
        if (mask == null) return;
        _confirmedMotorMask = mask;
        _safetyMessage =
            'Finger ${fields[2]} stopped: vibration time limit reached. Turn it off and wait 2 seconds before rearming.';
      } else if (fields.length == 4 &&
          fields[1] == 'LINK' &&
          fields[2] == 'LEASE_EXPIRED' &&
          fields[3] == '0') {
        _confirmedMotorMask = 0;
        _safetyMessage = 'Manual control expired; all motors stopped.';
      } else if (fields.length == 4 &&
          fields[1] == 'CAL' &&
          ['OPEN', 'CLOSED'].contains(fields[2])) {
        if (fields[3] == 'DONE') {
          _calibrationPhase = fields[2] == 'OPEN'
              ? CalibrationPhase.openReady
              : CalibrationPhase.ready;
          _calibrationError = null;
        } else if (['UNSTABLE', 'INVALID_SPAN'].contains(fields[3])) {
          _calibrationPhase = fields[3] == 'INVALID_SPAN'
              ? CalibrationPhase.openReady
              : CalibrationPhase.failed;
          _calibrationError = fields[3] == 'UNSTABLE'
              ? 'Readings moved too much. Hold the hand still and retry.'
              : 'Open and bent readings are too close. Check sensor placement and retry the bent capture.';
        } else {
          return;
        }
        _confirmedMotorMask = 0;
      } else if (fields.length == 3 && fields[1] == 'OUTPUT') {
        final mask = _parseMask(fields[2]);
        if (mask == null) return;
        _confirmedMotorMask = mask;
      } else {
        return;
      }
      _notify();
      return;
    }
    if (fields.length < 4 || !['ACK', 'ERR'].contains(fields[0])) return;
    final id = int.tryParse(fields[1]);
    if (id == null || id < 0 || id > 65535) return;
    final pending = _pending;
    final matches = pending != null && id == pending.id;
    if (!matches && id != 0) return;
    if (fields[0] == 'ERR') {
      if (fields.length != 4) return;
      if (id == 0 &&
          fields[2] == 'LINK' &&
          ['RX_OVERFLOW', 'TX_OVERFLOW'].contains(fields[3])) {
        _confirmedMotorMask = null;
        _safetyMessage = 'Glove communication overflow. Output state is unknown; refresh status.';
        _notify();
      }
      if (matches) _failPending(StateError('${fields[2]}: ${fields[3]}'));
      return;
    }
    bool valid = false;
    if (fields[2] == 'STATUS' &&
        (id == 0 ||
            pending?.payload == 'STATUS' ||
            pending?.payload == 'CAL:STATUS')) {
      final status = FirmwareStatus.fromFields(fields.sublist(3));
      if (status == null) return;
      _firmware = status;
      _supportsProtocol = true;
      _hapticMode = status.mode;
      _calibrationPhase = status.phase;
      _confirmedMotorMask = status.motorMask;
      _legacyFirmware = false;
      valid = true;
    } else if (matches &&
        fields[2] == 'VIB' &&
        fields.length == 6 &&
        pending.payload == 'VIB:${fields[3]},${fields[4]}') {
      final mask = _parseMask(fields[5]);
      if (mask == null) return;
      _confirmedMotorMask = mask;
      _hapticMode = HapticMode.manual;
      valid = true;
    } else if (matches &&
        fields[2] == 'MODE' &&
        fields.length == 5 &&
        pending.payload == 'MODE:${fields[3]}') {
      final mask = _parseMask(fields[4]);
      if (mask == null) return;
      _hapticMode = fields[3] == 'AUTO'
          ? HapticMode.automatic
          : HapticMode.manual;
      _confirmedMotorMask = mask;
      valid = true;
    } else if (matches && fields[2] == 'CAL') {
      if (fields.length == 5 &&
          fields[4] == 'STARTED' &&
          pending.payload == 'CAL:${fields[3]}' &&
          ['OPEN', 'CLOSED'].contains(fields[3])) {
        _calibrationPhase = fields[3] == 'OPEN'
            ? CalibrationPhase.open
            : CalibrationPhase.closed;
        valid = true;
      } else if (fields.length == 4 &&
          ((fields[3] == 'SAVED' && pending.payload == 'CAL:SAVE') ||
              (fields[3] == 'RESET' && pending.payload == 'CAL:RESET') ||
              (fields[3] == 'CANCELLED' && pending.payload == 'CAL:CANCEL'))) {
        _calibrationPhase = CalibrationPhase.idle;
        // Save/reset validity is synchronized by the next STATUS, not guessed.
        if (fields[3] != 'CANCELLED') _firmware = null;
        valid = true;
      }
      if (valid) _confirmedMotorMask = 0;
    }
    if (!valid) return;
    if (matches) {
      pending.timer?.cancel();
      _pending = null;
      if (!pending.quiet) {
        _commandState = CommandState.confirmed;
        _commandMessage = 'Confirmed';
      }
      pending.completer.complete();
    }
    _notify();
  }

  static int? _parseMask(String text) {
    if (!RegExp(r'^\d{1,2}$').hasMatch(text)) return null;
    final value = int.parse(text);
    return value <= 31 ? value : null;
  }

  Future<void> vibrateAll(bool enabled) =>
      sendCommand('<VIB:ALL,${enabled ? 1 : 0}>');
  Future<void> vibrateFinger(int finger, bool enabled) {
    if (finger < 1 || finger > 5) {
      throw RangeError.range(finger, 1, 5, 'finger');
    }
    return sendCommand('<VIB:$finger,${enabled ? 1 : 0}>');
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(disconnect());
    super.dispose();
  }
}

class _PendingCommand {
  _PendingCommand(this.id, this.payload, this.quiet, this.generation);
  final int id, generation;
  final String payload;
  final bool quiet;
  final completer = Completer<void>();
  Timer? timer;
  int attempts = 0;
}

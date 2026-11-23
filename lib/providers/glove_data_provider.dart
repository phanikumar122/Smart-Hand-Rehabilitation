import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_classic_bluetooth/flutter_classic_bluetooth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/sensor_data.dart';
import '../models/rehab_session.dart';
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
      hasLiveData && !_isSessionActive && !_isSavingSession;
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
    final data = SensorData.fromCsv(line, timestamp: _now());
    if (data == null) return;
    _lastPacket = data.timestamp;
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
    if (!RegExp(r'^<VIB:(ALL|[1-5]),[01]>$').hasMatch(command)) {
      throw ArgumentError.value(
        command,
        'command',
        'Invalid vibration command',
      );
    }
    final connection = _connection;
    if (connection == null) throw StateError('Glove is disconnected.');
    await connection.write(Uint8List.fromList(ascii.encode(command)));
    await connection.flush();
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

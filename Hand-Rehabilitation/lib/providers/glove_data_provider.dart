import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import '../models/sensor_data.dart';
import '../models/session.dart';
import '../services/storage_service.dart';

class GloveDataProvider extends ChangeNotifier {
  BluetoothConnection? _connection;
  bool _isConnected = false;
  bool _isConnecting = false;
  BluetoothDevice? _connectedDevice;

  SensorData _currentData = SensorData.empty();
  List<SensorData> _history = [];
  
  // Session tracking
  bool _isSessionActive = false;
  DateTime? _sessionStartTime;
  int _sessionMaxGrip = 0;
  List<int> _sessionMovementAverages = [];

  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  BluetoothDevice? get connectedDevice => _connectedDevice;
  SensorData get currentData => _currentData;
  List<SensorData> get history => _history;
  bool get isSessionActive => _isSessionActive;
  
  final StorageService _storageService = StorageService();

  Future<void> connectToDevice(BluetoothDevice device) async {
    if (_isConnecting || _isConnected) return;
    
    _isConnecting = true;
    notifyListeners();

    int retryCount = 0;
    const int maxRetries = 2;
    bool success = false;

    while (retryCount <= maxRetries && !success) {
      try {
        if (kDebugMode) print('Connection attempt ${retryCount + 1} to ${device.address}');
        
        _connection = await BluetoothConnection.toAddress(device.address)
            .timeout(const Duration(seconds: 15));
        
        _isConnected = true;
        _connectedDevice = device;
        success = true;
        
        _connection!.input!.listen(
          _onDataReceived,
          onDone: () => disconnect(),
          onError: (e) => disconnect(),
          cancelOnError: true,
        );
      } catch (e) {
        retryCount++;
        if (retryCount <= maxRetries) {
          await Future.delayed(const Duration(milliseconds: 1000));
        } else {
          if (kDebugMode) print('Connection failed after $maxRetries retries: $e');
        }
      }
    }

    _isConnecting = false;
    notifyListeners();
  }

  void disconnect() {
    _connection?.close();
    _connection = null;
    _isConnected = false;
    _connectedDevice = null;
    _currentData = SensorData.empty();
    if (_isSessionActive) {
      stopSession();
    }
    notifyListeners();
  }

  String _buffer = '';

  void _onDataReceived(Uint8List data) {
    try {
      // Decode data with safety for invalid characters
      _buffer += utf8.decode(data, allowMalformed: true);
      
      // Safety: Prevent buffer from growing indefinitely if no newline is received
      if (_buffer.length > 2048) {
        _buffer = _buffer.substring(_buffer.length - 1024);
      }

      int index;
      while ((index = _buffer.indexOf('\n')) >= 0) {
        String line = _buffer.substring(0, index).trim();
        _buffer = _buffer.substring(index + 1);
        
        if (line.isNotEmpty) {
          _processDataString(line);
        }
      }
    } catch (e) {
      if (kDebugMode) print('Data receive error: $e');
    }
  }

  void _processDataString(String csvLine) {
    final newData = SensorData.fromCsv(csvLine);
    if (newData == null) return; // Skip invalid packets instead of resetting to zero

    _currentData = newData;
    
    // Maintain a rolling history for charts (last 30 readings)
    _history.add(newData);
    if (_history.length > 30) {
      _history.removeAt(0);
    }

    if (_isSessionActive) {
      if (newData.grip > _sessionMaxGrip) {
        _sessionMaxGrip = newData.grip;
      }
      int avgMovement = (newData.thumb + newData.index + newData.middle + newData.ring + newData.pinky) ~/ 5;
      _sessionMovementAverages.add(avgMovement);
    }

    notifyListeners();
  }

  void startSession() {
    _isSessionActive = true;
    _sessionStartTime = DateTime.now();
    _sessionMaxGrip = 0;
    _sessionMovementAverages = [];
    notifyListeners();
  }

  Future<void> stopSession() async {
    if (!_isSessionActive || _sessionStartTime == null) return;
    
    _isSessionActive = false;
    
    final duration = DateTime.now().difference(_sessionStartTime!);
    int finalAvgMovement = 0;
    if (_sessionMovementAverages.isNotEmpty) {
      finalAvgMovement = _sessionMovementAverages.reduce((a, b) => a + b) ~/ _sessionMovementAverages.length;
    }

    final session = RehabSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      startTime: _sessionStartTime!,
      duration: duration,
      maxGrip: _sessionMaxGrip,
      averageMovement: finalAvgMovement,
    );

    await _storageService.saveSession(session);
    notifyListeners();
  }
}

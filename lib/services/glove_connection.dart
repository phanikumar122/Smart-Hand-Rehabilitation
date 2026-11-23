import 'dart:typed_data';

import 'package:flutter_classic_bluetooth/flutter_classic_bluetooth.dart';

/// The serial link boundary; sensor parsing belongs to the provider.
abstract interface class GloveConnection {
  Stream<Uint8List> get input;
  Stream<BtcConnectionState> get states;
  Future<void> write(Uint8List bytes);
  Future<void> flush();
  Future<void> close();
}

typedef GloveConnector = Future<GloveConnection> Function(BtcDevice device);

Future<GloveConnection> connectGlove(BtcDevice device) async {
  final connection = await FlutterClassicBluetooth().connect(
    address: device.address,
    timeout: const Duration(seconds: 15),
  );
  return ClassicGloveConnection(connection);
}

class ClassicGloveConnection implements GloveConnection {
  ClassicGloveConnection(this._connection);
  final BtcConnection _connection;

  @override
  Stream<Uint8List> get input => _connection.input;
  @override
  Stream<BtcConnectionState> get states => _connection.stateStream;
  @override
  Future<void> write(Uint8List bytes) => _connection.output.add(bytes);
  @override
  Future<void> flush() => _connection.output.allSent;
  @override
  Future<void> close() async {
    try {
      await _connection.close();
    } finally {
      _connection.dispose();
    }
  }
}

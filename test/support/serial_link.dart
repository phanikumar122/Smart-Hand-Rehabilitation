import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_classic_bluetooth/flutter_classic_bluetooth.dart';
import 'package:smart_glove_app/services/glove_connection.dart';

/// A test-only byte transport. The production parser receives the bytes unchanged.
class SerialLink implements GloveConnection {
  final bytes = StreamController<Uint8List>.broadcast(sync: true);
  final connectionStates = StreamController<BtcConnectionState>.broadcast(
    sync: true,
  );
  final writes = <Uint8List>[];
  int flushes = 0;
  bool closed = false;
  @override
  Stream<Uint8List> get input => bytes.stream;
  @override
  Stream<BtcConnectionState> get states => connectionStates.stream;
  @override
  Future<void> write(Uint8List data) async => writes.add(data);
  @override
  Future<void> flush() async => flushes++;
  @override
  Future<void> close() async {
    closed = true;
    await bytes.close();
    await connectionStates.close();
  }
}

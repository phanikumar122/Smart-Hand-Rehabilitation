import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_classic_bluetooth/flutter_classic_bluetooth.dart';
import 'package:smart_glove_app/services/glove_connection.dart';

/// A test-only byte transport. The production parser receives the bytes unchanged.
class SerialLink implements GloveConnection {
  SerialLink({this.autoStatus = true, this.flushGate});
  final bool autoStatus;
  final Future<void>? flushGate;
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
  Future<void> write(Uint8List data) async {
    writes.add(data);
    final command = ascii.decode(data);
    final status = RegExp(r'^<Q:(\d+):STATUS>$').firstMatch(command);
    if (autoStatus && status != null) {
      bytes.add(
        Uint8List.fromList(
          ascii.encode('ACK,${status[1]},STATUS,3.0,AUTO,1,IDLE,1,0\n'),
        ),
      );
    }
  }

  @override
  Future<void> flush() async {
    flushes++;
    await flushGate;
  }

  @override
  Future<void> close() async {
    closed = true;
    await bytes.close();
    await connectionStates.close();
  }
}

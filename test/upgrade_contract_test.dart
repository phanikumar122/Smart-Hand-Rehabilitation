import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_classic_bluetooth/flutter_classic_bluetooth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_async/fake_async.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_glove_app/models/firmware_status.dart';
import 'package:smart_glove_app/providers/glove_data_provider.dart';
import 'package:smart_glove_app/services/storage_service.dart';

import 'support/serial_link.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SerialLink link;
  late GloveDataProvider provider;
  void receive(String text) =>
      link.bytes.add(Uint8List.fromList(ascii.encode(text)));
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    link = SerialLink();
    provider = GloveDataProvider(connector: (_) async => link);
    await provider.connectToDevice(
      const BtcDevice(address: '00:11:22:33:44:55'),
    );
  });
  tearDown(() async {
    await provider.disconnect();
    provider.dispose();
  });
  test(
    'a stalled transport flush cannot leave a command pending forever',
    () async {
      await provider.disconnect();
      fakeAsync((time) {
        final gate = Completer<void>();
        final transport = SerialLink(flushGate: gate.future);
        final p = GloveDataProvider(connector: (_) async => transport);
        p.connectToDevice(const BtcDevice(address: '00:11:22:33:44:55'));
        time.flushMicrotasks();
        Object? error;
        p.vibrateFinger(3, true).catchError((Object e) {
          error = e;
        });
        time.flushMicrotasks();
        time.elapse(const Duration(milliseconds: 1100));
        expect(error, isA<TimeoutException>());
        expect(p.commandPending, isFalse);
        expect(
          p.isConnected,
          isFalse,
        ); // Close the stalled transport to prevent late queued ON writes.
        p.dispose();
        gate.complete();
        time.flushMicrotasks();
      });
    },
  );

  test('invalid firmware calibration blocks session despite fresh sensors', () {
    receive('ACK,0,STATUS,3.0,AUTO,0,IDLE,0,0\n1,2,3,4,5,600\n');
    expect(provider.hasLiveData, isTrue);
    expect(provider.canStartSession, isFalse);
  });

  test(
    'writing a command alone does not complete its acknowledgement',
    () async {
      var completed = false;
      final result = provider.vibrateFinger(3, true);
      unawaited(result.then((_) => completed = true, onError: (Object _) {}));
      await Future<void>.delayed(Duration.zero);
      expect(completed, isFalse);
    },
  );

  test('split matching ACK confirms output while sensor lines remain measured data', () async {
    final command = provider.vibrateFinger(3, true);
    expect(provider.requestedMotorMask, 4);
    expect(provider.confirmedMotorMask, 0);
    receive('1,2,3,4,5,600\nACK,2,VIB,3,');
    expect(provider.commandState, CommandState.sending);
    receive('1,4\n2,3,4,5,6,700\n');
    await command;
    expect(provider.confirmedMotorMask, 4);
    expect(provider.commandState, CommandState.confirmed);
    expect(provider.hapticMode, HapticMode.manual);
    expect(provider.history.length, 2);
    expect(provider.currentData?.grip, 700);
  });

  test(
    'wrong ID or wrong target cannot acknowledge pending motor command',
    () async {
      final command = provider.vibrateFinger(3, true);
      receive('ACK,99,VIB,3,1,4\nACK,2,VIB,2,1,2\nACK,2,VIB,3,1,32\n');
      expect(provider.commandPending, isTrue);
      expect(provider.confirmedMotorMask, 0);
      receive('ACK,2,VIB,3,1,4\n');
      await command;
    },
  );

  test('ERR fails pending command without claiming requested output', () async {
    final command = provider.vibrateFinger(3, true);
    final check = expectLater(command, throwsStateError);
    receive('ERR,2,VIB,REARM_REQUIRED\n');
    await check;
    expect(provider.commandState, CommandState.failed);
    expect(provider.confirmedMotorMask, 0);
  });

  test('timeout events and lease expiry change confirmed output', () async {
    final command = provider.vibrateAll(true);
    receive('ACK,2,VIB,ALL,1,31\n');
    await command;
    receive('EVT,VIB,3,TIMEOUT,27\n');
    expect(provider.confirmedMotorMask, 27);
    expect(provider.safetyMessage, contains('Finger 3'));
    receive('EVT,LINK,LEASE_EXPIRED,0\n');
    expect(provider.confirmedMotorMask, 0);
  });

  test('calibration captures, errors, save and status gate sessions', () async {
    receive('1,2,3,4,5,600\n');
    expect(provider.canStartSession, isTrue);
    final open = provider.calibrateOpen();
    receive('ACK,2,CAL,OPEN,STARTED\n');
    await open;
    expect(provider.calibrationActive, isTrue);
    expect(provider.canStartSession, isFalse);
    receive('EVT,CAL,OPEN,DONE\n');
    expect(provider.calibrationPhase, CalibrationPhase.openReady);
    final bent = provider.calibrateClosed();
    receive('ACK,3,CAL,CLOSED,STARTED\nEVT,CAL,CLOSED,INVALID_SPAN\n');
    await bent;
    expect(provider.calibrationPhase, CalibrationPhase.openReady);
    expect(provider.calibrationError, contains('too close'));
    final retry = provider.calibrateClosed();
    receive('ACK,4,CAL,CLOSED,STARTED\nEVT,CAL,CLOSED,DONE\n');
    await retry;
    final save = provider.saveCalibration();
    receive('ACK,5,CAL,SAVED\n');
    await save;
    expect(provider.canStartSession, isFalse); // Require authoritative status.
    receive('ACK,0,STATUS,3.0,AUTO,1,IDLE,1,0\n');
    expect(provider.canStartSession, isFalse);
    receive('1,2,3,4,5,600\n');
    expect(provider.canStartSession, isTrue);
  });

  test(
    'disconnect fails pending command and clears confirmed output',
    () async {
      final command = provider.vibrateAll(true);
      final check = expectLater(command, throwsStateError);
      await provider.disconnect();
      await check;
      expect(provider.commandState, CommandState.failed);
      expect(provider.confirmedMotorMask, isNull);
    },
  );

  test('retry uses identical ID and eventually fails without ACK', () async {
    await provider.disconnect();
    fakeAsync((time) {
      final transport = SerialLink();
      final p = GloveDataProvider(connector: (_) async => transport);
      p.connectToDevice(const BtcDevice(address: '00:11:22:33:44:55'));
      time.flushMicrotasks();
      Object? error;
      p.vibrateFinger(3, true).catchError((Object e) {
        error = e;
      });
      time.flushMicrotasks();
      time.elapse(const Duration(milliseconds: 2800));
      expect(error, isA<TimeoutException>());
      expect(transport.writes.skip(1).map(ascii.decode).toList(), [
        '<Q:2:VIB:3,1>',
        '<Q:2:VIB:3,1>',
        '<Q:2:VIB:3,1>',
      ]);
      expect(p.confirmedMotorMask, isNull);
      p.dispose();
      time.flushMicrotasks();
    });
  });

  test('responses do not keep stale sensor data alive', () async {
    await provider.disconnect();
    fakeAsync((time) {
      final transport = SerialLink();
      final p = GloveDataProvider(
        connector: (_) async => transport,
        now: time.getClock(DateTime.utc(2026)).now,
      );
      p.connectToDevice(const BtcDevice(address: '00:11:22:33:44:55'));
      time.flushMicrotasks();
      transport.bytes.add(Uint8List.fromList(ascii.encode('1,2,3,4,5,600\n')));
      time.elapse(const Duration(seconds: 2));
      expect(p.hasLiveData, isFalse);
      expect(p.currentData, isNull);
      expect(p.history.length, 1);
      p.dispose();
      time.flushMicrotasks();
    });
  });

  test(
    'a confirmed upgraded glove cannot bypass calibration using legacy mode',
    () async {
      await expectLater(provider.setLegacyFirmwareMode(true), throwsStateError);
    },
  );
  test('older firmware requires explicit mode and sends exact unconfirmed legacy bytes', () async {
    await provider.disconnect();
    fakeAsync((time) {
      final transport = SerialLink(autoStatus: false);
      final p = GloveDataProvider(
        connector: (_) async => transport,
        now: time.getClock(DateTime.utc(2026)).now,
      );
      p.connectToDevice(const BtcDevice(address: '00:11:22:33:44:55'));
      time.flushMicrotasks();
      time.elapse(const Duration(seconds: 3));
      transport.bytes.add(Uint8List.fromList(ascii.encode('1,2,3,4,5,600\n')));
      p.setLegacyFirmwareMode(true);
      time.flushMicrotasks();
      expect(p.canStartSession, isFalse);
      transport.bytes.add(Uint8List.fromList(ascii.encode('1,2,3,4,5,600\n')));
      expect(p.canStartSession, isTrue);
      p.vibrateFinger(3, true);
      time.flushMicrotasks();
      expect(ascii.decode(transport.writes.last), '<VIB:3,1>');
      expect(p.commandState, CommandState.sentUnconfirmed);
      expect(p.confirmedMotorMask, isNull);
      p.dispose();
      time.flushMicrotasks();
    });
  });
  test('commands wait for a complete sensor receive window when the last frame is old', () async {
    await provider.disconnect();
    fakeAsync((time) {
      final transport = SerialLink();
      final p = GloveDataProvider(
        connector: (_) async => transport,
        now: time.getClock(DateTime.utc(2026)).now,
      );
      p.connectToDevice(const BtcDevice(address: '00:11:22:33:44:55'));
      time.flushMicrotasks();
      transport.bytes.add(Uint8List.fromList(ascii.encode('1,2,3,4,5,600\n')));
      time.elapse(const Duration(milliseconds: 40));
      p.vibrateFinger(3, true);
      time.flushMicrotasks();
      expect(transport.writes.length, 1);
      transport.bytes.add(Uint8List.fromList(ascii.encode('2,3,4,5,6,700')));
      time.flushMicrotasks();
      expect(transport.writes.length, 1);
      transport.bytes.add(Uint8List.fromList(ascii.encode('\n')));
      time.flushMicrotasks();
      expect(ascii.decode(transport.writes.last), '<Q:2:VIB:3,1>');
      transport.bytes.add(
        Uint8List.fromList(ascii.encode('ACK,2,VIB,3,1,4\n')),
      );
      time.flushMicrotasks();
      expect(p.commandState, CommandState.confirmed);
      p.dispose();
      time.flushMicrotasks();
    });
  });
  test(
    'missing status ACK never silently downgrades to legacy session mode',
    () async {
      await provider.disconnect();
      fakeAsync((time) {
        final transport = SerialLink(autoStatus: false);
        final p = GloveDataProvider(
          connector: (_) async => transport,
          now: time.getClock(DateTime.utc(2026)).now,
        );
        p.connectToDevice(const BtcDevice(address: '00:11:22:33:44:55'));
        time.flushMicrotasks();
        time.elapse(const Duration(milliseconds: 2400));
        transport.bytes.add(
          Uint8List.fromList(ascii.encode('1,2,3,4,5,600\n')),
        );
        time.elapse(const Duration(milliseconds: 400));
        expect(p.hasLiveData, isTrue);
        expect(p.legacyFirmware, isFalse);
        expect(p.canStartSession, isFalse);
        p.dispose();
        time.flushMicrotasks();
      });
    },
  );
  test('late capture ACK cannot rewind a completed capture', () async {
    final open = provider.calibrateOpen();
    receive('EVT,CAL,OPEN,DONE\nACK,2,CAL,OPEN,STARTED\n');
    await open;
    expect(provider.calibrationPhase, CalibrationPhase.openReady);
    final closed = provider.calibrateClosed();
    receive('EVT,CAL,CLOSED,UNSTABLE\nACK,3,CAL,CLOSED,STARTED\n');
    await closed;
    expect(provider.calibrationPhase, CalibrationPhase.failed);
    expect(provider.calibrationError, contains('still'));
  });

  test(
    'all off supersedes an unconfirmed ON and ignores its late reply',
    () async {
      final on = provider.vibrateFinger(3, true);
      final replaced = expectLater(on, throwsA(isA<CommandSuperseded>()));
      final off = provider.vibrateAll(false);
      await replaced;
      await Future<void>.delayed(Duration.zero);
      expect(link.writes.map(ascii.decode), [
        '<Q:1:STATUS>',
        '<Q:2:VIB:3,1>',
        '<Q:3:VIB:ALL,0>',
      ]);
      receive('ACK,2,VIB,3,1,4\n');
      expect(provider.confirmedMotorMask, isNull);
      receive('ACK,3,VIB,ALL,0,0\n');
      await off;
      expect(provider.confirmedMotorMask, 0);
      expect(provider.commandState, CommandState.confirmed);
    },
  );

  test('all off preempts an initial status probe with no response', () async {
    await provider.disconnect();
    final stalled = SerialLink(autoStatus: false);
    final p = GloveDataProvider(connector: (_) async => stalled);
    addTearDown(p.dispose);
    final connecting = p.connectToDevice(
      const BtcDevice(address: '00:11:22:33:44:55'),
    );
    await Future<void>.delayed(Duration.zero);
    expect(p.commandPending, isTrue);
    final off = p.vibrateAll(false);
    expect(await connecting, isTrue);
    expect(stalled.writes.map(ascii.decode), [
      '<Q:1:STATUS>',
      '<Q:2:VIB:ALL,0>',
    ]);
    stalled.bytes.add(Uint8List.fromList(ascii.encode('ACK,2,VIB,ALL,0,0\n')));
    await off;
    expect(p.confirmedMotorMask, 0);
  });

  test('all off shares one request when tapped repeatedly', () async {
    final first = provider.vibrateAll(false);
    final second = provider.vibrateAll(false);
    final completed = Future.wait([first, second]);
    await Future<void>.delayed(Duration.zero);
    expect(link.writes.map(ascii.decode), ['<Q:1:STATUS>', '<Q:2:VIB:ALL,0>']);
    receive('ACK,2,VIB,ALL,0,0\n');
    await completed;
  });

  test('nondecimal request IDs and motor masks are not accepted', () async {
    final command = provider.vibrateAll(true);
    receive('ACK,0x2,VIB,ALL,1,31\nACK,2,VIB,ALL,1,0x1f\n');
    receive('ACK,0,STATUS,3.0,MANUAL,1,IDLE,1,0x1f\n');
    expect(provider.commandPending, isTrue);
    expect(provider.confirmedMotorMask, 0);
    receive('ACK,2,VIB,ALL,1,31\n');
    await command;
  });

  test(
    'invalid calibration stops recording before subsequent frames',
    () async {
      receive('1,2,3,4,5,600\n');
      expect(provider.startSession(), isTrue);
      receive('1,2,3,4,5,601\nACK,0,STATUS,3.0,AUTO,0,IDLE,0,0\n');
      receive('0,0,0,0,0,999\n');
      expect(provider.isSessionActive, isFalse);
      await Future<void>.delayed(Duration.zero);
      final saved = (await StorageService().getSessions()).single;
      expect(saved.readingCount, 1);
      expect(saved.maxGrip, 601);
      expect(provider.sessionMessage, contains('interrupted'));
      receive('ACK,0,STATUS,3.0,AUTO,1,IDLE,1,0\n');
      expect(provider.canStartSession, isFalse);
      receive('1,2,3,4,5,602\n');
      expect(provider.canStartSession, isTrue);
    },
  );
}

import 'dart:convert';
import 'dart:typed_data';

import 'package:fake_async/fake_async.dart';

import 'package:flutter_classic_bluetooth/flutter_classic_bluetooth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_glove_app/providers/glove_data_provider.dart';
import 'package:smart_glove_app/services/storage_service.dart';

import 'support/serial_link.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const device = BtcDevice(address: '00:11:22:33:44:55');
  late SerialLink link;
  late GloveDataProvider provider;
  void receive(String line) =>
      link.bytes.add(Uint8List.fromList(ascii.encode(line)));

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    link = SerialLink();
    provider = GloveDataProvider(connector: (_) async => link);
    await provider.connectToDevice(device);
    await provider.settingsReady;
  });
  tearDown(() async {
    await provider.disconnect();
    provider.dispose();
  });
  test('assembles split packets without partial readings', () {
    receive('10,20,30,');
    expect(provider.currentData, isNull);
    receive('40,50,600\n');
    expect(provider.currentData?.grip, 600);
    expect(provider.history.length, 1);
  });
  test('processes two packets in one chunk', () {
    receive('1,2,3,4,5,6\n10,20,30,40,50,600\r\n');
    expect(provider.history.length, 2);
    expect(provider.currentData?.thumb, 10);
  });
  test('drops garbage bytes and invalid ranges, then recovers', () {
    link.bytes.add(Uint8List.fromList([255, 0, 10]));
    receive('91,2,3,4,5,6\n');
    expect(provider.currentData, isNull);
    receive('1,2,3,4,5,6\n');
    expect(provider.history.length, 1);
  });
  test('overflow discards the whole damaged frame through its newline', () {
    receive(' ' * 2100);
    receive('1,2,3,4,5,6\n');
    expect(provider.currentData, isNull);
    receive('10,20,30,40,50,600\n');
    expect(provider.currentData?.grip, 600);
  });
  test('history is bounded to 3000 readings and cannot be mutated', () {
    for (var i = 0; i < 3010; i++) {
      receive('1,2,3,4,5,6\n');
    }
    expect(provider.history.length, 3000);
    expect(() => provider.history.clear(), throwsUnsupportedError);
  });
  test('disconnect clears readings and history', () {
    receive('1,2,3,4,5,6\n');
    provider.disconnect();
    expect(provider.currentData, isNull);
    expect(provider.history, isEmpty);
    receive('10,20,30,40,50,600\n');
    expect(provider.currentData, isNull);
  });
  test('cannot start a session without a received packet', () {
    provider.startSession();
    expect(provider.isSessionActive, isFalse);
  });
  test('no session is saved with zero readings after start', () async {
    receive('1,2,3,4,5,6\n');
    provider.startSession();
    await provider.stopSession();
    expect(await StorageService().getSessions(), isEmpty);
    expect(provider.sessionMessage, contains('discarded'));
  });
  test('sends exact firmware commands and awaits output flush', () async {
    await provider.vibrateAll(true);
    await provider.vibrateAll(false);
    await provider.vibrateFinger(3, false);
    await provider.vibrateFinger(5, true);
    expect(link.writes.map(ascii.decode).toList(), [
      '<VIB:ALL,1>',
      '<VIB:ALL,0>',
      '<VIB:3,0>',
      '<VIB:5,1>',
    ]);
    expect(link.flushes, 4);
    expect(() => provider.vibrateFinger(0, true), throwsRangeError);
    expect(() => provider.vibrateFinger(6, true), throwsRangeError);
    await expectLater(provider.sendCommand('<VIB:ALL,2>'), throwsArgumentError);
    await provider.disconnect();
    await expectLater(provider.vibrateAll(true), throwsStateError);
  });
  test('disconnect saves only packets received during the session', () async {
    receive('90,90,90,90,90,1023\n');
    expect(provider.startSession(), isTrue);
    receive('10,20,30,40,50,600\n0,0,0,0,0,0\n');
    await provider.disconnect();
    final sessions = await StorageService().getSessions();
    expect(sessions, hasLength(1));
    expect(sessions.single.readingCount, 2);
    expect(sessions.single.maxGrip, 600);
    expect(sessions.single.averageMovement, 15);
    expect(provider.isSessionActive, isFalse);
  });
  test('elapsed timing belongs to provider and stops on disconnect', () async {
    await provider.disconnect();
    fakeAsync((time) {
      final transport = SerialLink();
      final p = GloveDataProvider(
        connector: (_) async => transport,
        now: time.getClock(DateTime.utc(2026)).now,
      );
      p.connectToDevice(device);
      time.flushMicrotasks();
      transport.bytes.add(Uint8List.fromList(ascii.encode('1,2,3,4,5,6\n')));
      expect(p.startSession(), isTrue);
      time.elapse(const Duration(seconds: 3));
      expect(p.sessionElapsed, const Duration(seconds: 3));
      expect(p.status, 'No signal');
      expect(p.canStartSession, isFalse);
      p.disconnect();
      time.elapse(const Duration(seconds: 5));
      expect(p.sessionElapsed, const Duration(seconds: 3));
      expect(p.isSessionActive, isFalse);
      p.dispose();
      time.flushMicrotasks();
    });
  });
  test('auto-reconnect preference survives a new provider', () async {
    await provider.setAutoReconnect(true);
    final next = GloveDataProvider();
    await next.settingsReady;
    expect(next.autoReconnect, isTrue);
    next.dispose();
  });
  test('history removes packets older than five minutes', () async {
    await provider.disconnect();
    var timestamp = DateTime.utc(2026);
    final transport = SerialLink();
    final p = GloveDataProvider(
      connector: (_) async => transport,
      now: () => timestamp,
    );
    addTearDown(p.dispose);
    await p.connectToDevice(device);
    transport.bytes.add(Uint8List.fromList(ascii.encode('1,2,3,4,5,6\n')));
    timestamp = timestamp.add(const Duration(minutes: 5, milliseconds: 100));
    transport.bytes.add(
      Uint8List.fromList(ascii.encode('10,20,30,40,50,600\n')),
    );
    expect(p.history, hasLength(1));
    expect(p.history.single.grip, 600);
  });
  test('disabling auto-reconnect cancels queued retry', () async {
    final transport = SerialLink();
    var attempts = 0;
    final p = GloveDataProvider(
      connector: (_) async {
        attempts++;
        if (attempts == 1) return transport;
        throw StateError('Glove unavailable');
      },
    );
    addTearDown(p.dispose);
    await p.connectToDevice(device);
    await p.setAutoReconnect(true);
    transport.connectionStates.add(BtcConnectionState.disconnected);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(p.isReconnecting, isTrue);
    await p.setAutoReconnect(false);
    await Future<void>.delayed(const Duration(milliseconds: 2200));
    expect(attempts, 1);
    expect(p.isReconnecting, isFalse);
  });
  test('watchdog clears stale data and blocks starting', () async {
    receive('1,2,3,4,5,6\n');
    await Future<void>.delayed(const Duration(milliseconds: 2050));
    expect(provider.currentData, isNull);
    provider.startSession();
    expect(provider.isSessionActive, isFalse);
    receive('10,20,30,40,50,600\n');
    expect(provider.currentData?.grip, 600);
  });

  test(
    'manual disconnect cancels a reconnect during asynchronous cleanup',
    () async {
      final transport = SerialLink();
      var attempts = 0;
      final p = GloveDataProvider(
        connector: (_) async {
          attempts++;
          if (attempts == 1) return transport;
          throw StateError('Glove unavailable');
        },
      );
      addTearDown(p.dispose);
      await p.connectToDevice(device);
      await p.setAutoReconnect(true);
      transport.connectionStates.add(BtcConnectionState.disconnected);
      expect(p.isConnected, isFalse);
      await p.disconnect();
      await Future<void>.delayed(const Duration(milliseconds: 2200));
      expect(attempts, 1);
      expect(p.isReconnecting, isFalse);
    },
  );

  test(
    'reconnect retries three times, two seconds apart, then stops',
    () async {
      final transport = SerialLink();
      final clock = Stopwatch()..start();
      final attemptTimes = <Duration>[];
      final p = GloveDataProvider(
        connector: (_) async {
          attemptTimes.add(clock.elapsed);
          if (attemptTimes.length == 1) return transport;
          throw StateError('Glove unavailable');
        },
      );
      addTearDown(p.dispose);
      await p.connectToDevice(device);
      await p.setAutoReconnect(true);
      transport.connectionStates.add(BtcConnectionState.disconnected);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(p.isReconnecting, isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 8400));
      expect(attemptTimes.length, 4);
      for (var i = 1; i < 4; i++) {
        expect(
          attemptTimes[i] - attemptTimes[i - 1],
          greaterThanOrEqualTo(const Duration(seconds: 2)),
        );
      }
      expect(p.isConnected, isFalse);
      expect(p.isReconnecting, isFalse);
      expect(p.connectionError, contains('Glove unavailable'));
    },
  );
}

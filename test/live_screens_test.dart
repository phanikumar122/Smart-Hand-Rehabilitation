import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_classic_bluetooth/flutter_classic_bluetooth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_glove_app/providers/glove_data_provider.dart';
import 'package:smart_glove_app/screens/connection_screen.dart';
import 'package:smart_glove_app/screens/progress_screen.dart';
import 'package:smart_glove_app/screens/today_screen.dart';
import 'package:smart_glove_app/screens/live_hand_screen.dart';
import 'package:smart_glove_app/screens/app_shell.dart';
import 'package:smart_glove_app/screens/session_screen.dart';
import 'package:smart_glove_app/screens/settings_screen.dart';
import 'package:smart_glove_app/widgets/haptic_control_panel.dart';

import 'support/bluetooth_radio.dart';
import 'support/serial_link.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const device = BtcDevice(address: '00:11:22:33:44:55');
  late GloveDataProvider provider;
  late SerialLink link;
  late BluetoothRadio radio;
  late FlutterClassicBluetoothPlatform platform;
  late DateTime now;
  Widget app(Widget home, {double textScale = 1}) =>
      ChangeNotifierProvider.value(
        value: provider,
        child: MaterialApp(
          theme: ThemeData.dark(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: home,
        ),
      );
  void receive(String line) =>
      link.bytes.add(Uint8List.fromList(ascii.encode(line)));
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    platform = FlutterClassicBluetoothPlatform.instance;
    radio = BluetoothRadio();
    FlutterClassicBluetoothPlatform.instance = radio;
    now = DateTime.utc(2026);
    link = SerialLink();
    provider = GloveDataProvider(connector: (_) async => link, now: () => now);
    await provider.settingsReady;
  });
  tearDown(() async {
    await provider.disconnect();
    provider.dispose();
    FlutterClassicBluetoothPlatform.instance = platform;
    await radio.close();
  });
  testWidgets('connection gate has no bypass and scanning starts only on tap', (
    tester,
  ) async {
    await tester.pumpWidget(app(const AppShell()));
    await tester.pumpAndSettle();
    expect(find.byType(ConnectionScreen), findsOneWidget);
    expect(find.text('Live Dashboard'), findsNothing);
    expect(radio.scans, 0);
    expect(radio.permissionRequests.first, {
      BtcPermission.scan,
      BtcPermission.connect,
    });
    await tester.tap(find.text('Scan'));
    await tester.pump();
    expect(radio.scans, 1);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(radio.adapterEvents.hasListener, isFalse);
    expect(radio.discoveryEvents.hasListener, isFalse);
    expect(radio.discoveryStateEvents.hasListener, isFalse);
  });
  testWidgets('missing readings never display numeric sensor values', (
    tester,
  ) async {
    for (final screen in [
      const TodayScreen(),
      const LiveHandScreen(),
      const ProgressScreen(),
      const SessionScreen(),
    ]) {
      await tester.pumpWidget(app(screen));
      await tester.pump();
      expect(find.textContaining('No signal'), findsWidgets);
      expect(find.text('0°'), findsNothing);
      expect(find.text('Grip: 0'), findsNothing);
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('connected shell exposes four focused destinations', (
    tester,
  ) async {
    await tester.runAsync(() => provider.connectToDevice(device));
    await tester.pumpWidget(app(const AppShell()));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationDestination), findsNWidgets(4));
    for (final label in ['Today', 'Live', 'Session', 'Progress']) {
      expect(find.text(label), findsOneWidget);
    }
    await tester.tap(find.text('Progress'));
    await tester.pumpAndSettle();
    expect(find.text('Live trends'), findsOneWidget);
    expect(find.text('Sessions'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'session start requires a recent packet and elapsed survives navigation',
    (tester) async {
      await tester.runAsync(() => provider.connectToDevice(device));
      await tester.pumpWidget(app(const SessionScreen()));
      await tester.pump();
      expect(
        tester
            .widget<ElevatedButton>(
              find.widgetWithText(ElevatedButton, 'Start Session'),
            )
            .onPressed,
        isNull,
      );
      receive('10,20,30,40,50,600\n');
      await tester.pump();
      await tester.tap(find.text('Start Session'));
      await tester.pump();
      expect(provider.isSessionActive, isTrue);
      await tester.pumpWidget(app(const LiveHandScreen()));
      now = now.add(const Duration(seconds: 3));
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpWidget(app(const SessionScreen()));
      await tester.pump();
      expect(find.text('00:03'), findsOneWidget);
      await tester.tap(find.text('Stop Session'));
      await tester.pumpAndSettle();
      expect(find.textContaining('discarded'), findsWidgets);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('charts draw only measured data and hide stale signal', (
    tester,
  ) async {
    await tester.runAsync(() => provider.connectToDevice(device));
    receive('10,20,30,40,50,600\n');
    now = now.add(const Duration(milliseconds: 100));
    receive('20,30,40,50,60,700\n');
    await tester.pumpWidget(app(const ProgressScreen()));
    await tester.pumpAndSettle();
    expect(find.text('No signal'), findsNothing);
    expect(tester.takeException(), isNull);
    now = now.add(const Duration(seconds: 2));
    await tester.pumpWidget(app(const ProgressScreen(), textScale: 1.1));
    await tester.pump();
    expect(find.text('No signal'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'vibration controls disable without connection and send exact bytes',
    (tester) async {
      await tester.pumpWidget(app(const Scaffold(body: HapticControlPanel())));
      expect(
        tester
            .widget<ElevatedButton>(
              find.widgetWithText(ElevatedButton, 'All on'),
            )
            .onPressed,
        isNull,
      );
      await tester.runAsync(() => provider.connectToDevice(device));
      await tester.pump();
      await tester.tap(find.text('All on'));
      link.bytes.add(Uint8List.fromList(ascii.encode('ACK,2,VIB,ALL,1,31\n')));
      await tester.pumpAndSettle();
      expect(link.writes.map(ascii.decode), [
        '<Q:1:STATUS>',
        '<Q:2:VIB:ALL,1>',
      ]);
      await tester.tap(find.byType(Switch).at(2));
      link.bytes.add(Uint8List.fromList(ascii.encode('ACK,3,VIB,3,0,27\n')));
      await tester.pumpAndSettle();
      expect(link.writes.map(ascii.decode), [
        '<Q:1:STATUS>',
        '<Q:2:VIB:ALL,1>',
        '<Q:3:VIB:3,0>',
      ]);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'phone and landscape layouts handle large text without exceptions',
    (tester) async {
      for (final size in [const Size(375, 812), const Size(812, 375)]) {
        tester.view.reset();
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        for (final screen in [
          const TodayScreen(),
          const SessionScreen(),
          const LiveHandScreen(),
          const ConnectionScreen(),
          const SettingsScreen(),
        ]) {
          await tester.pumpWidget(app(screen, textScale: 2));
          await tester.pump();
          expect(tester.takeException(), isNull, reason: '$screen at $size');
        }
      }
      await tester.pumpWidget(const SizedBox());
      tester.view.reset();
    },
  );
  testWidgets(
    'settings explains calibration and prevents disconnected capture',
    (tester) async {
      await tester.pumpWidget(app(const SettingsScreen(), textScale: 2));
      await tester.scrollUntilVisible(find.text('Capture open hand'), 250);
      expect(find.text('Glove calibration'), findsOneWidget);
      expect(
        tester
            .widget<OutlinedButton>(
              find.widgetWithText(OutlinedButton, 'Capture open hand'),
            )
            .onPressed,
        isNull,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}

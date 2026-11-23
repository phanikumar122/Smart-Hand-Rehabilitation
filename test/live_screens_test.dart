import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_classic_bluetooth/flutter_classic_bluetooth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_glove_app/providers/glove_data_provider.dart';
import 'package:smart_glove_app/screens/bluetooth_screen.dart';
import 'package:smart_glove_app/screens/charts_screen.dart';
import 'package:smart_glove_app/screens/dashboard_screen.dart';
import 'package:smart_glove_app/screens/hand_viz_screen.dart';
import 'package:smart_glove_app/screens/main_wrapper.dart';
import 'package:smart_glove_app/screens/session_screen.dart';
import 'package:smart_glove_app/widgets/vibration_panel.dart';

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
    await tester.pumpWidget(app(const MainWrapper()));
    await tester.pumpAndSettle();
    expect(find.byType(BluetoothScreen), findsOneWidget);
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
      const DashboardScreen(),
      const HandVizScreen(),
      const ChartsScreen(),
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
      await tester.pumpWidget(app(const HandVizScreen()));
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
    await tester.pumpWidget(app(const ChartsScreen()));
    await tester.pumpAndSettle();
    expect(find.text('No signal'), findsNothing);
    expect(tester.takeException(), isNull);
    now = now.add(const Duration(seconds: 2));
    await tester.pumpWidget(app(const ChartsScreen(), textScale: 1.1));
    await tester.pump();
    expect(find.text('No signal'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'vibration controls disable without connection and send exact bytes',
    (tester) async {
      await tester.pumpWidget(app(const Scaffold(body: VibrationPanel())));
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
      await tester.pumpAndSettle();
      expect(link.writes.map(ascii.decode), ['<VIB:ALL,1>']);
      await tester.tap(find.byType(Switch).at(2));
      await tester.pumpAndSettle();
      expect(link.writes.map(ascii.decode), ['<VIB:ALL,1>', '<VIB:3,0>']);
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
          const DashboardScreen(),
          const SessionScreen(),
          const HandVizScreen(),
          const BluetoothScreen(),
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
}

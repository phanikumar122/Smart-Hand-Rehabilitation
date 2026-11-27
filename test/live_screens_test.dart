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
import 'package:smart_glove_app/screens/splash_screen.dart';
import 'package:smart_glove_app/widgets/haptic_control_panel.dart';
import 'package:smart_glove_app/theme/app_theme.dart';
import 'package:smart_glove_app/main.dart';

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
  Widget app(Widget home, {double textScale = 1, bool reduceMotion = false}) =>
      ChangeNotifierProvider.value(
        value: provider,
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
              disableAnimations: reduceMotion,
            ),
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
      expect(find.text('0/90'), findsNothing);
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
      expect(find.widgetWithText(NavigationDestination, label), findsOneWidget);
    }
    await tester.tap(find.text('Progress'));
    await tester.pumpAndSettle();
    expect(find.text('Live trends'), findsOneWidget);
    expect(find.text('Sessions'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'selecting a finger shows its reading and All restores the average',
    (tester) async {
      await tester.runAsync(() => provider.connectToDevice(device));
      receive('10,20,30,40,50,600\n');
      await tester.pumpWidget(app(const LiveHandScreen()));
      await tester.pumpAndSettle();
      final selectedReading = find.byKey(const ValueKey('selected-bend'));
      expect(selectedReading, findsOneWidget);
      expect(tester.widget<Text>(selectedReading).data, '30/90');
      await tester.tap(find.widgetWithText(ChoiceChip, 'Thumb'));
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(selectedReading).data, '10/90');
      receive('65,20,30,40,50,600\n');
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(selectedReading).data, '65/90');
      await tester.tap(find.widgetWithText(ChoiceChip, 'All'));
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(selectedReading).data, '41/90');
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('finger focus survives switching tabs', (tester) async {
    await tester.runAsync(() => provider.connectToDevice(device));
    receive('10,20,30,40,50,600\n');
    await tester.pumpWidget(app(const AppShell()));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(NavigationDestination, 'Live'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Thumb'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(NavigationDestination, 'Progress'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(NavigationDestination, 'Live'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('selected-bend'))).data,
      '10/90',
    );
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'finger movement animates with constant grip and retargets without jumping',
    (tester) async {
      await tester.runAsync(() => provider.connectToDevice(device));
      receive('0,0,0,0,0,600\n');
      await tester.pumpWidget(app(const LiveHandScreen()));
      await tester.pumpAndSettle();
      final canvas = find.byKey(const ValueKey('hand-canvas'));
      expect(canvas, findsOneWidget);
      Future<Uint8List> pixels() async {
        final image = await captureImage(tester.element(canvas));
        final bytes = (await image.toByteData())!.buffer.asUint8List();
        image.dispose();
        return bytes;
      }

      final open = await tester.runAsync(pixels);
      receive('90,0,0,0,0,600\n');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      final moving = await tester.runAsync(pixels);
      expect(moving, isNot(equals(open)));
      receive('45,0,0,0,0,600\n');
      await tester.pump();
      final retargeted = await tester.runAsync(pixels);
      expect(retargeted, equals(moving));
      await tester.pumpAndSettle();
      final settled = await tester.runAsync(pixels);
      expect(settled, isNot(equals(retargeted)));
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'focused finger clears its reading when the live signal expires',
    (tester) async {
      await tester.runAsync(() => provider.connectToDevice(device));
      receive('10,20,30,40,50,600\n');
      await tester.pumpWidget(app(const LiveHandScreen(), reduceMotion: true));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'Ring'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('selected-bend'))).data,
        '40/90',
      );
      now = now.add(const Duration(seconds: 2));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 550)),
      );
      await tester.pump();
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('selected-bend'))).data,
        '--',
      );
      expect(find.text('No signal'), findsWidgets);
      await tester.pumpWidget(const SizedBox());
    },
  );
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
  testWidgets(
    'language selection changes the whole app to native Telugu and Hindi',
    (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const SmartGloveApp(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 650));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      expect(find.text('తెలుగు'), findsOneWidget);
      await tester.tap(find.text('తెలుగు'));
      await tester.pumpAndSettle();
      expect(find.text('అమరికలు'), findsOneWidget);
      expect(find.text('భాష'), findsOneWidget);
      await tester.tap(find.text('हिन्दी'));
      await tester.pumpAndSettle();
      expect(find.text('सेटिंग्स'), findsNothing);
      expect(find.text('व्यवस्था'), findsOneWidget);
      expect(find.text('भाषा'), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('दस्ताना जोड़ें'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('reduced motion shows the splash mark immediately', (
    tester,
  ) async {
    await tester.pumpWidget(app(const SplashScreen(), reduceMotion: true));
    final fade = find.descendant(
      of: find.byType(SplashScreen),
      matching: find.byType(FadeTransition),
    );
    expect(tester.widget<FadeTransition>(fade).opacity.value, 1);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 1500));
  });
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
  testWidgets('all off stays enabled while a command is pending', (
    tester,
  ) async {
    await tester.runAsync(() => provider.connectToDevice(device));
    await tester.pumpWidget(app(const Scaffold(body: HapticControlPanel())));
    await tester.tap(find.text('All on'));
    await tester.pump();
    final off = find.widgetWithText(OutlinedButton, 'All off');
    expect(tester.widget<OutlinedButton>(off).onPressed, isNotNull);
    await tester.tap(off);
    await tester.pump();
    expect(ascii.decode(link.writes.last), '<Q:3:VIB:ALL,0>');
    receive('ACK,3,VIB,ALL,0,0\n');
    await tester.pumpAndSettle();
    expect(provider.confirmedMotorMask, 0);
  });

  testWidgets('timed-out finger has an explicit OFF action', (tester) async {
    await tester.runAsync(() => provider.connectToDevice(device));
    await tester.pumpWidget(app(const Scaffold(body: HapticControlPanel())));
    receive('EVT,VIB,1,TIMEOUT,0\n');
    await tester.pump();
    await tester.tap(find.byTooltip('Send OFF to Thumb'));
    await tester.pump();
    expect(ascii.decode(link.writes.last), '<Q:2:VIB:1,0>');
    receive('ACK,2,VIB,1,0,0\n');
    await tester.pumpAndSettle();
    expect(find.byTooltip('Send OFF to Thumb'), findsNothing);
  });

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

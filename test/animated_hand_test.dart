import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:smart_glove_app/models/sensor_data.dart';
import 'package:smart_glove_app/theme/app_theme.dart';
import 'package:smart_glove_app/widgets/animated_hand.dart';

Widget fixture(
  String? packet, {
  int? inspected,
  bool light = false,
  Key? handKey,
}) => MaterialApp(
  theme: light ? AppTheme.lightTheme : AppTheme.darkTheme,
  home: Scaffold(
    body: Center(
      child: SizedBox(
        width: 270,
        height: 350,
        child: AnimatedHand(
          key: handKey,
          data: packet == null ? null : SensorData.fromCsv(packet),
          selectedFinger: inspected,
          onFingerSelected: (_) {},
        ),
      ),
    ),
  ),
);

Future<Uint8List> pixels(WidgetTester tester) async {
  final image = await captureImage(
    tester.element(find.byKey(const ValueKey('hand-canvas'))),
  );
  final rgba = (await image.toByteData())!.buffer.asUint8List();
  image.dispose();
  return rgba;
}

// Fixed reference points at the five finger roots in the 270 x 350 diagram.
const roots = [
  Offset(77, 226),
  Offset(97, 169),
  Offset(138, 158),
  Offset(179, 169),
  Offset(215, 186),
];
bool whiteAt(Uint8List rgba, Offset point) {
  final start = (point.dy.toInt() * 270 + point.dx.toInt()) * 4;
  return rgba[start] == 255 && rgba[start + 1] == 255 && rgba[start + 2] == 255;
}

Uint8List region(Uint8List rgba, Rect area) => Uint8List.fromList([
  for (var y = area.top.toInt(); y < area.bottom.toInt(); y++)
    for (var x = area.left.toInt(); x < area.right.toInt(); x++)
      for (var channel = 0; channel < 4; channel++)
        rgba[(y * 270 + x) * 4 + channel],
]);

void main() {
  testWidgets('inspection cannot turn an open finger white or move the hand', (
    tester,
  ) async {
    await tester.pumpWidget(fixture('0,0,0,0,0,600'));
    await tester.pumpAndSettle();
    final before = (await tester.runAsync(() => pixels(tester)))!;
    await tester.pumpWidget(fixture('0,0,0,0,0,600', inspected: 2));
    await tester.pumpAndSettle();
    final after = (await tester.runAsync(() => pixels(tester)))!;
    expect(after, equals(before));
    expect(roots.map((point) => whiteAt(after, point)), everyElement(isFalse));
  });

  for (final light in [false, true]) {
    testWidgets(
      'only bent fingers become white in ${light ? 'light' : 'dark'} mode',
      (tester) async {
        const cases = [
          ('60,0,0,0,0,600', 0),
          ('0,60,0,0,0,600', 1),
          ('0,0,60,0,0,600', 2),
          ('0,0,0,60,0,600', 3),
          ('0,0,0,0,60,600', 4),
        ];
        for (final entry in cases) {
          await tester.pumpWidget(
            fixture(entry.$1, inspected: (entry.$2 + 1) % 5, light: light),
          );
          await tester.pumpAndSettle();
          final image = (await tester.runAsync(() => pixels(tester)))!;
          expect(
            [for (var i = 0; i < roots.length; i++) whiteAt(image, roots[i])],
            [for (var i = 0; i < roots.length; i++) i == entry.$2],
          );
          await tester.pumpWidget(fixture('0,0,0,0,0,600', light: light));
          await tester.pump();
          final released = (await tester.runAsync(() => pixels(tester)))!;
          expect(
            roots.map((point) => whiteAt(released, point)),
            everyElement(isFalse),
          );
          await tester.pumpAndSettle();
        }
        await tester.pumpWidget(fixture('0,35,0,50,0,600', light: light));
        await tester.pumpAndSettle();
        final multiple = (await tester.runAsync(() => pixels(tester)))!;
        expect(roots.map((point) => whiteAt(multiple, point)), [
          false,
          true,
          false,
          true,
          false,
        ]);
      },
    );
  }

  testWidgets('stationary packets and grip changes produce no hand animation', (
    tester,
  ) async {
    await tester.pumpWidget(fixture('0,0,0,0,0,400'));
    await tester.pumpAndSettle();
    final still = (await tester.runAsync(() => pixels(tester)))!;
    for (final packet in ['0,0,0,0,0,400', '0,0,0,0,0,800']) {
      await tester.pumpWidget(fixture(packet));
      await tester.pump(const Duration(milliseconds: 60));
      expect((await tester.runAsync(() => pixels(tester)))!, equals(still));
    }
    await tester.pump(const Duration(seconds: 1));
    expect((await tester.runAsync(() => pixels(tester)))!, equals(still));
  });

  testWidgets('moving the thumb leaves all other finger shapes still', (
    tester,
  ) async {
    await tester.pumpWidget(fixture('0,0,0,0,0,600'));
    await tester.pumpAndSettle();
    final open = (await tester.runAsync(() => pixels(tester)))!;
    await tester.pumpWidget(fixture('60,0,0,0,0,600'));
    await tester.pumpAndSettle();
    final bent = (await tester.runAsync(() => pixels(tester)))!;
    expect(bent, isNot(equals(open)));
    expect(
      region(bent, const Rect.fromLTWH(75, 0, 165, 152)),
      equals(region(open, const Rect.fromLTWH(75, 0, 165, 152))),
    );
  });

  testWidgets('a new index reading cannot restart an animating thumb', (
    tester,
  ) async {
    await tester.pumpWidget(fixture('0,0,0,0,0,600'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(fixture('90,0,0,0,0,600'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    await tester.pumpWidget(fixture('90,60,0,0,0,600'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    final moving = (await tester.runAsync(() => pixels(tester)))!;
    await tester.pumpWidget(
      fixture('90,0,0,0,0,600', handKey: const ValueKey('reference')),
    );
    await tester.pumpAndSettle();
    final settled = (await tester.runAsync(() => pixels(tester)))!;
    expect(
      region(moving, const Rect.fromLTWH(0, 145, 78, 140)),
      equals(region(settled, const Rect.fromLTWH(0, 145, 78, 140))),
    );
  });

  testWidgets(
    'signal loss immediately removes bend highlights and stops motion',
    (tester) async {
      await tester.pumpWidget(fixture('0,0,0,0,0,600'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(fixture('60,0,45,0,0,600'));
      await tester.pump(const Duration(milliseconds: 60));
      await tester.pumpWidget(fixture(null, inspected: 2));
      await tester.pump();
      final missing = (await tester.runAsync(() => pixels(tester)))!;
      expect(
        roots.map((point) => whiteAt(missing, point)),
        everyElement(isFalse),
      );
      await tester.pump(const Duration(seconds: 1));
      expect((await tester.runAsync(() => pixels(tester)))!, equals(missing));
    },
  );
}

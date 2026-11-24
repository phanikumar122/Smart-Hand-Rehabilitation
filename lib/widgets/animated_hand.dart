import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/app_strings.dart';

import '../models/sensor_data.dart';

/// Sensor bend changes the projected joint positions; no demo motion is added.
class AnimatedHand extends StatefulWidget {
  const AnimatedHand({
    super.key,
    required this.data,
    required this.selectedFinger,
    required this.onFingerSelected,
  });
  final SensorData? data;
  final int? selectedFinger;
  final ValueChanged<int?> onFingerSelected;
  @override
  State<AnimatedHand> createState() => _AnimatedHandState();
}

class _AnimatedHandState extends State<AnimatedHand>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final Listenable _frames;
  late List<double> _starts;
  late List<double> _targets;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _targets = _HandPose.fromData(widget.data).bends;
    _starts = List.of(_targets);
    _controllers = List.generate(
      5,
      (_) => AnimationController(
        vsync: this,
        value: 1,
        duration: const Duration(milliseconds: 140),
      ),
    );
    _frames = Listenable.merge(_controllers);
  }

  double _value(int finger) =>
      _starts[finger] +
      (_targets[finger] - _starts[finger]) *
          Curves.easeOutCubic.transform(_controllers[finger].value);

  void _snap(List<double> values) {
    _starts = List.of(values);
    _targets = List.of(values);
    for (final controller in _controllers) {
      controller.stop();
      controller.value = 1;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.of(context).disableAnimations;
    if (_reduceMotion) _snap(_targets);
  }

  @override
  void didUpdateWidget(covariant AnimatedHand oldWidget) {
    super.didUpdateWidget(oldWidget);
    final incoming = _HandPose.fromData(widget.data).bends;
    // Missing or first readings set a pose immediately; neither invents motion.
    if (widget.data == null || oldWidget.data == null || _reduceMotion) {
      _snap(incoming);
      return;
    }
    for (var finger = 0; finger < 5; finger++) {
      if (incoming[finger] == _targets[finger]) continue;
      _starts[finger] = _value(finger);
      _targets[finger] = incoming[finger];
      _controllers[finger].forward(from: 0);
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _frames,
      builder: (context, _) => RepaintBoundary(
        key: const ValueKey('hand-canvas'),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest;
            final geometry = _HandGeometry(
              _HandPose([
                for (var finger = 0; finger < 5; finger++) _value(finger),
              ]),
              size,
            );
            return Semantics(
              image: true,
              label: widget.data == null
                  ? context.strings.handNoSignal
                  : widget.selectedFinger == null
                  ? context.strings.handLiveHint
                  : context.strings.handInspected(
                      context.strings.fingerName(widget.selectedFinger!),
                    ),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (details) => widget.onFingerSelected(
                  geometry.fingerAt(details.localPosition),
                ),
                child: CustomPaint(
                  size: size,
                  painter: _ArticulatedHandPainter(
                    geometry: geometry,
                    bentFingers: [
                      for (final bend in _targets)
                        widget.data != null && bend > 0,
                    ],
                    colors: colors,
                    hasSignal: widget.data != null,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HandPose {
  const _HandPose(this.bends);
  factory _HandPose.fromData(SensorData? data) => _HandPose([
    (data?.thumb ?? 0).toDouble(),
    (data?.index ?? 0).toDouble(),
    (data?.middle ?? 0).toDouble(),
    (data?.ring ?? 0).toDouble(),
    (data?.pinky ?? 0).toDouble(),
  ]);
  final List<double> bends;
  @override
  bool operator ==(Object other) =>
      other is _HandPose && listEquals(bends, other.bends);
  @override
  int get hashCode => Object.hashAll(bends);
}

class _HandGeometry {
  _HandGeometry(this.pose, Size size) {
    scale = math.min(size.width / 270, size.height / 350);
    offset = Offset(
      (size.width - 270 * scale) / 2 - 35 * scale,
      (size.height - 350 * scale) / 2 - 60 * scale,
    );
    final thumbFlex = pose.bends[0] / 90;
    final thumb = [const Offset(112, 286)];
    for (var i = 0; i < 2; i++) {
      final direction = -1.05 + thumbFlex * (0.75 + i * 0.5);
      final length = i == 0 ? 46.0 : 32.0;
      thumb.add(
        thumb.last +
            Offset(math.sin(direction) * length, -math.cos(direction) * length),
      );
    }
    joints.add(thumb);
    const bases = [
      Offset(132, 229),
      Offset(173, 218),
      Offset(214, 229),
      Offset(250, 246),
    ];
    const lengths = [
      [55.0, 35.0, 25.0],
      [65.0, 43.0, 28.0],
      [58.0, 38.0, 25.0],
      [42.0, 30.0, 22.0],
    ];
    const fans = [-0.10, 0.0, 0.07, 0.18];
    const inwardCurl = [0.28, 0.12, -0.12, -0.22];
    for (var finger = 0; finger < 4; finger++) {
      final flex = pose.bends[finger + 1] / 90 * 1.5;
      final points = [bases[finger]];
      for (var joint = 0; joint < 3; joint++) {
        final curl = flex * [0.45, 1.05, 1.6][joint];
        points.add(
          points.last +
              Offset(
                (math.sin(fans[finger]) + math.sin(curl) * inwardCurl[finger]) *
                    lengths[finger][joint],
                -math.cos(curl) * lengths[finger][joint],
              ),
        );
      }
      joints.add(points);
    }
    for (var finger = 0; finger < 5; finger++) {
      var shape = Path();
      for (var joint = 0; joint < joints[finger].length - 1; joint++) {
        final radius = (finger == 4 ? 12.0 : 15.0) - joint * 1.5;
        shape = Path.combine(
          PathOperation.union,
          shape,
          capsule(
            joints[finger][joint],
            joints[finger][joint + 1],
            radius,
            radius - 1,
          ),
        );
      }
      fingers.add(shape);
    }
    palm = Path()
      ..moveTo(142, 390)
      ..cubicTo(132, 357, 121, 325, 103, 294)
      ..cubicTo(88, 300, 87, 270, 104, 250)
      ..cubicTo(110, 236, 110, 221, 127, 219)
      ..quadraticBezierTo(154, 212, 176, 209)
      ..quadraticBezierTo(198, 213, 215, 221)
      ..quadraticBezierTo(244, 222, 260, 239)
      ..cubicTo(278, 276, 267, 309, 248, 337)
      ..quadraticBezierTo(230, 365, 222, 390)
      ..close();
  }
  final _HandPose pose;
  late final double scale;
  late final Offset offset;
  late final Path palm;
  final joints = <List<Offset>>[];
  final fingers = <Path>[];
  int? fingerAt(Offset position) {
    final point = (position - offset) / scale;
    for (var i = 4; i >= 0; i--) {
      if (fingers[i].contains(point)) return i;
    }
    return null;
  }

  static Path capsule(Offset start, Offset end, double r1, double r2) {
    final vector = end - start;
    final direction = vector / math.max(vector.distance, 0.001);
    final normal = Offset(-direction.dy, direction.dx);
    final a = start + normal * r1, b = end + normal * r2;
    final c = end - normal * r2, d = start - normal * r1;
    final cap1 = direction * r1 * 1.33, cap2 = direction * r2 * 1.33;
    return Path()
      ..moveTo(a.dx, a.dy)
      ..lineTo(b.dx, b.dy)
      ..cubicTo(
        b.dx + cap2.dx,
        b.dy + cap2.dy,
        c.dx + cap2.dx,
        c.dy + cap2.dy,
        c.dx,
        c.dy,
      )
      ..lineTo(d.dx, d.dy)
      ..cubicTo(
        d.dx - cap1.dx,
        d.dy - cap1.dy,
        a.dx - cap1.dx,
        a.dy - cap1.dy,
        a.dx,
        a.dy,
      )
      ..close();
  }
}

class _ArticulatedHandPainter extends CustomPainter {
  _ArticulatedHandPainter({
    required this.geometry,
    required this.bentFingers,
    required this.colors,
    required this.hasSignal,
  });
  final _HandGeometry geometry;
  final List<bool> bentFingers;
  final ColorScheme colors;
  final bool hasSignal;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(geometry.offset.dx, geometry.offset.dy);
    canvas.scale(geometry.scale);
    canvas.drawPath(
      geometry.palm,
      Paint()..color = colors.surfaceContainerHigh,
    );
    canvas.drawPath(
      geometry.palm,
      Paint()
        ..color = hasSignal ? colors.onSurfaceVariant : colors.outlineVariant
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );
    for (var finger = 0; finger < 5; finger++) {
      canvas.drawPath(
        geometry.fingers[finger],
        Paint()
          ..color = bentFingers[finger]
              ? Colors.white
              : colors.surfaceContainerHigh,
      );
      // Stable digit contours prevent redraw changes on other fingers.
      canvas.save();
      canvas.clipRect(
        Rect.fromLTRB(-100, -100, 460, geometry.joints[finger].first.dy),
      );
      canvas.drawPath(
        geometry.fingers[finger],
        Paint()
          ..color = hasSignal ? colors.onSurfaceVariant : colors.outlineVariant
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8,
      );
      canvas.restore();
    }
    for (var finger = 0; finger < 5; finger++) {
      final points = geometry.joints[finger];
      final ink = bentFingers[finger] ? Colors.black : colors.onSurfaceVariant;
      for (var joint = 1; joint < points.length - 1; joint++) {
        final vector = points[joint] - points[joint - 1];
        final direction = vector / math.max(vector.distance, 0.001);
        final normal = Offset(-direction.dy, direction.dx) * 8;
        canvas.drawLine(
          points[joint] - normal,
          points[joint] + normal,
          Paint()
            ..color = ink.withValues(alpha: 0.4)
            ..strokeWidth = 1.3
            ..strokeCap = StrokeCap.round,
        );
      }
    }
    final crease = Paint()
      ..color = colors.onSurfaceVariant.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(116, 273)
        ..cubicTo(142, 260, 171, 262, 225, 280),
      crease,
    );
    canvas.drawPath(
      Path()
        ..moveTo(129, 303)
        ..cubicTo(157, 290, 192, 294, 236, 303),
      crease,
    );
    canvas.drawPath(
      Path()
        ..moveTo(141, 366)
        ..quadraticBezierTo(181, 358, 228, 366),
      crease,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ArticulatedHandPainter oldDelegate) =>
      oldDelegate.geometry.pose != geometry.pose ||
      !listEquals(oldDelegate.bentFingers, bentFingers) ||
      oldDelegate.colors != colors ||
      oldDelegate.hasSignal != hasSignal;
}

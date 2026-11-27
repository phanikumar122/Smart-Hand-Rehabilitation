class SensorData {
  final int thumb;
  final int index;
  final int middle;
  final int ring;
  final int pinky;
  final int grip;
  final DateTime timestamp;
  static final _decimal = RegExp(r'^[0-9]+$');

  SensorData({
    required this.thumb,
    required this.index,
    required this.middle,
    required this.ring,
    required this.pinky,
    required this.grip,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  static SensorData? fromCsv(String csv, {DateTime? timestamp}) {
    final parts = csv.split(',');
    if (parts.length != 6) return null;
    final values = <int>[];
    for (var i = 0; i < parts.length; i++) {
      final text = parts[i].trim();
      if (!_decimal.hasMatch(text)) return null;
      final value = int.tryParse(text, radix: 10);
      if (value == null || value > (i == 5 ? 1023 : 90)) return null;
      values.add(value);
    }
    return SensorData(
      timestamp: timestamp,
      thumb: values[0],
      index: values[1],
      middle: values[2],
      ring: values[3],
      pinky: values[4],
      grip: values[5],
    );
  }
}

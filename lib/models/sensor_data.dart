class SensorData {
  final int thumb;
  final int index;
  final int middle;
  final int ring;
  final int pinky;
  final int grip;
  final DateTime timestamp;

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
    try {
      final parts = csv.split(',');
      if (parts.length == 6) {
        final values = parts.map((part) => int.tryParse(part.trim())).toList();
        if (values.any((value) => value == null) ||
            values.take(5).any((value) => value! < 0 || value > 90) ||
            values[5]! < 0 ||
            values[5]! > 1023) {
          return null;
        }
        return SensorData(
          timestamp: timestamp,
          thumb: int.parse(parts[0].trim()),
          index: int.parse(parts[1].trim()),
          middle: int.parse(parts[2].trim()),
          ring: int.parse(parts[3].trim()),
          pinky: int.parse(parts[4].trim()),
          grip: int.parse(parts[5].trim()),
        );
      }
    } catch (e) {
      // Ignored
    }
    return null;
  }
}

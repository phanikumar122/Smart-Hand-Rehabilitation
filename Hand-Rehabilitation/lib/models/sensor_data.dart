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

  static SensorData? fromCsv(String csv) {
    try {
      final parts = csv.split(',');
      if (parts.length == 6) {
        return SensorData(
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

  factory SensorData.empty() {
    return SensorData(
      thumb: 0,
      index: 0,
      middle: 0,
      ring: 0,
      pinky: 0,
      grip: 0,
    );
  }
}

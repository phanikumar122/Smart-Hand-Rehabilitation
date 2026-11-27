import 'dart:convert';

class RehabSession {
  final String id;
  final DateTime startTime;
  final Duration duration;
  final int maxGrip;
  final int averageMovement;
  final int readingCount;

  RehabSession({
    required this.id,
    required this.startTime,
    required this.duration,
    required this.maxGrip,
    required this.averageMovement,
    required this.readingCount,
  });

  bool get hasValidMetrics =>
      readingCount > 0 &&
      !duration.isNegative &&
      maxGrip >= 0 &&
      maxGrip <= 1023 &&
      averageMovement >= 0 &&
      averageMovement <= 90;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'duration': duration.inSeconds,
      'maxGrip': maxGrip,
      'averageMovement': averageMovement,
      'readingCount': readingCount,
    };
  }

  factory RehabSession.fromMap(Map<String, dynamic> map) {
    final session = RehabSession(
      id: map['id'],
      startTime: DateTime.parse(map['startTime']),
      duration: Duration(seconds: map['duration']),
      maxGrip: map['maxGrip'],
      averageMovement: map['averageMovement'],
      readingCount: map['readingCount'] ?? 0,
    );
    // Historical summaries without measured readings are not usable records.
    if (!session.hasValidMetrics) {
      throw const FormatException('Invalid rehabilitation session metrics.');
    }
    return session;
  }

  String toJson() => json.encode(toMap());

  factory RehabSession.fromJson(String source) =>
      RehabSession.fromMap(json.decode(source));
}

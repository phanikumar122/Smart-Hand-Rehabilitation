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
    return RehabSession(
      id: map['id'],
      startTime: DateTime.parse(map['startTime']),
      duration: Duration(seconds: map['duration']),
      maxGrip: map['maxGrip'],
      averageMovement: map['averageMovement'],
      readingCount: map['readingCount'] ?? 0,
    );
  }

  String toJson() => json.encode(toMap());

  factory RehabSession.fromJson(String source) =>
      RehabSession.fromMap(json.decode(source));
}

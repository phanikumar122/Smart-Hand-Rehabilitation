import 'package:shared_preferences/shared_preferences.dart';

import '../models/session.dart';

class StorageService {
  static const String _sessionsKey = 'rehab_sessions';

  Future<void> saveSession(RehabSession session) async {
    if (session.readingCount <= 0) {
      throw StateError('Cannot save a session without sensor readings.');
    }
    final prefs = await SharedPreferences.getInstance();
    final List<String> currentSessions =
        prefs.getStringList(_sessionsKey) ?? [];
    currentSessions.add(session.toJson());
    if (!await prefs.setStringList(_sessionsKey, currentSessions)) {
      throw StateError('Session storage failed.');
    }
  }

  Future<List<RehabSession>> getSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> currentSessions =
        prefs.getStringList(_sessionsKey) ?? [];
    final sessions = <RehabSession>[];
    for (final value in currentSessions) {
      try {
        final session = RehabSession.fromJson(value);
        // Older records do not prove that they contained live glove readings.
        if (session.readingCount > 0) sessions.add(session);
      } on FormatException {
        continue;
      } on TypeError {
        continue;
      }
    }
    return sessions;
  }

  Future<void> clearSessions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionsKey);
  }
}

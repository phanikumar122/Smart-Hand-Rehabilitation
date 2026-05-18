import 'package:shared_preferences/shared_preferences.dart';
import '../models/session.dart';

class StorageService {
  static const String _sessionsKey = 'rehab_sessions';

  Future<void> saveSession(RehabSession session) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> currentSessions = prefs.getStringList(_sessionsKey) ?? [];
    currentSessions.add(session.toJson());
    await prefs.setStringList(_sessionsKey, currentSessions);
  }

  Future<List<RehabSession>> getSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> currentSessions = prefs.getStringList(_sessionsKey) ?? [];
    return currentSessions.map((s) => RehabSession.fromJson(s)).toList();
  }

  Future<void> clearSessions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionsKey);
  }
}

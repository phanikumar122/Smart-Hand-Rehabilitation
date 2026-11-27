import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/rehab_session.dart';

class StorageService {
  static const String _sessionsKey = 'rehab_sessions';
  static final _historyRevision = ValueNotifier(0);
  static ValueListenable<int> get historyRevision => _historyRevision;
  static Future<void>? _lastMutation;

  static Future<void> _mutate(Future<void> Function() action) {
    final mutation = _lastMutation?.then((_) => action()) ?? action();
    late final Future<void> settled;
    void clearIfLast() {
      if (identical(_lastMutation, settled)) _lastMutation = null;
    }

    settled = mutation.then(
      (_) => clearIfLast(),
      onError: (Object _, StackTrace _) => clearIfLast(),
    );
    _lastMutation = settled;
    return mutation;
  }

  Future<void> saveSession(RehabSession session) => _mutate(() async {
    if (session.readingCount <= 0) {
      throw StateError('Cannot save a session without sensor readings.');
    }
    if (!session.hasValidMetrics) {
      throw StateError('Session storage failed.');
    }
    final prefs = await SharedPreferences.getInstance();
    final List<String> currentSessions =
        prefs.getStringList(_sessionsKey) ?? [];
    currentSessions.add(session.toJson());
    try {
      if (!await prefs.setStringList(_sessionsKey, currentSessions)) {
        throw StateError('Session storage failed.');
      }
    } catch (_) {
      await prefs.reload();
      rethrow;
    }
    _historyRevision.value++;
  });

  Future<List<RehabSession>> getSessions() async {
    if (_lastMutation case final mutation?) await mutation;
    final prefs = await SharedPreferences.getInstance();
    final List<String> currentSessions =
        prefs.getStringList(_sessionsKey) ?? [];
    final sessions = <RehabSession>[];
    for (final value in currentSessions) {
      try {
        sessions.add(RehabSession.fromJson(value));
      } on FormatException {
        continue;
      } on TypeError {
        continue;
      }
    }
    return sessions;
  }

  Future<void> clearSessions() => _mutate(() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      if (!await prefs.remove(_sessionsKey)) {
        throw StateError('Could not clear history: storage rejected removal.');
      }
    } catch (_) {
      // The legacy preferences API updates its cache before disk acknowledges.
      await prefs.reload();
      rethrow;
    }
    _historyRevision.value++;
  });
}

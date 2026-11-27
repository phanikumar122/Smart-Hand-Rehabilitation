import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_glove_app/models/rehab_session.dart';
import 'package:smart_glove_app/screens/session_history_view.dart';
import 'package:smart_glove_app/services/storage_service.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  // Keep the default method-channel backend for simulated platform failures.
  setUp(SharedPreferences.resetStatic);
  const channel = MethodChannel('plugins.flutter.io/shared_preferences');
  final storage = StorageService();
  final session = RehabSession(
    id: 'fixture',
    startTime: DateTime(2026),
    duration: const Duration(seconds: 3),
    maxGrip: 500,
    averageMovement: 30,
    readingCount: 2,
  );

  tearDown(() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    SharedPreferences.resetStatic();
  });

  test('invalid metrics and legacy records are skipped without losing valid records', () async {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (_) async => {
        'flutter.rehab_sessions': [
          session.toJson(),
          ...{
            'duration': -1,
            'maxGrip': 1024,
            'averageMovement': 91,
            'readingCount': 0,
          }.entries.map(
            (entry) => jsonEncode({...session.toMap(), entry.key: entry.value}),
          ),
          jsonEncode(session.toMap()..remove('readingCount')),
          'not JSON',
        ],
      },
    );
    expect((await storage.getSessions()).map((record) => record.id), [
      'fixture',
    ]);
  });

  test('failed deletion throws and restores the preference cache', () async {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      switch (call.method) {
        case 'getAllWithParameters':
        case 'getAll':
          return {
            'flutter.rehab_sessions': [session.toJson()],
          };
        case 'remove':
          return false;
        default:
          throw MissingPluginException(call.method);
      }
    });
    final revision = StorageService.historyRevision.value;
    await expectLater(storage.clearSessions(), throwsStateError);
    expect(StorageService.historyRevision.value, revision);
    expect((await storage.getSessions()).single.id, session.id);
  });

  testWidgets('history offers a retry after a preferences read failure', (
    tester,
  ) async {
    var fail = true;
    var reads = 0;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (_) async {
      reads++;
      if (fail) throw PlatformException(code: 'unavailable');
      return <String, Object>{};
    });
    await tester.runAsync(() async {
      await tester.pumpWidget(const MaterialApp(home: SessionHistoryView()));
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pump();
    expect(reads, greaterThan(0));
    expect(
      find.text('Could not load session history. Please try again.'),
      findsOneWidget,
    );
    fail = false;
    await tester.runAsync(() async {
      await tester.tap(find.text('Reload history'));
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Reload history'), findsNothing);
    expect(find.text('No sessions saved yet.'), findsOneWidget);
  });
}

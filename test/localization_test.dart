import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_glove_app/l10n/app_locale_controller.dart';
import 'package:smart_glove_app/l10n/app_strings.dart';
import 'package:smart_glove_app/l10n/generated/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('saved language is restored by a fresh controller and device mode clears it', () async {
    final first = AppLocaleController();
    await first.setLocale(const Locale('te'));
    final restored = AppLocaleController();
    await restored.load();
    expect(restored.locale, const Locale('te'));
    await first.setLocale(const Locale('hi', 'IN'));
    await restored.load();
    expect(restored.locale, const Locale('hi'));
    await first.setLocale(null);
    await restored.load();
    expect(restored.locale, isNull);
    first.dispose();
    restored.dispose();
  });

  test('unsupported language cannot overwrite a supported choice', () async {
    final controller = AppLocaleController();
    await controller.setLocale(const Locale('hi'));
    expect(() => controller.setLocale(const Locale('fr')), throwsArgumentError);
    final restored = AppLocaleController();
    await restored.load();
    expect(restored.locale, const Locale('hi'));
    controller.dispose();
    restored.dispose();
  });

  test('rapid language selections persist the final selection', () async {
    final controller = AppLocaleController();
    await Future.wait([
      controller.setLocale(const Locale('te')),
      controller.setLocale(const Locale('hi')),
      controller.setLocale(const Locale('en')),
    ]);
    final restored = AppLocaleController();
    await restored.load();
    expect(restored.locale, const Locale('en'));
    controller.dispose();
    restored.dispose();
  });

  for (final code in ['te', 'hi']) {
    test('runtime errors and safety messages use native $code text', () async {
      final strings = await AppLocalizations.delegate.load(Locale(code));
      for (final source in [
        'Bad state: Glove is disconnected.',
        'Session saved (26 readings).',
        'Finger 3 stopped: vibration time limit reached. Turn it off and wait 2 seconds before rearming.',
        'Manual control expired; all motors stopped.',
        'TimeoutException: Glove did not acknowledge VIB:ALL,1.',
        'Bad state: CAL:INVALID_SPAN',
        'Unexpected platform error',
      ]) {
        final message = localizedMessage(strings, source);
        expect(RegExp('[A-Za-z]').hasMatch(message), isFalse, reason: source);
        expect(message, isNotEmpty);
      }
      expect(
        localizedMessage(strings, 'Session saved (26 readings).'),
        contains('26'),
      );
      expect(
        localizedMessage(strings, 'Finger 3 stopped: timeout'),
        contains(strings.middleFinger),
      );
      expect(
        localizedMessage(strings, 'Bad state: Glove is disconnected.'),
        strings.gloveDisconnected,
      );
    });
  }
}

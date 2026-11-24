import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLocaleController extends ChangeNotifier {
  static final instance = AppLocaleController();
  static const languageCodes = ['en', 'te', 'hi'];
  static const _key = 'app_locale';
  Locale? _locale;
  Locale? get locale => _locale;
  Future<void> _writes = Future.value();

  Future<void> load() async {
    final code = (await SharedPreferences.getInstance()).getString(_key);
    _locale = languageCodes.contains(code) ? Locale(code!) : null;
    notifyListeners();
  }

  Future<void> setLocale(Locale? locale) {
    if (locale != null && !languageCodes.contains(locale.languageCode)) {
      throw ArgumentError.value(locale, 'locale', 'Unsupported app language');
    }
    final next = locale == null ? null : Locale(locale.languageCode);
    final write = _writes.catchError((Object _) {}).then((_) async {
      if (_locale == next) return;
      final prefs = await SharedPreferences.getInstance();
      final saved = next == null
          ? await prefs.remove(_key)
          : await prefs.setString(_key, next.languageCode);
      if (!saved) throw StateError('Could not save the language setting.');
      _locale = next;
      notifyListeners();
    });
    _writes = write;
    return write;
  }
}

class AppLocaleScope extends InheritedNotifier<AppLocaleController> {
  const AppLocaleScope({
    super.key,
    required AppLocaleController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppLocaleController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppLocaleScope>()?.notifier ??
      AppLocaleController.instance;
}

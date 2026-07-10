import 'package:shared_preferences/shared_preferences.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

/// Admin tema modu (kalıcı).
class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController._() : super(ThemeMode.dark);

  static final ThemeController instance = ThemeController._();

  static const String _prefsKey = 'admin_theme_mode';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    value = _fromString(prefs.getString(_prefsKey));
  }

  Future<void> set(ThemeMode mode) async {
    if (value == mode) return;
    value = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, _toString(mode));
  }

  Future<void> toggleDark(bool dark) async {
    await set(dark ? ThemeMode.dark : ThemeMode.light);
  }

  bool get isDark => value == ThemeMode.dark;

  static String _toString(ThemeMode m) {
    switch (m) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  static ThemeMode _fromString(String? v) {
    switch (v) {
      case 'light':
        return ThemeMode.light;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.dark;
    }
  }
}

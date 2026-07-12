import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Uygulama dilini tutan ve kalıcılaştıran singleton.
/// `null` = cihaz sistem dili (desteklenmiyorsa İngilizce).
class LocaleController extends ValueNotifier<Locale?> {
  LocaleController._() : super(null);

  static final LocaleController instance = LocaleController._();

  static const String _prefsKey = 'app_locale';

  static const List<Locale> supported = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  Future<void> load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? stored = prefs.getString(_prefsKey);
    value = _fromTag(stored);
  }

  Future<void> set(Locale? locale) async {
    if (value == locale) return;
    value = locale;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove(_prefsKey);
    } else {
      await prefs.setString(_prefsKey, _toTag(locale));
    }
  }

  static String _toTag(Locale locale) => locale.languageCode;

  static Locale? _fromTag(String? tag) {
    if (tag == null || tag.isEmpty) return null;
    for (final Locale l in supported) {
      if (l.languageCode == tag) return l;
    }
    return null;
  }

  static Locale resolve(Locale? deviceLocale) {
    if (instance.value != null) return instance.value!;
    final String? code = deviceLocale?.languageCode;
    for (final Locale l in supported) {
      if (l.languageCode == code) return l;
    }
    return const Locale('en');
  }
}

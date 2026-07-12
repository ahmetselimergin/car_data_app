import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// İlk açılışta gösterilen karşılama ekranının görülüp görülmediğini tutan
/// singleton. `true` ise karşılama ekranı bir daha gösterilmez.
class OnboardingController extends ValueNotifier<bool> {
  OnboardingController._() : super(false);

  static final OnboardingController instance = OnboardingController._();

  static const String _prefsKey = 'has_seen_welcome';

  bool get hasSeenWelcome => value;

  Future<void> load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    value = prefs.getBool(_prefsKey) ?? false;
  }

  Future<void> markSeen() async {
    if (value) return;
    value = true;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, true);
  }

  /// Login'den Welcome'a geri dönüş için bayrağı temizler.
  Future<void> clearSeen() async {
    if (!value) return;
    value = false;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, false);
  }
}

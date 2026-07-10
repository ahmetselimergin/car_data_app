import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DistanceUnit {
  metric,
  imperial,
}

/// Kilometre / mil gösterim tercihini tutan singleton.
class DistanceUnitController extends ValueNotifier<DistanceUnit> {
  DistanceUnitController._() : super(DistanceUnit.metric);

  static final DistanceUnitController instance = DistanceUnitController._();

  static const String _prefsKey = 'distance_unit';

  Future<void> load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? stored = prefs.getString(_prefsKey);
    value = _fromString(stored);
  }

  Future<void> set(DistanceUnit unit) async {
    if (value == unit) return;
    value = unit;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, _toString(unit));
  }

  static String _toString(DistanceUnit u) =>
      u == DistanceUnit.imperial ? 'imperial' : 'metric';

  static DistanceUnit _fromString(String? v) =>
      v == 'imperial' ? DistanceUnit.imperial : DistanceUnit.metric;
}

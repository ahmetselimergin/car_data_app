import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../services/distance_unit_controller.dart';

class DistanceFormat {
  DistanceFormat._();

  static const double kmPerMile = 1.609344;

  static int kmToMiles(int km) => (km / kmPerMile).round();

  static int milesToKm(int miles) => (miles * kmPerMile).round();

  static DistanceUnit get unit => DistanceUnitController.instance.value;

  static String format(
    int km, {
    required DistanceUnit unit,
    required String localeTag,
    required AppLocalizations l10n,
  }) {
    final NumberFormat nf = NumberFormat.decimalPattern(localeTag);
    if (unit == DistanceUnit.imperial) {
      return '${nf.format(kmToMiles(km))} ${l10n.unitMilesShort}';
    }
    return '${nf.format(km)} ${l10n.unitKmShort}';
  }

  static String fieldLabel(AppLocalizations l10n, DistanceUnit unit) =>
      unit == DistanceUnit.imperial ? l10n.distanceLabelMi : l10n.distanceLabelKm;

  static String fieldHint(AppLocalizations l10n, DistanceUnit unit) =>
      unit == DistanceUnit.imperial ? l10n.distanceHintMi : l10n.distanceHintKm;

  static String fieldRequired(AppLocalizations l10n, DistanceUnit unit) =>
      unit == DistanceUnit.imperial
          ? l10n.distanceRequiredMi
          : l10n.distanceRequiredKm;

  static int parseInput(String raw, DistanceUnit unit) {
    final String digits = raw.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) return 0;
    final int v = int.tryParse(digits) ?? 0;
    return unit == DistanceUnit.imperial ? milesToKm(v) : v;
  }

  static String toInputText(int km, DistanceUnit unit) {
    if (km <= 0) return '';
    final int display = unit == DistanceUnit.imperial ? kmToMiles(km) : km;
    return display.toString();
  }

  /// Birim değişince form alanındaki metni yeni birime çevirir.
  static String convertInputText(
    String raw,
    DistanceUnit from,
    DistanceUnit to,
  ) {
    if (from == to) return raw;
    final int km = parseInput(raw, from);
    return toInputText(km, to);
  }
}

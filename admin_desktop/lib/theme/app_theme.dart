import 'package:shadcn_flutter/shadcn_flutter.dart';

/// Cardex Admin — shadcn zinc teması.
abstract final class AppTheme {
  static ThemeData light() => ThemeData(
        colorScheme: ColorSchemes.lightZinc,
        radius: 0.6,
      );

  static ThemeData dark() => ThemeData(
        colorScheme: ColorSchemes.darkZinc,
        radius: 0.6,
      );

  /// Marka vurgu rengi.
  static Color primaryOf(BuildContext context) =>
      Theme.of(context).colorScheme.primary;

  /// Geriye uyumluluk — Material ekranlar için.
  static Color get primary => ColorSchemes.lightZinc.primary;
}

/// Eski Material token API’sine uyum — shadcn ColorScheme üzerinden.
@immutable
class AdminTokens {
  const AdminTokens(this._scheme);

  final ColorScheme _scheme;

  Color get panel => _scheme.muted;
  Color get panelElevated => _scheme.card;
  Color get rail => _scheme.card;
  Color get hairline => _scheme.border;
  Color get muted => _scheme.mutedForeground;
  Color get signal => _scheme.primary;
  Color get success => _scheme.chart2;
  Color get danger => _scheme.destructive;
  Color get gridLine => _scheme.border.withValues(alpha: 0.35);
}

extension AdminTokensX on BuildContext {
  AdminTokens get tokens => AdminTokens(Theme.of(this).colorScheme);
}

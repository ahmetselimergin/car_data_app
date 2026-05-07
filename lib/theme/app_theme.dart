import 'package:flutter/material.dart';

/// Tema genelinde tutarlı kullanılacak semantic renk tokenları.
/// Hem açık hem koyu temada aynı isimle erişilir.
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.cardBg,
    required this.surfaceMuted,
    required this.border,
    required this.mutedText,
    required this.heroOnPrimary,
    required this.success,
    required this.warning,
    required this.danger,
  });

  /// Kartların arka planı.
  final Color cardBg;

  /// Bottom nav / settings kutucuk gibi hafifçe yüzeyden ayrışan alan.
  final Color surfaceMuted;

  /// İnce çerçeve / divider rengi.
  final Color border;

  /// Yardımcı/alt açıklama yazıları.
  final Color mutedText;

  /// Birincil vurgu yüzeyi üzerindeki metin/ikon rengi.
  final Color heroOnPrimary;

  final Color success;
  final Color warning;
  final Color danger;

  @override
  AppTokens copyWith({
    Color? cardBg,
    Color? surfaceMuted,
    Color? border,
    Color? mutedText,
    Color? heroOnPrimary,
    Color? success,
    Color? warning,
    Color? danger,
  }) {
    return AppTokens(
      cardBg: cardBg ?? this.cardBg,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      border: border ?? this.border,
      mutedText: mutedText ?? this.mutedText,
      heroOnPrimary: heroOnPrimary ?? this.heroOnPrimary,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
    );
  }

  @override
  AppTokens lerp(ThemeExtension<AppTokens>? other, double t) {
    if (other is! AppTokens) return this;
    return AppTokens(
      cardBg: Color.lerp(cardBg, other.cardBg, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      border: Color.lerp(border, other.border, t)!,
      mutedText: Color.lerp(mutedText, other.mutedText, t)!,
      heroOnPrimary: Color.lerp(heroOnPrimary, other.heroOnPrimary, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
    );
  }
}

/// Kısa erişim için helper.
extension AppTokensX on BuildContext {
  AppTokens get tokens => Theme.of(this).extension<AppTokens>()!;
}

class AppTheme {
  AppTheme._();

  /// Ana marka rengi (butonlar, vurgular, garaj kutuları).
  static const Color primary = Color(0xFF1EA971);
  static const Color primaryDark = Color(0xFF168A5C);

  static const Color _ink = Color(0xFF18181B);
  static const Color _bgLight = Color(0xFFF2F2F2);
  static const Color _cardLight = Color(0xFFFFFFFF);
  static const Color _borderLight = Color(0xFFE4E4E7);

  static const Color _bgDark = Color(0xFF1E1E1E);
  static const Color _surfaceDark = Color(0xFF262626);
  static const Color _cardDark = Color(0xFF2A2A2A);
  static const Color _borderDark = Color(0xFF3D3D3D);

  static const AppTokens _lightTokens = AppTokens(
    cardBg: _cardLight,
    surfaceMuted: _cardLight,
    border: _borderLight,
    mutedText: Color(0x9918181B),
    heroOnPrimary: Colors.white,
    success: Color(0xFF26C281),
    warning: Color(0xFFF9A825),
    danger: Color(0xFFE53935),
  );

  static const AppTokens _darkTokens = AppTokens(
    cardBg: _cardDark,
    surfaceMuted: _surfaceDark,
    border: _borderDark,
    mutedText: Color(0xB3A1A1AA),
    heroOnPrimary: Colors.white,
    success: Color(0xFF26C281),
    warning: Color(0xFFF9A825),
    danger: Color(0xFFFF7043),
  );

  static ThemeData get light {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      primary: primary,
      onPrimary: Colors.white,
      surface: _cardLight,
      onSurface: _ink,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: _bgLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: _ink,
        elevation: 0,
        centerTitle: false,
      ),
      textTheme: _textTheme(_ink),
      cardTheme: CardThemeData(
        color: _cardLight,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      inputDecorationTheme: _inputTheme(scheme),
      filledButtonTheme: _filledButtonTheme(),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _cardLight,
        indicatorColor: primary.withValues(alpha: 0.18),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: _ink),
        ),
      ),
      extensions: const <ThemeExtension<dynamic>>[_lightTokens],
    );
  }

  static ThemeData get dark {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
      primary: primary,
      onPrimary: Colors.white,
      surface: _cardDark,
      onSurface: Colors.white,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: _bgDark,
      canvasColor: _bgDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      textTheme: _textTheme(Colors.white),
      cardTheme: CardThemeData(
        color: _cardDark,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      inputDecorationTheme: _inputTheme(scheme, isDark: true),
      filledButtonTheme: _filledButtonTheme(),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _surfaceDark,
        indicatorColor: primary.withValues(alpha: 0.28),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ),
      dividerColor: _borderDark,
      extensions: const <ThemeExtension<dynamic>>[_darkTokens],
    );
  }

  static FilledButtonThemeData _filledButtonTheme() {
    return FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(54),
        textStyle:
            const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32),
        ),
      ),
    );
  }

  static TextTheme _textTheme(Color c) {
    return TextTheme(
      headlineMedium:
          TextStyle(color: c, fontWeight: FontWeight.w800, fontSize: 24),
      titleLarge:
          TextStyle(color: c, fontWeight: FontWeight.w700, fontSize: 20),
      titleMedium:
          TextStyle(color: c, fontWeight: FontWeight.w700, fontSize: 16),
      bodyLarge: TextStyle(color: c, fontSize: 15),
      bodyMedium: TextStyle(color: c, fontSize: 14),
      bodySmall: TextStyle(color: c.withValues(alpha: 0.65), fontSize: 12),
      labelLarge:
          TextStyle(color: c, fontWeight: FontWeight.w700, fontSize: 14),
    );
  }

  static InputDecorationTheme _inputTheme(ColorScheme scheme,
      {bool isDark = false}) {
    return InputDecorationTheme(
      filled: true,
      fillColor: isDark ? _cardDark : _cardLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: isDark ? _borderDark : _borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: isDark ? _borderDark : _borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.primary, width: 1.6),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}

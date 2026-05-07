import 'package:flutter/material.dart';

import '../models/car_model.dart';
import 'app_theme.dart';
import 'car_card_palette.dart';

class GarageCardTheming {
  GarageCardTheming._();

  static Color accentForCar(Car car) =>
      CarCardPalette.resolve(argbValue: car.cardColor, seed: car.id);

  static bool _dark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  /// Üst sol → alt sağ hafif gradient + ince parlama gölgesi (düz tint’ten daha canlı).
  static BoxDecoration garageCardDecoration(
    BuildContext context,
    Color accent, {
    required double borderRadius,
    double borderWidth = 1,
  }) {
    final AppTokens tokens = context.tokens;
    final bool dark = _dark(context);

    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      color: tokens.cardBg,
      border: Border.all(
        color: tintedBorder(context, accent),
        width: borderWidth,
      ),
      boxShadow: <BoxShadow>[
        BoxShadow(
          color: accent.withValues(alpha: dark ? 0.20 : 0.12),
          blurRadius: dark ? 14 : 10,
          spreadRadius: dark ? -1 : 0,
          offset: Offset(0, dark ? 5 : 3),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: dark ? 0.45 : 0.07),
          blurRadius: dark ? 10 : 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  /// Geriye dönük: düz renk istersen (ör. küçük chip’ler).
  static Color tintedCardBg(BuildContext context, Color accent) {
    return context.tokens.cardBg;
  }

  static Color tintedBorder(BuildContext context, Color accent) {
    final AppTokens base = context.tokens;
    final bool dark = _dark(context);
    return Color.lerp(base.border, accent, dark ? 0.62 : 0.48)!;
  }

  /// İkon / çizgi / vurgu: koyu temada accent’e beyaz karıştır (parlar).
  static Color vividForeground(Color accent, BuildContext context) {
    if (_dark(context)) {
      return Color.lerp(accent, Colors.white, 0.52)!;
    }
    return Color.lerp(accent, const Color(0xFF1C1C1E), 0.12)!;
  }

  /// Link ve ikon (biraz nötr sapma ile okunurluk).
  static Color mixedAccent(Color accent) =>
      Color.lerp(AppTheme.primary, accent, 0.88)!;

  static Color iconSoftFill(Color accent) => accent.withValues(alpha: 0.38);

  /// Küçük etiket satırları (Ort. Bakım vb.): muted yerine hafif accent’li açık ton.
  static Color supportiveLabel(BuildContext context, Color accent) {
    if (!_dark(context)) {
      return Color.lerp(Colors.black87, accent, 0.35)!;
    }
    return Color.lerp(Colors.white, accent, 0.22)!.withValues(alpha: 0.88);
  }

  /// Dolu CTA (örn. Hatırlatıcı ekle) — seçili araç accent’i.
  static Color ctaFilledBackground(Color accent) {
    final double lum = accent.computeLuminance();
    if (lum > 0.72) {
      return Color.lerp(accent, Colors.black, 0.30)!;
    }
    if (lum < 0.14) {
      return Color.lerp(accent, Colors.white, 0.26)!;
    }
    return accent;
  }

  static Color ctaOnFilled(Color accent) {
    final Color bg = ctaFilledBackground(accent);
    return bg.computeLuminance() > 0.56 ? const Color(0xFF121212) : Colors.white;
  }

  /// Çerçeveli CTA (örn. Yeni araç) — kenarlık ve yazı.
  static Color ctaOutlinedColor(Color accent, BuildContext context) =>
      vividForeground(accent, context);
}

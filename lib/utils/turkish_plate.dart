import 'package:flutter/services.dart';

/// Türkiye plaka kuralı (boşluksuz normalize):
/// - **İl:** 2 rakam (01–81)
/// - **Harf:** 1–3 harf; **Ç, Ş, İ, Ö, Ü, Ğ** kullanılmaz (yalnızca ASCII A–Z içindeki harfler)
/// - **Sıra no:** harf sayısına göre — 1 harf → tam 4 rakam; 2 harf → 3–4 rakam; 3 harf → 2–3 rakam
class TurkishPlateValidator {
  TurkishPlateValidator._();

  /// İl + harf + rakam (rakam grubu ayrı doğrulanır).
  static final RegExp _structure = RegExp(r'^(\d{2})([A-Z]{1,3})(\d+)$');

  static final RegExp _forbiddenPlateLetters =
      RegExp(r'[ÇŞİÖÜĞçşıöüğı]');

  /// Boşlukları kaldırır, büyük harfe çevirir, Türkçe **İ/ı** → **I** (kayıt için).
  static String normalize(String raw) {
    return raw
        .trim()
        .toUpperCase()
        .replaceAll('İ', 'I')
        .replaceAll('ı', 'I')
        .replaceAll(RegExp(r'\s+'), '');
  }

  static bool _digitsOk(int letterCount, int digitCount) {
    switch (letterCount) {
      case 1:
        return digitCount == 4;
      case 2:
        return digitCount >= 3 && digitCount <= 4;
      case 3:
        return digitCount >= 2 && digitCount <= 3;
      default:
        return false;
    }
  }

  /// [normalize] edilmiş metin için geçerlilik.
  static bool isValidNormalized(String compact) {
    if (_forbiddenPlateLetters.hasMatch(compact)) {
      return false;
    }
    final RegExpMatch? m = _structure.firstMatch(compact);
    if (m == null) return false;
    final int il = int.tryParse(m.group(1)!) ?? 0;
    if (il < 1 || il > 81) return false;
    final String letters = m.group(2)!;
    if (_forbiddenPlateLetters.hasMatch(letters)) return false;
    final String digits = m.group(3)!;
    return _digitsOk(letters.length, digits.length);
  }

  static bool isValid(String raw) => isValidNormalized(normalize(raw));

  /// Kayıtlı sıkışık plakayı `34 ABC 1234` biçiminde gösterir; geçersizse olduğu gibi döner.
  static String formatDisplay(String stored) {
    final String c = normalize(stored);
    if (!isValidNormalized(c)) return stored.trim();
    final RegExpMatch m = _structure.firstMatch(c)!;
    return '${m.group(1)} ${m.group(2)} ${m.group(3)}';
  }

  /// [TextFormField.validator] — geçerliyse `null`.
  static String? formError(String? value) {
    final String v = (value ?? '').trim();
    if (v.isEmpty) return 'Plaka gerekli';
    final String c = normalize(v);
    if (_forbiddenPlateLetters.hasMatch(c)) {
      return 'Plakada Ç, Ş, İ, Ö, Ü, Ğ kullanılmaz; örn. 34 ABC 1234';
    }
    if (!isValid(v)) {
      return 'İl 01-81, harf 1-3 (ÇŞİÖÜĞ yok), rakam: 1 harf→4; 2 harf→3-4; 3 harf→2-3';
    }
    return null;
  }
}

/// Plaka alanı: rakam, ASCII harf, boşluk; Ç/Ş/İ/Ö/Ü/ğ vb. girilmez.
class TurkishPlateInputFormatter extends TextInputFormatter {
  TurkishPlateInputFormatter({this.maxLength = 12});

  final int maxLength;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text.toUpperCase();
    text = text.replaceAll('İ', 'I').replaceAll('ı', 'I');
    text = text.replaceAll(RegExp(r'[^0-9A-Z ]'), '');
    if (text.length > maxLength) {
      text = text.substring(0, maxLength);
    }
    return TextEditingValue(
      text: text,
      selection: _clampedSelection(newValue.selection, text.length),
      composing: TextRange.empty,
    );
  }

  static TextSelection _clampedSelection(TextSelection sel, int len) {
    int base = sel.baseOffset;
    int extent = sel.extentOffset;
    if (base < 0) base = 0;
    if (extent < 0) extent = 0;
    if (base > len) base = len;
    if (extent > len) extent = len;
    return TextSelection(baseOffset: base, extentOffset: extent);
  }
}

import 'package:flutter/material.dart';

/// Araç hero kartının arka planı için sunulan ön tanımlı renk paleti.
/// Modern, yumuşak ama doygun tonlar; karanlık/aydınlık temada da okunaklı.
class CarCardPalette {
  CarCardPalette._();

  /// Sıralama: en sık tercih edilenler önce.
  static const List<Color> colors = <Color>[
    Color(0xFF6E70F2), // indigo (referans tasarım)
    Color(0xFF1F7AE0), // klasik mavi
    Color(0xFF0EA5A5), // teal
    Color(0xFF22A06B), // koyu yeşil
    Color(0xFFE0763D), // turuncu
    Color(0xFFE05D5D), // mercan kırmızı
    Color(0xFFB54AC8), // mor
    Color(0xFF334155), // antrasit
  ];

  /// Verilen [seed] değerine (örn. car.id) göre paletten deterministik bir renk seçer.
  /// Yeni eklenen araçlara çeşitli renkler dağılması için kullanılır.
  static Color autoFor(int? seed) {
    if (seed == null) return colors.first;
    return colors[seed.abs() % colors.length];
  }

  /// [argbValue] DB'den okunan ARGB int değeri ise onu Color'a çevirir,
  /// null ise [seed]'e göre otomatik seçer.
  static Color resolve({required int? argbValue, required int? seed}) {
    if (argbValue != null) return Color(argbValue);
    return autoFor(seed);
  }
}

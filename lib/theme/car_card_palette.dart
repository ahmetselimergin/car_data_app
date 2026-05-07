import 'package:flutter/material.dart';

/// Kahraman kartı için araç başına saklanabilir renk paleti.
class CarCardPalette {
  CarCardPalette._();

  /// Manuel seçim listesi (ilk renk tema birincili ile uyumlu).
  static const List<Color> colors = <Color>[
    Color(0xFF1EA971),
    Color(0xFFE53935),
    Color(0xFF1E88E5),
    Color(0xFFF9A825),
    Color(0xFF8E24AA),
    Color(0xFF3949AB),
    Color(0xFF00897B),
    Color(0xFFD84315),
    Color(0xFF5E35B1),
    Color(0xFF43A047),
  ];

  static Color resolve({int? argbValue, int? seed}) {
    if (argbValue != null) return Color(argbValue);
    return autoFor(seed);
  }

  static Color autoFor(int? seed) {
    final int i = (seed ?? 0).abs() % colors.length;
    return colors[i];
  }
}

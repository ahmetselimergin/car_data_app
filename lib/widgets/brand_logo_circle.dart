import 'package:flutter/material.dart';

import '../data/brand_logo_domains.dart';

String _brandInitial(String marka) {
  final String m = marka.trim();
  if (m.isEmpty) return '?';
  return m.substring(0, 1).toUpperCase();
}

/// Marka için mümkünse Clearbit logosu, yoksa beyaz zemin üzerinde harf.
class BrandLogoCircle extends StatelessWidget {
  const BrandLogoCircle({
    super.key,
    required this.marka,
    required this.size,
    required this.accent,
  });

  final String marka;
  final double size;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final String? domain = BrandLogoDomains.clearbitDomainFor(marka);
    final Widget letter = Text(
      _brandInitial(marka),
      style: TextStyle(
        color: accent,
        fontSize: size * 0.45,
        fontWeight: FontWeight.w800,
        height: 1,
      ),
    );

    return ClipOval(
      child: Container(
        width: size,
        height: size,
        color: Colors.white,
        alignment: Alignment.center,
        child: domain == null
            ? letter
            : Image.network(
                'https://logo.clearbit.com/$domain',
                width: size,
                height: size,
                fit: BoxFit.contain,
                gaplessPlayback: true,
                errorBuilder:
                    (BuildContext context, Object error, StackTrace? st) =>
                        letter,
                loadingBuilder:
                    (BuildContext context, Widget child, ImageChunkEvent? evt) {
                  if (evt == null) return child;
                  return letter;
                },
              ),
      ),
    );
  }
}

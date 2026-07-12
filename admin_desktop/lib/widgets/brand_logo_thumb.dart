import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../data/brand_logo_cdn.dart';
import '../models/models.dart';

/// Marka logosu (CDN PNG) — koyu temada görünürlük için beyaz zemin.
class BrandLogoThumb extends StatelessWidget {
  const BrandLogoThumb({
    super.key,
    required this.brand,
    this.size = 44,
    this.radius = 10,
    this.padding = 6,
    this.fallbackIcon = LucideIcons.tag,
  });

  final Brand? brand;
  final double size;
  final double radius;
  final double padding;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final url = brand == null
        ? null
        : BrandLogoCdn.effectiveUrl(
            slug: brand!.slug,
            stored: brand!.logoUrl,
          );
    final fallback = Icon(
      fallbackIcon,
      size: size * 0.45,
      color: theme.colorScheme.mutedForeground,
    );

    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: url == null
              ? Center(child: fallback)
              : Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => Center(child: fallback),
                ),
        ),
      ),
    );
  }
}

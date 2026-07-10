import 'package:flutter/material.dart';
import 'package:ms_undraw/ms_undraw.dart';

/// Boş durum ekranları için undraw illüstrasyonu + başlık/alt metin.
class UndrawEmptyState extends StatelessWidget {
  const UndrawEmptyState({
    super.key,
    required this.illustration,
    required this.title,
    this.subtitle,
    this.color,
    this.action,
    this.height = 200,
  });

  final UnDrawIllustration illustration;
  final String title;
  final String? subtitle;
  final Color? color;
  final Widget? action;
  final double height;

  @override
  Widget build(BuildContext context) {
    final Color accent =
        color ?? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.82);
    final TextTheme tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            height: height,
            width: double.infinity,
            child: UnDraw(
              illustration: illustration,
              color: accent,
              height: height,
              fit: BoxFit.contain,
              placeholder: Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: accent.withValues(alpha: 0.35),
                  ),
                ),
              ),
              errorWidget: Icon(
                Icons.image_not_supported_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (subtitle != null) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: tt.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
          ],
          if (action != null) ...<Widget>[
            const SizedBox(height: 20),
            action!,
          ],
        ],
      ),
    );
  }
}

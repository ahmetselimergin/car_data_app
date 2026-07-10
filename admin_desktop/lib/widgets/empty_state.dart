import 'package:shadcn_flutter/shadcn_flutter.dart';

/// Boş durum — yerel ikon (ağ / undraw yok).
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.muted,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.colorScheme.border),
            ),
            child: Icon(
              icon,
              size: 36,
              color: theme.colorScheme.mutedForeground,
            ),
          ),
          const Gap(16),
          Text(title).semiBold(),
          if (subtitle != null) ...[
            const Gap(6),
            Text(subtitle!).small().muted(),
          ],
        ],
      ),
    );
  }
}

part of 'package:car_data_app/screens/home_screen.dart';

class _MutedTile extends StatelessWidget {
  const _MutedTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.accent,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  /// Null ise tema varsayılan kart renkleri (garaj dışı kullanım için).
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    final Color? a = accent;
    final Color mix = a != null
        ? GarageCardTheming.vividForeground(a, context)
        : AppTheme.primary;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
      decoration: a != null
          ? GarageCardTheming.garageCardDecoration(
              context,
              a,
              borderRadius: 24,
            )
          : BoxDecoration(
              color: tokens.cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: tokens.border),
            ),
      child: Row(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: a != null
                  ? GarageCardTheming.iconSoftFill(a)
                  : AppTheme.primary.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: mix, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: a != null
                            ? GarageCardTheming.supportiveLabel(context, a)
                            : null,
                        height: 1.35,
                      ),
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

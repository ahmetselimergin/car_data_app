part of 'package:car_data_app/screens/home_screen.dart';

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.log, required this.accent});
  final Maintenance log;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final int days = DateTime.now().difference(log.tarih).inDays;
    final String timeAgo = days == 0
        ? 'Bugün'
        : days < 7
            ? '$days gün önce'
            : days < 30
                ? '${(days / 7).floor()} hafta önce'
                : '${(days / 30).floor()} ay önce';

    final AppTokens tokens = context.tokens;
    final Color vivid = GarageCardTheming.vividForeground(accent, context);
    return Container(
      decoration: GarageCardTheming.garageCardDecoration(
        context,
        accent,
        borderRadius: 18,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: GarageCardTheming.iconSoftFill(accent),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              log.islem.isNotEmpty ? log.islem.characters.first.toUpperCase() : '?',
              style: TextStyle(
                color: vivid,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(log.islem,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  '$timeAgo • ${log.km} km',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color:
                            GarageCardTheming.supportiveLabel(context, accent),
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: vivid,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Icon(Icons.check_circle, color: tokens.success, size: 18),
              const SizedBox(height: 2),
              Text('Güncel',
                  style: TextStyle(
                      color: tokens.success.withValues(alpha: 0.9),
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}

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
      padding: const EdgeInsets.all(14),
      decoration: a != null
          ? GarageCardTheming.garageCardDecoration(
              context,
              a,
              borderRadius: 18,
            )
          : BoxDecoration(
              color: tokens.cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: tokens.border),
            ),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: a != null
                  ? GarageCardTheming.iconSoftFill(a)
                  : AppTheme.primary.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: mix, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: a != null
                            ? GarageCardTheming.supportiveLabel(context, a)
                            : null,
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

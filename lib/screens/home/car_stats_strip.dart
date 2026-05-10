part of 'package:car_data_app/screens/home_screen.dart';

class _CarStatsStrip extends StatelessWidget {
  const _CarStatsStrip({
    required this.car,
    required this.logs,
    required this.accent,
  });
  final Car car;
  final List<Maintenance> logs;
  final Color accent;

  String get _avgCostText {
    if (logs.isEmpty) return '—';
    final double avg = logs
            .map((Maintenance e) => e.maliyet)
            .reduce((double a, double b) => a + b) /
        logs.length;
    return NumberFormat.compactCurrency(
            locale: 'tr_TR', symbol: '₺', decimalDigits: 0)
        .format(avg);
  }

  String get _lastServiceText {
    if (logs.isEmpty) return '—';
    final DateTime last = logs
        .map((Maintenance e) => e.tarih)
        .reduce((DateTime a, DateTime b) => a.isAfter(b) ? a : b);
    final int days = DateTime.now().difference(last).inDays;
    if (days == 0) return 'Bugün';
    if (days < 30) return '$days gün';
    if (days < 365) return '${(days / 30).floor()} ay';
    return '${(days / 365).floor()} yıl';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _StatTile(
            icon: Icons.payments_outlined,
            label: 'Bakım Maliyeti',
            value: _avgCostText,
            accent: accent,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            icon: Icons.schedule_outlined,
            label: 'Son Servis',
            value: _lastServiceText,
            accent: accent,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            icon: Icons.build_outlined,
            label: 'Toplam',
            value: '${logs.length}',
            accent: accent,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final Color vivid = GarageCardTheming.vividForeground(accent, context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: GarageCardTheming.garageCardDecoration(
        context,
        accent,
        borderRadius: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: vivid, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.96)
                  : null,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: GarageCardTheming.supportiveLabel(context, accent),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DotsIndicator extends StatelessWidget {
  const _DotsIndicator({
    required this.count,
    required this.current,
    required this.accent,
  });
  final int count;
  final int current;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final Color base = GarageCardTheming.vividForeground(accent, context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(count, (int i) {
        final bool active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 20 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active ? base : base.withValues(alpha: 0.28),
            borderRadius: BorderRadius.circular(6),
            boxShadow: active
                ? <BoxShadow>[
                    BoxShadow(
                      color: accent.withValues(alpha: 0.45),
                      blurRadius: 8,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }
}

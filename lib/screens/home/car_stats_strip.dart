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

  ({String text, bool isPlaceholder}) _avgCost(String localeTag) {
    final NumberFormat currencyFormat = NumberFormat.currency(
      locale: localeTag,
      symbol: '₺',
      decimalDigits: 0,
    );
    if (logs.isEmpty) {
      return (text: currencyFormat.format(0), isPlaceholder: true);
    }
    final double avg = logs
            .map((Maintenance e) => e.maliyet)
            .reduce((double a, double b) => a + b) /
        logs.length;
    return (
      text: NumberFormat.compactCurrency(
        locale: localeTag,
        symbol: '₺',
        decimalDigits: 0,
      ).format(avg),
      isPlaceholder: false,
    );
  }

  ({String text, bool isPlaceholder}) _lastService(AppLocalizations l10n) {
    if (logs.isEmpty) {
      return (text: '—', isPlaceholder: true);
    }
    final DateTime last = logs
        .map((Maintenance e) => e.tarih)
        .reduce((DateTime a, DateTime b) => a.isAfter(b) ? a : b);
    final int days = DateTime.now().difference(last).inDays;
    if (days == 0) return (text: l10n.today, isPlaceholder: false);
    if (days < 30) return (text: l10n.daysCount(days), isPlaceholder: false);
    if (days < 365) {
      return (
        text: l10n.monthsCount((days / 30).floor()),
        isPlaceholder: false,
      );
    }
    return (
      text: l10n.yearsCount((days / 365).floor()),
      isPlaceholder: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final String localeTag =
        localeTagFor(Localizations.localeOf(context));
    final ({String text, bool isPlaceholder}) cost = _avgCost(localeTag);
    final ({String text, bool isPlaceholder}) lastService = _lastService(l10n);
    final bool totalEmpty = logs.isEmpty;

    return Row(
      children: <Widget>[
        Expanded(
          child: _StatTile(
            icon: Icons.payments_outlined,
            label: l10n.statMaintenanceCost,
            value: cost.text,
            isPlaceholder: cost.isPlaceholder,
            accent: accent,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            icon: Icons.schedule_outlined,
            label: l10n.statLastService,
            value: lastService.text,
            isPlaceholder: lastService.isPlaceholder,
            accent: accent,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            icon: Icons.build_outlined,
            label: l10n.statTotal,
            value: '${logs.length}',
            isPlaceholder: totalEmpty,
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
    required this.isPlaceholder,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isPlaceholder;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final Color vivid = GarageCardTheming.vividForeground(accent, context);
    final Color valueColor = isPlaceholder
        ? vivid.withValues(alpha: dark ? 0.38 : 0.42)
        : dark
            ? Colors.white.withValues(alpha: 0.96)
            : Theme.of(context).colorScheme.onSurface;
    final Color iconColor =
        isPlaceholder ? vivid.withValues(alpha: 0.55) : vivid;

    return Container(
      constraints: const BoxConstraints(minHeight: 96),
      padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
      decoration: GarageCardTheming.garageCardDecoration(
        context,
        accent,
        borderRadius: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Icon(icon, color: iconColor, size: 22),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 22,
              height: 1.1,
              letterSpacing: -0.3,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: GarageCardTheming.supportiveLabel(context, accent),
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              height: 1.2,
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

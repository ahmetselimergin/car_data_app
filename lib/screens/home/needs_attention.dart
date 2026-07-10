part of 'package:car_data_app/screens/home_screen.dart';

class _NeedsAttentionList extends StatelessWidget {
  const _NeedsAttentionList({
    required this.car,
    required this.reminders,
    required this.accent,
  });

  final Car car;
  final List<Reminder> reminders;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    if (reminders.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: _MutedTile(
          icon: Icons.check_circle_outline,
          title: l10n.allUpToDate,
          subtitle: l10n.noUpcomingReminders,
          accent: accent,
          trailing: TextButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ReminderScreen(car: car),
                ),
              );
            },
            icon: Icon(
                Icons.add,
                color: GarageCardTheming.vividForeground(accent, context)),
            label: Text(
              l10n.add,
              style: TextStyle(
                color: GarageCardTheming.vividForeground(accent, context),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: reminders.length,
        separatorBuilder: (BuildContext _, int _) =>
            const SizedBox(width: 12),
        itemBuilder: (BuildContext c, int i) {
          return _AttentionCard(
            reminder: reminders[i],
            car: car,
            accent: accent,
          );
        },
      ),
    );
  }
}

class _AttentionCard extends StatelessWidget {
  const _AttentionCard({
    required this.reminder,
    required this.car,
    required this.accent,
  });
  final Reminder reminder;
  final Car car;
  final Color accent;

  IconData get _icon {
    switch (reminder.tur) {
      case ReminderType.sigorta:
        return Icons.shield_outlined;
      case ReminderType.kasko:
        return Icons.security_outlined;
      case ReminderType.muayene:
        return Icons.fact_check_outlined;
      case ReminderType.egzoz:
        return Icons.air;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ReminderStatus status = DateHelper.statusFor(reminder.bitisTarihi);
    final int days = DateHelper.daysUntil(reminder.bitisTarihi);
    final Color statusColor = DateHelper.colorFor(status);
    final bool highlighted = status == ReminderStatus.critical ||
        status == ReminderStatus.expired;
    final Color vivid = GarageCardTheming.vividForeground(accent, context);

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ReminderScreen(car: car),
          ),
        );
      },
      child: Container(
        width: 128,
        padding: const EdgeInsets.all(14),
        decoration: GarageCardTheming.garageCardDecoration(
          context,
          accent,
          borderRadius: 22,
          borderWidth: highlighted ? 1.75 : 1,
        ).copyWith(
          border: Border.all(
            color: highlighted
                ? vivid
                : GarageCardTheming.tintedBorder(context, accent),
            width: highlighted ? 1.75 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              reminder.tur.localizedLabel(l10n),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: GarageCardTheming.iconSoftFill(accent),
                shape: BoxShape.circle,
              ),
              child: Icon(_icon, color: vivid, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              days < 0 ? l10n.expired : l10n.remainingUntilExpiry,
              style: TextStyle(
                fontSize: 11,
                color: days < 0
                    ? statusColor
                    : GarageCardTheming.supportiveLabel(context, accent),
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              days < 0 ? l10n.daysAgo(days.abs()) : l10n.daysCount(days),
              style: TextStyle(
                color: highlighted
                    ? statusColor
                    : Theme.of(context).textTheme.titleMedium?.color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

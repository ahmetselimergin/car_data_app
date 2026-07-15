part of 'package:car_data_app/screens/home_screen.dart';

class _NeedsAttentionList extends StatelessWidget {
  const _NeedsAttentionList({
    required this.car,
    required this.reminders,
    required this.accent,
    required this.onRefresh,
  });

  final Car car;
  final List<Reminder> reminders;
  final Color accent;
  final Future<void> Function() onRefresh;

  Future<void> _openReminders(BuildContext context) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ReminderScreen(car: car),
      ),
    );
    await onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    if (reminders.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(32),
            onTap: () => _openReminders(context),
            child: Ink(
              height: 118,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    Image.asset(
                      'assets/images/reminders_hero.jpg',
                      fit: BoxFit.cover,
                      alignment: const Alignment(0.55, 0),
                      errorBuilder: (_, _, _) => const ColoredBox(
                        color: Color(0xFFE8ECF0),
                      ),
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: <Color>[
                            Color(0xFFF4F5F7),
                            Color(0xFFF4F5F7),
                            Color(0xCCF4F5F7),
                            Color(0x66F4F5F7),
                            Color(0x00F4F5F7),
                          ],
                          stops: <double>[
                            0.0,
                            0.28,
                            0.48,
                            0.72,
                            1.0,
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 18, 18, 18),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 200),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Text(
                                l10n.allUpToDate,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      height: 1.15,
                                      letterSpacing: -0.3,
                                      color: const Color(0xFF1A2332),
                                    ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                l10n.noUpcomingReminders,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      height: 1.35,
                                      color: const Color(0xFF6B7585),
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final bool canAddMore =
        reminders.map((Reminder r) => r.tur).toSet().length <
            ReminderType.values.length;

    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: reminders.length + (canAddMore ? 1 : 0),
        separatorBuilder: (BuildContext _, int _) =>
            const SizedBox(width: 12),
        itemBuilder: (BuildContext c, int i) {
          if (i == reminders.length) {
            return _AddReminderCard(
              accent: accent,
              onTap: () => _openReminders(context),
            );
          }
          return _AttentionCard(
            reminder: reminders[i],
            car: car,
            accent: accent,
            onRefresh: onRefresh,
          );
        },
      ),
    );
  }
}

class _AddReminderCard extends StatelessWidget {
  const _AddReminderCard({
    required this.accent,
    required this.onTap,
  });

  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final Color vivid = GarageCardTheming.vividForeground(accent, context);

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        width: 128,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: GarageCardTheming.iconSoftFill(accent),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: GarageCardTheming.tintedBorder(context, accent),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add_rounded, color: vivid, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.addNew,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: vivid,
                fontWeight: FontWeight.w800,
                fontSize: 14,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttentionCard extends StatelessWidget {
  const _AttentionCard({
    required this.reminder,
    required this.car,
    required this.accent,
    required this.onRefresh,
  });
  final Reminder reminder;
  final Car car;
  final Color accent;
  final Future<void> Function() onRefresh;

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
      case ReminderType.bakimKm:
        return Icons.speed_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ReminderStatus status = DateHelper.statusForReminder(
      reminder,
      currentKm: car.km,
    );
    final Color statusColor = DateHelper.colorFor(status);
    final bool highlighted = status == ReminderStatus.critical ||
        status == ReminderStatus.expired;
    final Color vivid = GarageCardTheming.vividForeground(accent, context);
    final bool kmBased = reminder.isKmBased;
    final int? kmLeft = DateHelper.kmRemaining(reminder, car.km);
    final int? days =
        reminder.bitisTarihi == null
            ? null
            : DateHelper.daysUntil(reminder.bitisTarihi!);

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () async {
        await Navigator.of(context).push<bool>(
          MaterialPageRoute<bool>(
            builder: (_) => ReminderScreen(car: car),
          ),
        );
        await onRefresh();
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
              kmBased
                  ? ((kmLeft ?? 0) <= 0
                      ? l10n.expired
                      : l10n.remainingUntilExpiry)
                  : ((days ?? 0) < 0
                      ? l10n.expired
                      : l10n.remainingUntilExpiry),
              style: TextStyle(
                fontSize: 11,
                color: (kmBased ? (kmLeft ?? 0) <= 0 : (days ?? 0) < 0)
                    ? statusColor
                    : GarageCardTheming.supportiveLabel(context, accent),
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              kmBased
                  ? ((kmLeft ?? 0) <= 0
                      ? l10n.kmOverdueCount((kmLeft ?? 0).abs())
                      : l10n.kmRemainingCount(kmLeft ?? 0))
                  : ((days ?? 0) < 0
                      ? l10n.daysAgo(days!.abs())
                      : l10n.daysCount(days ?? 0)),
              style: TextStyle(
                color: highlighted
                    ? statusColor
                    : Theme.of(context).textTheme.titleMedium?.color,
                fontWeight: FontWeight.w800,
                fontSize: kmBased ? 12 : null,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

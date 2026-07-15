part of 'package:car_data_app/screens/home_screen.dart';

class _AllRemindersTab extends StatelessWidget {
  const _AllRemindersTab({
    required this.future,
    required this.cachedGarage,
    required this.onGoToGarage,
    required this.onRefresh,
  });
  final Future<_GarageData> future;
  final _GarageData? cachedGarage;
  final VoidCallback onGoToGarage;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_GarageData>(
      future: future,
      builder: (BuildContext context, AsyncSnapshot<_GarageData> snap) {
        final _GarageData? effective = snap.data ?? cachedGarage;
        final bool waitingFirstLoad =
            snap.connectionState != ConnectionState.done && effective == null;
        if (waitingFirstLoad) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError && effective == null) {
          return LoadErrorView(onRetry: onRefresh);
        }
        final _GarageData data = effective!;
        final List<Reminder> reminders = List<Reminder>.of(data.reminders)
          ..sort((Reminder a, Reminder b) {
            final DateTime? da = a.bitisTarihi;
            final DateTime? db = b.bitisTarihi;
            if (da == null && db == null) {
              final int ka = a.targetKm ?? 1 << 30;
              final int kb = b.targetKm ?? 1 << 30;
              return ka.compareTo(kb);
            }
            if (da == null) return 1;
            if (db == null) return -1;
            return da.compareTo(db);
          });

        return Column(
          children: <Widget>[
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(context.l10n.remindersTitle,
                        style: Theme.of(context).textTheme.headlineMedium),
                  ),
                ],
              ),
            ),
            Expanded(
              child: reminders.isEmpty
                  ? Center(
                      child: UndrawEmptyState(
                        illustration: UnDrawIllustration.calendar,
                        title: context.l10n.remindersEmptyTitle,
                        subtitle: context.l10n.allRemindersEmpty,
                        height: 190,
                        action: FilledButton.icon(
                          onPressed: onGoToGarage,
                          icon: const Icon(Icons.directions_car_outlined),
                          label: Text(context.l10n.goToGarage),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      itemCount: reminders.length,
                      separatorBuilder: (BuildContext _, int _) =>
                          const SizedBox(height: 10),
                      itemBuilder: (BuildContext c, int i) {
                        final Reminder r = reminders[i];
                        final Car car = data.cars.firstWhere(
                          (Car x) => x.id == r.carId,
                          orElse: () => const Car(
                            plaka: '—',
                            marka: '?',
                            model: '',
                            yil: 0,
                            km: 0,
                          ),
                        );
                        return _ReminderFlatTile(reminder: r, car: car);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _ReminderFlatTile extends StatelessWidget {
  const _ReminderFlatTile({required this.reminder, required this.car});
  final Reminder reminder;
  final Car car;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final String localeTag =
        localeTagFor(Localizations.localeOf(context));
    final ReminderStatus status = DateHelper.statusForReminder(
      reminder,
      currentKm: car.km,
    );
    final Color color = DateHelper.colorFor(status);
    return Container(
      decoration: BoxDecoration(
        color: context.tokens.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.tokens.border),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(DateHelper.iconFor(status), color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('${reminder.tur.localizedLabel(l10n)} • ${car.plaka}',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  humanizeReminder(
                    reminder,
                    l10n,
                    currentKm: car.km,
                    localeTag: localeTag,
                  ),
                  style: TextStyle(color: color, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

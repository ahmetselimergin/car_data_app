part of 'package:car_data_app/screens/home_screen.dart';

class _DashboardTab extends StatelessWidget {
  const _DashboardTab({
    required this.future,
    required this.cachedGarage,
    required this.pageController,
    required this.currentCar,
    required this.onCarChanged,
    required this.onAddCar,
    required this.onEditCar,
    required this.onRefresh,
  });

  final Future<_GarageData> future;
  final _GarageData? cachedGarage;
  final PageController pageController;
  final int currentCar;
  final ValueChanged<int> onCarChanged;
  final VoidCallback onAddCar;
  final ValueChanged<Car> onEditCar;
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
          return Center(
              child: Text(context.l10n.genericError(snap.error.toString())));
        }
        final _GarageData data = effective!;

        if (data.cars.isEmpty) {
          return _EmptyGarage(onAddCar: onAddCar);
        }

        final int idx =
            currentCar.clamp(0, data.cars.length - 1);
        final Car car = data.cars[idx];
        final List<Reminder> reminders = data.remindersOf(car.id!);
        final List<Maintenance> logs = data.maintenanceOf(car.id!);
        final Color garageAccent = GarageCardTheming.accentForCar(car);
        final Color ctaOutline =
            GarageCardTheming.ctaOutlinedColor(garageAccent, context);

        return RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            children: <Widget>[
              // Car card (swipeable)
              SizedBox(
                height: 300,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    PageView.builder(
                      controller: pageController,
                      itemCount: data.cars.length,
                      onPageChanged: onCarChanged,
                      clipBehavior: Clip.none,
                      itemBuilder: (BuildContext c, int i) {
                        final Car car = data.cars[i];
                        return _CarHeaderCard(
                          car: car,
                          logs: data.maintenanceOf(car.id!),
                          onEdit: () => onEditCar(car),
                        );
                      },
                    ),
                    if (data.cars.length > 1)
                      Positioned(
                        bottom: 2,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: _DotsIndicator(
                            count: data.cars.length,
                            current: idx,
                            accent: garageAccent,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // Compact stats below the hero card.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _CarStatsStrip(
                  car: car,
                  logs: logs,
                  accent: garageAccent,
                ),
              ),
              const SizedBox(height: 22),

              // Dikkat gereken hatırlatmalar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(context.l10n.needsAttention,
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              const SizedBox(height: 10),
              _NeedsAttentionList(
                car: car,
                reminders: reminders,
                accent: garageAccent,
              ),

              const SizedBox(height: 24),

              // Bakım geçmişi
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(context.l10n.maintenanceHistory,
                          style: Theme.of(context).textTheme.titleMedium),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => MaintenanceScreen(car: car),
                          ),
                        );
                      },
                      child: Row(
                        children: <Widget>[
                          Text(context.l10n.seeAll,
                              style: TextStyle(
                                  color: GarageCardTheming.vividForeground(
                                      garageAccent, context),
                                  fontWeight: FontWeight.w700)),
                          Icon(Icons.chevron_right,
                              color: GarageCardTheming.vividForeground(
                                  garageAccent, context),
                              size: 18),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              if (logs.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _MutedTile(
                    icon: Icons.build_outlined,
                    title: context.l10n.noMaintenanceYet,
                    subtitle: context.l10n.noMaintenanceHint,
                    accent: garageAccent,
                  ),
                ),
              ...logs.take(3).map(
                    (Maintenance m) =>
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                          child: _HistoryTile(
                            log: m,
                            accent: garageAccent,
                          ),
                        ),
                  ),

              const SizedBox(height: 18),

              // CTA (seçili araç rengine bağlı — nötr gri yerine canlı accent)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        GarageCardTheming.ctaFilledBackground(garageAccent),
                    foregroundColor:
                        GarageCardTheming.ctaOnFilled(garageAccent),
                    minimumSize: const Size.fromHeight(54),
                    elevation: 2,
                    shadowColor: garageAccent.withValues(alpha: 0.42),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                  ),
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ReminderScreen(car: car),
                      ),
                    );
                    await onRefresh();
                  },
                  icon: const Icon(Icons.notification_add_outlined),
                  label: Text(
                    context.l10n.addReminder,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),

              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: OutlinedButton.icon(
                  onPressed: onAddCar,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                    foregroundColor: ctaOutline,
                    side: BorderSide(
                      color: ctaOutline.withValues(alpha: 0.92),
                      width: 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                  ),
                  icon: Icon(Icons.add, color: ctaOutline),
                  label: Text(
                    context.l10n.newCar,
                    style: TextStyle(
                      color: ctaOutline,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),
            ],
          ),
        );
      },
    );
  }
}

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
          return LoadErrorView(onRetry: onRefresh);
        }
        final _GarageData data = effective!;

        if (data.cars.isEmpty) {
          return _EmptyGarage(onAddCar: onAddCar);
        }

        final int idx =
            currentCar.clamp(0, data.cars.length - 1);
        final Car car = data.cars[idx];
        final List<Reminder> reminders = data.remindersOf(car.id!);
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
              const SizedBox(height: 22),

              // Dikkat gereken hatırlatmalar — sadece liste varken başlık
              if (reminders.isNotEmpty) ...<Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(context.l10n.needsAttention,
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                const SizedBox(height: 10),
              ],
              _NeedsAttentionList(
                car: car,
                reminders: reminders,
                accent: garageAccent,
                onRefresh: onRefresh,
              ),

              const SizedBox(height: 20),

              // Bakım geçmişi — sol metin, sağa motor fotoğrafı + yumuşak fade
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(32),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => MaintenanceScreen(car: car),
                        ),
                      );
                    },
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
                              'assets/images/maintenance_hero.jpg',
                              fit: BoxFit.cover,
                              alignment: const Alignment(0.65, 0),
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
                              padding:
                                  const EdgeInsets.fromLTRB(22, 18, 18, 18),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 200),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: <Widget>[
                                      Text(
                                        context.l10n.maintenanceHistory,
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
                                        context
                                            .l10n.maintenanceHistorySubtitle,
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
              ),

              const SizedBox(height: 14),

              // En Yakın Tamirci — harita ekranına götüren şık kart-buton
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: _NearestMechanicCard(),
              ),

              const SizedBox(height: 14),

              // AI Destek Asistanı — sohbet ekranını açan kart-buton
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: _SupportChatCard(),
              ),

              const SizedBox(height: 18),

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

/// Ana ekranda "En Yakın Tamirci" harita ekranını açan şık kart-buton.
class _NearestMechanicCard extends StatelessWidget {
  const _NearestMechanicCard();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(32),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const NearestMechanicScreen(),
            ),
          );
        },
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[Color(0xFFF5731F), Color(0xFFDE3B0C)],
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: const Color(0xFFDE3B0C).withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: <Widget>[
              // Dekoratif harita halkaları (sağ üst)
              Positioned(
                right: -26,
                top: -26,
                child: _ring(120, 0.10),
              ),
              Positioned(
                right: 18,
                top: 20,
                child: _ring(64, 0.14),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 18, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Image.asset(
                        'assets/images/eurorepar-logo.png',
                        height: 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'En Yakın Servis',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(Icons.format_list_bulleted,
                              color: Colors.white, size: 15),
                          SizedBox(width: 6),
                          Text(
                            'Servisleri Gör',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ring(double size, double alpha) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: alpha),
          width: 2,
        ),
      ),
    );
  }
}

/// Ana ekranda AI destek sohbetini açan kart-buton.
class _SupportChatCard extends StatelessWidget {
  const _SupportChatCard();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const SupportChatScreen(),
            ),
          );
        },
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[Color(0xFF2563EB), Color(0xFF1E3A8A)],
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: const Color(0xFF1E3A8A).withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 18, 18),
            child: Row(
              children: const <Widget>[
                Icon(
                  Icons.support_agent,
                  color: Colors.white,
                  size: 34,
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        'AI Destek Asistanı',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Uygulama yardımı ve araç arıza triyajı',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.white70,
                ),
              ],
            ),
          ),
        ),
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

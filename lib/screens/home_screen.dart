import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/car_model.dart';
import '../models/maintenance_model.dart';
import '../models/reminder_model.dart';
import '../repositories/car_repository.dart';
import '../repositories/maintenance_repository.dart';
import '../repositories/reminder_repository.dart';
import '../services/date_helper.dart';
import '../theme/app_theme.dart';
import '../theme/car_card_palette.dart';
import '../theme/theme_controller.dart';
import 'add_car_screen.dart';
import 'maintenance_screen.dart';
import 'reminder_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;

  final CarRepository _carRepo = SqliteCarRepository();
  final ReminderRepository _reminderRepo = SqliteReminderRepository();
  final MaintenanceRepository _mRepo = SqliteMaintenanceRepository();

  late Future<_GarageData> _future;
  final PageController _pageController = PageController(viewportFraction: 1);
  int _currentCar = 0;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<_GarageData> _load() async {
    final List<Car> cars = await _carRepo.getCars();
    final List<Reminder> reminders = await _reminderRepo.getAllReminders();
    final Map<int, List<Maintenance>> maintenance = <int, List<Maintenance>>{};
    for (final Car c in cars) {
      if (c.id != null) {
        maintenance[c.id!] = await _mRepo.getMaintenanceByCarId(c.id!);
      }
    }
    return _GarageData(
      cars: cars,
      reminders: reminders,
      maintenance: maintenance,
    );
  }

  void _refresh() {
    if (!mounted) return;
    setState(() {
      _future = _load();
    });
  }

  Future<void> _openAddCar({Car? existing}) async {
    final bool? ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AddCarScreen(existing: existing),
      ),
    );
    if (ok ?? false) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = <Widget>[
      _DashboardTab(
        future: _future,
        pageController: _pageController,
        onCarChanged: (int i) => setState(() => _currentCar = i),
        currentCar: _currentCar,
        onAddCar: () => _openAddCar(),
        onEditCar: (Car c) => _openAddCar(existing: c),
        onRefresh: _refresh,
      ),
      _AllRemindersTab(future: _future),
      const _SettingsTab(),
    ];

    return Scaffold(
      body: SafeArea(child: pages[_navIndex]),
      bottomNavigationBar: _BottomNav(
        index: _navIndex,
        onTap: (int i) => setState(() => _navIndex = i),
      ),
    );
  }
}

// ============ DATA ============

class _GarageData {
  _GarageData({
    required this.cars,
    required this.reminders,
    required this.maintenance,
  });

  final List<Car> cars;
  final List<Reminder> reminders;
  final Map<int, List<Maintenance>> maintenance;

  List<Reminder> remindersOf(int carId) =>
      reminders.where((Reminder r) => r.carId == carId).toList()
        ..sort((Reminder a, Reminder b) =>
            a.bitisTarihi.compareTo(b.bitisTarihi));

  List<Maintenance> maintenanceOf(int carId) =>
      maintenance[carId] ?? <Maintenance>[];
}

// ============ DASHBOARD TAB ============

class _DashboardTab extends StatelessWidget {
  const _DashboardTab({
    required this.future,
    required this.pageController,
    required this.currentCar,
    required this.onCarChanged,
    required this.onAddCar,
    required this.onEditCar,
    required this.onRefresh,
  });

  final Future<_GarageData> future;
  final PageController pageController;
  final int currentCar;
  final ValueChanged<int> onCarChanged;
  final VoidCallback onAddCar;
  final ValueChanged<Car> onEditCar;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_GarageData>(
      future: future,
      builder: (BuildContext context, AsyncSnapshot<_GarageData> snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Hata: ${snap.error}'));
        }
        final _GarageData data = snap.data!;

        if (data.cars.isEmpty) {
          return _EmptyGarage(onAddCar: onAddCar);
        }

        final int idx =
            currentCar.clamp(0, data.cars.length - 1);
        final Car car = data.cars[idx];
        final List<Reminder> reminders = data.remindersOf(car.id!);
        final List<Maintenance> logs = data.maintenanceOf(car.id!);

        return RefreshIndicator(
          onRefresh: () async => onRefresh(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            children: <Widget>[
              // Car card (swipeable)
              SizedBox(
                height: 320,
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
                        bottom: 4,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: _DotsIndicator(
                            count: data.cars.length,
                            current: idx,
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
                child: _CarStatsStrip(car: car, logs: logs),
              ),
              const SizedBox(height: 22),

              // Needs attention
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text('Needs Attention',
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              const SizedBox(height: 10),
              _NeedsAttentionList(car: car, reminders: reminders),

              const SizedBox(height: 24),

              // Service history
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text('Service History',
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
                          Text('View all',
                              style: TextStyle(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w700)),
                          const Icon(Icons.chevron_right,
                              color: AppTheme.primary, size: 18),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              if (logs.isEmpty)
                const _MutedTile(
                    icon: Icons.build_outlined,
                    title: 'Henüz bakım kaydı yok',
                    subtitle: 'Yağ değişimi, lastik vb. eklemek için + tuşu'),
              ...logs.take(3).map(
                    (Maintenance m) =>
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                          child: _HistoryTile(log: m),
                        ),
                  ),

              const SizedBox(height: 18),

              // CTA
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: FilledButton.icon(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ReminderScreen(car: car),
                      ),
                    );
                    onRefresh();
                  },
                  icon: const Icon(Icons.notification_add_outlined),
                  label: const Text('Hatırlatıcı ekle'),
                ),
              ),

              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: OutlinedButton.icon(
                  onPressed: onAddCar,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                    side: BorderSide(
                        color: AppTheme.primary.withValues(alpha: 0.5)),
                  ),
                  icon: const Icon(Icons.add, color: AppTheme.primary),
                  label: const Text('Yeni araç',
                      style: TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w700)),
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

// ============ CAR HEADER CARD ============
// Figma (approx. 385×254): top tapered card 250px, bottom rounded card 170px,
// corner radius 46px. Top card narrows left→right on both top and bottom edges.

const double _kHeroCardDesignWidth = 385.44;
const double _kHeroTopCardHeightPx = 250;
const double _kHeroBottomCardHeightPx = 170;
const double _kHeroCardCornerRadiusPx = 46;
const double _kTaperRightHeightFactor = 1;

class _CarHeaderCard extends StatelessWidget {
  const _CarHeaderCard({
    required this.car,
    required this.logs,
    required this.onEdit,
  });

  final Car car;
  final List<Maintenance> logs;
  final VoidCallback onEdit;

  String get _totalKmText {
    if (logs.isEmpty) return '0';
    final int latest = logs
        .map((Maintenance e) => e.km)
        .reduce((int a, int b) => a > b ? a : b);
    return NumberFormat.decimalPattern('tr_TR').format(latest);
  }

  @override
  Widget build(BuildContext context) {
    final Color accent = CarCardPalette.resolve(
      argbValue: car.cardColor,
      seed: car.id,
    );
    final Color bottomColor = Color.lerp(accent, Colors.white, 0.40)!;;
    final Color topTaperColor =accent;
    final Color titleOnTopColor = accent;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 40),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double w = constraints.maxWidth;
          final double s = (w / _kHeroCardDesignWidth).clamp(0.82, 1.0);
          final double hTop = _kHeroTopCardHeightPx * s;
          final double hBottom = _kHeroBottomCardHeightPx * s;
          final double br = math
              .min(_kHeroCardCornerRadiusPx * s, math.min(w, hTop) * 0.18)
              .clamp(16.0, _kHeroCardCornerRadiusPx);
          final double rightSpan = math.max(
            90 * s,
            hBottom * _kTaperRightHeightFactor,
          );

          return SizedBox(
            height: hTop,
            child: Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                // Alt kart 170px; hBottom altında ek renk şeridi yok (taper dışı scaffold).
                // Bottom card — 170px design height, 46 radius, same top-left.
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: hBottom,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: bottomColor,
                      borderRadius: BorderRadius.circular(br),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.22),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                  ),
                ),
                // Üst kart (daralan), açık accent.
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: hTop,
                  child: CustomPaint(
                    painter: _TaperedTopCardPainter(
                      color: topTaperColor,
                      rightInnerHeight: rightSpan,
                      cornerRadius: br,
                      shadowColor: bottomColor.withValues(alpha: 0.25),
                      shadowBlur: 12,
                    ),
                  ),
                ),
                // Plate + model on bottom (dark) card, left side.
                Positioned(
                  top: 52 * s,
                  left: 24,
                  right: 24,
                  height: hBottom - 56 * s,
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: w * 0.42),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            car.plaka,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.4,
                            ),
                          ),
                          SizedBox(height: 6 * s),
                          Text(
                            '${car.yil} Model',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Title + KM (üst sol).
                Positioned(
                  top: 18 * s,
                  left: 22 * s,
                  right: 56 * s,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          '${car.marka} ${car.model}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: titleOnTopColor,
                            fontSize: 21 * s,
                            fontWeight: FontWeight.w800,
                            height: 1.12,
                          ),
                        ),
                      ),
                      SizedBox(width: 8 * s),
                      Padding(
                        padding: EdgeInsets.only(top: 3 * s),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                              Icons.map_outlined,
                              color: titleOnTopColor.withValues(alpha: 0.88),
                              size: 16 * s,
                            ),
                            SizedBox(width: 5 * s),
                            Text(
                              '$_totalKmText KM',
                              style: TextStyle(
                                color: titleOnTopColor.withValues(alpha: 0.9),
                                fontWeight: FontWeight.w700,
                                fontSize: 12 * s,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 10 * s,
                  right: 14 * s,
                  child: Material(
                    color: accent.withValues(alpha: 0.14),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onEdit,
                      child: SizedBox(
                        width: 36 * s,
                        height: 36 * s,
                        child: Icon(
                          Icons.edit_outlined,
                          color: titleOnTopColor,
                          size: 18 * s,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: hTop * 0.38,
                  left: 120 * s,
                  right: -20 * s,
                  bottom: -28 * s,
                  child: IgnorePointer(
                    child: _CarImage(imagePath: car.imagePath),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CarImage extends StatelessWidget {
  const _CarImage({required this.imagePath});

  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    final bool hasFile = imagePath != null &&
        imagePath!.isNotEmpty &&
        File(imagePath!).existsSync();

    if (!hasFile) {
      return Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: const EdgeInsets.only(right: 22, bottom: 22),
          child: Icon(
            Icons.directions_car,
            size: 110,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    // Saydam PNG (arka planı kaldırılmış) ya da düz fotoğraf olabilir.
    // Aracın altı karta basacak şekilde sağ-alt hizalı, BoxFit.contain.
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Image.file(
        File(imagePath!),
        fit: BoxFit.contain,
        alignment: Alignment.bottomRight,
      ),
    );
  }
}

// ============ STATS STRIP ============

class _CarStatsStrip extends StatelessWidget {
  const _CarStatsStrip({required this.car, required this.logs});
  final Car car;
  final List<Maintenance> logs;

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
            label: 'Ort. Bakım',
            value: _avgCostText,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            icon: Icons.schedule_outlined,
            label: 'Son Servis',
            value: _lastServiceText,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            icon: Icons.build_outlined,
            label: 'Toplam',
            value: '${logs.length}',
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
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: tokens.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: AppTheme.primary, size: 18),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: tokens.mutedText,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DotsIndicator extends StatelessWidget {
  const _DotsIndicator({required this.count, required this.current});
  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(count, (int i) {
        final bool active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 18 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active
                ? AppTheme.primary
                : AppTheme.primary.withValues(alpha: 0.28),
            borderRadius: BorderRadius.circular(6),
          ),
        );
      }),
    );
  }
}

// ============ NEEDS ATTENTION ============

class _NeedsAttentionList extends StatelessWidget {
  const _NeedsAttentionList(
      {required this.car, required this.reminders});

  final Car car;
  final List<Reminder> reminders;

  @override
  Widget build(BuildContext context) {
    if (reminders.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: _MutedTile(
          icon: Icons.check_circle_outline,
          title: 'Hepsi güncel',
          subtitle: 'Bu araç için yaklaşan bir hatırlatıcı yok.',
          trailing: TextButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ReminderScreen(car: car),
                ),
              );
            },
            icon: const Icon(Icons.add, color: AppTheme.primary),
            label: const Text('Ekle',
                style: TextStyle(color: AppTheme.primary)),
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
          );
        },
      ),
    );
  }
}

class _AttentionCard extends StatelessWidget {
  const _AttentionCard({required this.reminder, required this.car});
  final Reminder reminder;
  final Car car;

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
    final ReminderStatus status = DateHelper.statusFor(reminder.bitisTarihi);
    final int days = DateHelper.daysUntil(reminder.bitisTarihi);
    final Color statusColor = DateHelper.colorFor(status);
    final bool highlighted = status == ReminderStatus.critical ||
        status == ReminderStatus.expired;

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
        decoration: BoxDecoration(
          color: context.tokens.cardBg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: highlighted ? AppTheme.primary : context.tokens.border,
            width: highlighted ? 1.5 : 1,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              reminder.tur.label,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(_icon, color: AppTheme.primary, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              days < 0 ? 'Süresi doldu' : 'Replace in',
              style: TextStyle(
                fontSize: 11,
                color: days < 0 ? statusColor : context.tokens.mutedText,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              days < 0 ? '${days.abs()} gün önce' : '$days Days',
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

// ============ SERVICE HISTORY ============

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.log});
  final Maintenance log;

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
    return Container(
      decoration: BoxDecoration(
        color: tokens.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tokens.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              log.islem.isNotEmpty ? log.islem.characters.first.toUpperCase() : '?',
              style: const TextStyle(
                color: AppTheme.primary,
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
                Text('$timeAgo • ${log.km} km',
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 6),
                Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
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
              Text('Up to date',
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
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.tokens.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.tokens.border),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

// ============ EMPTY GARAGE ============

class _EmptyGarage extends StatelessWidget {
  const _EmptyGarage({required this.onAddCar});
  final VoidCallback onAddCar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.directions_car,
                  size: 60, color: AppTheme.primary),
            ),
            const SizedBox(height: 20),
            Text('Garaja hoş geldin',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Araçlarını ekle, sigorta, kasko, muayene gibi tarihleri '
                'takip et ve bakım geçmişini tek yerde tut.',
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 240,
              child: FilledButton.icon(
                onPressed: onAddCar,
                icon: const Icon(Icons.add),
                label: const Text('İlk aracını ekle'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============ ALL REMINDERS TAB ============

class _AllRemindersTab extends StatelessWidget {
  const _AllRemindersTab({required this.future});
  final Future<_GarageData> future;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_GarageData>(
      future: future,
      builder: (BuildContext context, AsyncSnapshot<_GarageData> snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final _GarageData data = snap.data!;
        final List<Reminder> reminders = List<Reminder>.of(data.reminders)
          ..sort((Reminder a, Reminder b) =>
              a.bitisTarihi.compareTo(b.bitisTarihi));

        return Column(
          children: <Widget>[
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text('Hatırlatıcılar',
                        style: Theme.of(context).textTheme.headlineMedium),
                  ),
                ],
              ),
            ),
            Expanded(
              child: reminders.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Henüz hatırlatıcı yok. Bir araca girip sigorta,\n'
                          'kasko, muayene veya egzoz tarihi ekle.',
                          textAlign: TextAlign.center,
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
                              plaka: '—', marka: '?', model: '', yil: 0),
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
    final ReminderStatus status = DateHelper.statusFor(reminder.bitisTarihi);
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
                Text('${reminder.tur.label} • ${car.plaka}',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  '${DateHelper.formatLong(reminder.bitisTarihi)} • '
                  '${DateHelper.humanizeRemaining(reminder.bitisTarihi)}',
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

// ============ SETTINGS TAB ============

class _SettingsTab extends StatelessWidget {
  const _SettingsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: <Widget>[
        Text('Ayarlar',
            style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 18),

        // Theme selector
        _settingsCard(context, <Widget>[
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Row(
              children: <Widget>[
                Icon(Icons.brightness_6_outlined, color: AppTheme.primary),
                SizedBox(width: 12),
                Text(
                  'Tema',
                  style:
                      TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ],
            ),
          ),
          const _ThemeModeSelector(),
          const SizedBox(height: 12),
        ]),

        const SizedBox(height: 12),

        _settingsCard(context, const <Widget>[
          ListTile(
            leading: Icon(Icons.notifications_active_outlined,
                color: AppTheme.primary),
            title: Text('Bildirimler'),
            subtitle: Text(
                'Hatırlatıcı tarihinden 7 gün önce bildirim gönderilir.'),
          ),
        ]),
        const SizedBox(height: 12),
        _settingsCard(context, const <Widget>[
          ListTile(
            leading: Icon(Icons.info_outline, color: AppTheme.primary),
            title: Text('Sürüm'),
            subtitle: Text('1.0.0'),
          ),
        ]),
      ],
    );
  }

  Widget _settingsCard(BuildContext context, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: context.tokens.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.tokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _ThemeModeSelector extends StatelessWidget {
  const _ThemeModeSelector();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance,
      builder: (BuildContext context, ThemeMode mode, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SegmentedButton<ThemeMode>(
            segments: const <ButtonSegment<ThemeMode>>[
              ButtonSegment<ThemeMode>(
                value: ThemeMode.light,
                icon: Icon(Icons.light_mode_outlined),
                label: Text('Aydınlık'),
              ),
              ButtonSegment<ThemeMode>(
                value: ThemeMode.dark,
                icon: Icon(Icons.dark_mode_outlined),
                label: Text('Karanlık'),
              ),
              ButtonSegment<ThemeMode>(
                value: ThemeMode.system,
                icon: Icon(Icons.brightness_auto_outlined),
                label: Text('Sistem'),
              ),
            ],
            selected: <ThemeMode>{mode},
            onSelectionChanged: (Set<ThemeMode> set) {
              ThemeController.instance.set(set.first);
            },
            style: ButtonStyle(
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ============ BOTTOM NAV ============

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.index, required this.onTap});
  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final List<_NavItem> items = const <_NavItem>[
      _NavItem(icon: Icons.directions_car_outlined, label: 'Araçlarım'),
      _NavItem(icon: Icons.notifications_none_rounded, label: 'Hatırlatıcılar'),
      _NavItem(icon: Icons.settings_outlined, label: 'Ayarlar'),
    ];

    final AppTokens tokens = context.tokens;
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: tokens.surfaceMuted,
          borderRadius: BorderRadius.circular(36),
          border: dark ? Border.all(color: tokens.border) : null,
          boxShadow: dark
              ? null
              : <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Row(
          children: List<Widget>.generate(items.length, (int i) {
            final bool selected = i == index;
            final _NavItem item = items[i];
            return Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(28),
                onTap: () => onTap(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppTheme.primary.withValues(alpha: 0.14)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        item.icon,
                        color:
                            selected ? AppTheme.primary : tokens.mutedText,
                        size: 20,
                      ),
                      if (selected) ...<Widget>[
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            item.label,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

/// Tapered top card (Figma): left height = [size.height], right vertical span
/// = [rightInnerHeight]. Top edge slopes down L→R; bottom slopes up L→R.
/// All corners use circular fillets ([arcToPoint]).
class _TaperedTopCardPainter extends CustomPainter {
  const _TaperedTopCardPainter({
    required this.color,
    required this.rightInnerHeight,
    this.cornerRadius = 46,
    this.shadowColor,
    this.shadowBlur = 0,
  });

  final Color color;
  /// Height of the right side (matches bottom dark card design height).
  final double rightInnerHeight;
  final double cornerRadius;
  final Color? shadowColor;
  final double shadowBlur;

  static Offset _norm(Offset v) {
    final double d = v.distance;
    if (d < 1e-9) {
      return Offset.zero;
    }
    return Offset(v.dx / d, v.dy / d);
  }

  Path _path(Size size) {
    final double w = size.width;
    final double h = size.height;
    final double rCap = math.min(
      cornerRadius,
      math.min(w * 0.16, h * 0.18),
    );

    final double yTr = (h - rightInnerHeight) / 2;
    final double yBr = yTr + rightInnerHeight;

    // Clockwise: TL → TR → BR → BL — both top and bottom narrow to the right.
    final List<Offset> pts = <Offset>[
      Offset.zero,
      Offset(w, yTr),
      Offset(w, yBr),
      Offset(0, h),
    ];

    final Path path = Path();
    for (int i = 0; i < 4; i++) {
      final Offset prev = pts[(i + 3) % 4];
      final Offset curr = pts[i];
      final Offset next = pts[(i + 1) % 4];

      final Offset v1 = _norm(curr - prev);
      final Offset v2 = _norm(next - curr);
      final double cosInterior =
          (-v1.dx * v2.dx - v1.dy * v2.dy).clamp(-1.0, 1.0);
      final double angle = math.acos(cosInterior);

      if (angle < 1e-3 || (math.pi - angle).abs() < 1e-3) {
        if (i == 0) {
          path.moveTo(curr.dx, curr.dy);
        } else {
          path.lineTo(curr.dx, curr.dy);
        }
        continue;
      }

      final double tanHalf = math.tan(angle / 2);
      double dist = rCap / tanHalf;
      final double lenIn = (curr - prev).distance;
      final double lenOut = (next - curr).distance;
      final double maxD = math.min(lenIn, lenOut) / 2 - 0.5;
      dist = math.min(dist, maxD);
      if (dist < 1.0) {
        if (i == 0) {
          path.moveTo(curr.dx, curr.dy);
        } else {
          path.lineTo(curr.dx, curr.dy);
        }
        continue;
      }

      final Offset pStart = Offset(
        curr.dx - v1.dx * dist,
        curr.dy - v1.dy * dist,
      );
      final Offset pEnd = Offset(
        curr.dx + v2.dx * dist,
        curr.dy + v2.dy * dist,
      );

      if (i == 0) {
        path.moveTo(pStart.dx, pStart.dy);
      } else {
        path.lineTo(pStart.dx, pStart.dy);
      }
      path.arcToPoint(
        pEnd,
        radius: Radius.circular(rCap),
        rotation: 0,
        largeArc: false,
        clockwise: true,
      );
    }
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final Path path = _path(size);
    if (shadowColor != null && shadowBlur > 0) {
      canvas.drawShadow(path, shadowColor!, shadowBlur, false);
    }
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TaperedTopCardPainter old) =>
      old.color != color ||
      old.rightInnerHeight != rightInnerHeight ||
      old.cornerRadius != cornerRadius ||
      old.shadowColor != shadowColor ||
      old.shadowBlur != shadowBlur;
}

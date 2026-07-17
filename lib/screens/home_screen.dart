import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:ms_undraw/ms_undraw.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/car_model.dart';
import '../models/maintenance_model.dart';
import '../models/reminder_model.dart';
import '../repositories/car_repository.dart';
import '../repositories/maintenance_repository.dart';
import '../repositories/reminder_repository.dart';
import '../repositories/supabase_car_repository.dart';
import '../repositories/supabase_maintenance_repository.dart';
import '../repositories/supabase_reminder_repository.dart';
import '../l10n/l10n_ext.dart';
import '../services/date_helper.dart';
import '../services/distance_unit_controller.dart';
import '../services/image_storage_service.dart';
import '../services/locale_controller.dart';
import '../services/home_widget_service.dart';
import '../services/notification_service.dart';
import '../services/update_service.dart';
import '../utils/distance_format.dart';
import '../services/session_controller.dart';
import '../utils/car_image_normalize.dart';
import '../utils/turkish_plate.dart';
import '../theme/app_theme.dart';
import '../theme/car_card_palette.dart';
import '../theme/garage_card_theming.dart';
import '../theme/theme_controller.dart';
import '../widgets/brand_logo_circle.dart';
import '../widgets/app_confirm_dialog.dart';
import '../widgets/load_error_view.dart';
import '../widgets/undraw_empty_state.dart';
import 'add_car_screen.dart';
import 'maintenance_screen.dart';
import 'nearest_mechanic_screen.dart';
import 'support_chat_screen.dart';
import 'reminder_screen.dart';

part 'home/garage_data.dart';
part 'home/dashboard_tab.dart';
part 'home/car_header_card.dart';
part 'home/needs_attention.dart';
part 'home/empty_garage.dart';
part 'home/all_reminders_tab.dart';
part 'home/settings_tab.dart';
part 'home/bottom_nav.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;

  final CarRepository _carRepo = SupabaseCarRepository();
  final ReminderRepository _reminderRepo = SupabaseReminderRepository();
  final MaintenanceRepository _mRepo = SupabaseMaintenanceRepository();

  late Future<_GarageData> _future;
  _GarageData? _cachedGarage;
  final PageController _pageController = PageController(viewportFraction: 1);
  int _currentCar = 0;

  @override
  void initState() {
    super.initState();
    _future = _bootstrap();
    unawaited(_checkForUpdate());
  }

  Future<_GarageData> _bootstrap() async {
    final _GarageData d = await _load();
    if (mounted) setState(() => _cachedGarage = d);
    // Mevcut hatırlatıcılar için 15/7/1 gün + km bildirimlerini yenile.
    unawaited(_rescheduleAllNotifications(d));
    unawaited(_updateHomeWidget(d));
    return d;
  }

  /// Açılışta Supabase app_config'e bakıp gerekiyorsa güncelleme diyaloğu gösterir.
  Future<void> _checkForUpdate() async {
    final UpdateInfo info = await UpdateService().check();
    if (!mounted || info.type == UpdateType.none) return;
    await _showUpdateDialog(info);
  }

  Future<void> _showUpdateDialog(UpdateInfo info) async {
    final bool forced = info.type == UpdateType.forced;
    await showDialog<void>(
      context: context,
      barrierDismissible: !forced,
      builder: (BuildContext ctx) {
        return PopScope(
          canPop: !forced,
          child: AlertDialog(
            title: Text(forced ? 'Güncelleme gerekli' : 'Yeni sürüm var'),
            content: Text(
              info.message ??
                  (forced
                      ? 'Devam etmek için uygulamayı güncellemelisin.'
                      : 'Yeni bir sürüm mevcut. Güncellemeni öneririz.'),
            ),
            actions: <Widget>[
              if (!forced)
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Şimdi değil'),
                ),
              FilledButton(
                onPressed: () async {
                  final String? url = info.storeUrl;
                  if (url != null) {
                    await launchUrl(
                      Uri.parse(url),
                      mode: LaunchMode.externalApplication,
                    );
                  }
                },
                child: const Text('Güncelle'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _rescheduleAllNotifications(_GarageData data) async {
    final Map<int, Car> carsById = <int, Car>{
      for (final Car c in data.cars)
        if (c.id != null) c.id!: c,
    };
    for (final Reminder r in data.reminders) {
      if (r.id == null) continue;
      final Car? car = carsById[r.carId];
      final String label = car == null
          ? ''
          : '${car.marka} ${car.model} (${car.plaka})';
      try {
        await NotificationService.instance.scheduleReminder(
          r,
          carLabel: label,
        );
      } catch (_) {}
    }
    try {
      await NotificationService.instance.checkKmReminders(
        reminders: data.reminders,
        carsById: carsById,
      );
    } catch (_) {}
  }

  Future<void> _updateHomeWidget(_GarageData data) async {
    try {
      await HomeWidgetService.instance.updateUpcoming(
        reminders: data.reminders,
        cars: data.cars,
      );
    } catch (_) {}
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

  Future<void> _refresh() async {
    if (!mounted) return;
    try {
      final _GarageData d = await _load();
      if (!mounted) return;
      final int newIdx = d.cars.isEmpty
          ? 0
          : _currentCar.clamp(0, d.cars.length - 1);
      setState(() {
        _cachedGarage = d;
        _future = Future<_GarageData>.value(d);
        _currentCar = newIdx;
      });
      unawaited(_rescheduleAllNotifications(d));
      unawaited(_updateHomeWidget(d));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_pageController.hasClients || d.cars.isEmpty) {
          return;
        }
        final int page = _pageController.page?.round() ?? 0;
        if (page != newIdx) {
          _pageController.jumpToPage(newIdx);
        }
      });
    } catch (e, st) {
      if (!mounted) return;
      setState(() {
        if (_cachedGarage != null) {
          _future = Future<_GarageData>.value(_cachedGarage!);
        } else {
          _future = Future<_GarageData>.error(e, st);
        }
      });
    }
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
        cachedGarage: _cachedGarage,
        pageController: _pageController,
        onCarChanged: (int i) => setState(() => _currentCar = i),
        currentCar: _currentCar,
        onAddCar: () => _openAddCar(),
        onEditCar: (Car c) => _openAddCar(existing: c),
        onRefresh: _refresh,
      ),
      _AllRemindersTab(
        future: _future,
        cachedGarage: _cachedGarage,
        onGoToGarage: () => setState(() => _navIndex = 0),
        onRefresh: _refresh,
      ),
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

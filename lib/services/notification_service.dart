import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../l10n/l10n_ext.dart';
import '../models/car_model.dart';
import '../models/reminder_model.dart';
import 'date_helper.dart';
import 'locale_controller.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  static const String _channelId = 'car_reminders_channel';

  /// Bitiş tarihinden kaç gün önce bildirim (sistem tepsisi).
  static const List<int> alertOffsetsDays = <int>[15, 7, 1];

  /// Km tabanlı uyarı eşikleri (kalan km).
  static const List<int> kmAlertThresholds = <int>[500, 0];

  Future<void> init() async {
    if (_initialized) return;

    tzdata.initializeTimeZones();

    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
      macOS: iosInit,
    );

    await _plugin.initialize(settings: initSettings);

    final AppLocalizations l10n =
        lookupAppLocalizations(LocaleController.resolve(null));

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          AndroidNotificationChannel(
            _channelId,
            l10n.notificationChannelName,
            description: l10n.notificationChannelDescription,
            importance: Importance.max,
          ),
        );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  /// Benzersiz bildirim id: `reminderId * 100 + daysBefore` (15 / 7 / 1).
  static int notificationIdFor(int reminderId, int daysBefore) =>
      reminderId * 100 + daysBefore;

  /// Km bildirimi id: `reminderId * 1000 + (threshold + 1)`.
  static int kmNotificationIdFor(int reminderId, int threshold) =>
      reminderId * 1000 + (threshold + 1);

  static String _kmDedupeKey(int reminderId, int threshold) =>
      'km_notif_${reminderId}_$threshold';

  /// Hatırlatıcı için 15 / 7 / 1 gün kala saat 09:00 bildirimlerini planlar.
  /// Km tabanlı veya bitiş tarihi yoksa planlanmaz (eski tarih bildirimleri iptal edilir).
  Future<void> scheduleReminder(
    Reminder reminder, {
    String carLabel = '',
  }) async {
    await init();
    if (reminder.id == null) return;

    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool('notifications_enabled') ?? true)) return;

    // Yeniden planlamadan önce eski 3 uyarıyı temizle.
    await cancelReminder(reminder.id!);

    if (reminder.isKmBased || reminder.bitisTarihi == null) {
      return;
    }

    final AppLocalizations l10n =
        lookupAppLocalizations(LocaleController.resolve(null));
    final String typeLabel = reminder.tur.localizedLabel(l10n);

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      _channelId,
      l10n.notificationChannelName,
      channelDescription: l10n.notificationChannelDescription,
      importance: Importance.max,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();
    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: iosDetails,
    );

    final DateTime now = DateTime.now();
    final DateTime bitis = reminder.bitisTarihi!;

    for (final int daysBefore in alertOffsetsDays) {
      final DateTime triggerLocal = bitis
          .subtract(Duration(days: daysBefore))
          .copyWith(
            hour: 9,
            minute: 0,
            second: 0,
            millisecond: 0,
            microsecond: 0,
          );

      if (!triggerLocal.isAfter(now)) continue;

      final tz.TZDateTime tzTime = tz.TZDateTime.from(triggerLocal, tz.local);
      final String title = l10n.notificationTitle(typeLabel);
      final String body = carLabel.isEmpty
          ? l10n.notificationBody(daysBefore, typeLabel)
          : l10n.notificationBodyWithCar(daysBefore, typeLabel, carLabel);

      await _plugin.zonedSchedule(
        id: notificationIdFor(reminder.id!, daysBefore),
        title: title,
        body: body,
        scheduledDate: tzTime,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'reminder_${reminder.id}_d$daysBefore',
      );
    }
  }

  /// Km tabanlı hatırlatıcılar için anlık bildirim (eşik 500 / 0, prefs ile tek sefer).
  Future<void> checkKmReminders({
    required List<Reminder> reminders,
    required Map<int, Car> carsById,
  }) async {
    await init();
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool('notifications_enabled') ?? true)) return;

    final AppLocalizations l10n =
        lookupAppLocalizations(LocaleController.resolve(null));

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      _channelId,
      l10n.notificationChannelName,
      channelDescription: l10n.notificationChannelDescription,
      importance: Importance.max,
      priority: Priority.high,
    );
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();
    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: iosDetails,
    );

    for (final Reminder r in reminders) {
      if (r.id == null || !r.isKmBased || r.targetKm == null) continue;
      final Car? car = carsById[r.carId];
      if (car == null) continue;

      final int? remaining = DateHelper.kmRemaining(r, car.km);
      if (remaining == null) continue;

      final String typeLabel = r.tur.localizedLabel(l10n);
      final String carLabel = '${car.marka} ${car.model} (${car.plaka})';

      for (final int threshold in kmAlertThresholds) {
        if (remaining > threshold) continue;
        final String key = _kmDedupeKey(r.id!, threshold);
        if (prefs.getBool(key) ?? false) continue;

        final String title = l10n.notificationTitle(typeLabel);
        final String kmText = remaining <= 0
            ? l10n.kmOverdueCount(remaining.abs())
            : l10n.kmRemainingCount(remaining);
        final String body = '$carLabel — $kmText';

        await _plugin.show(
          id: kmNotificationIdFor(r.id!, threshold),
          title: title,
          body: body,
          notificationDetails: details,
          payload: 'reminder_${r.id}_km$threshold',
        );
        await prefs.setBool(key, true);
      }
    }
  }

  Future<void> cancelReminder(int reminderId) async {
    await init();
    for (final int daysBefore in alertOffsetsDays) {
      await _plugin.cancel(id: notificationIdFor(reminderId, daysBefore));
    }
    for (final int threshold in kmAlertThresholds) {
      await _plugin.cancel(id: kmNotificationIdFor(reminderId, threshold));
    }
    // Eski tek-bildirim id’si (v1) varsa onu da temizle.
    await _plugin.cancel(id: reminderId);
  }

  Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }
}

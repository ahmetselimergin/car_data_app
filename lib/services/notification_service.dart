import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../l10n/l10n_ext.dart';
import '../models/reminder_model.dart';
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

  /// Hatırlatıcı için 15 / 7 / 1 gün kala saat 09:00 bildirimlerini planlar.
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

    for (final int daysBefore in alertOffsetsDays) {
      final DateTime triggerLocal = reminder.bitisTarihi
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

  Future<void> cancelReminder(int reminderId) async {
    await init();
    for (final int daysBefore in alertOffsetsDays) {
      await _plugin.cancel(id: notificationIdFor(reminderId, daysBefore));
    }
    // Eski tek-bildirim id’si (v1) varsa onu da temizle.
    await _plugin.cancel(id: reminderId);
  }

  Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }
}

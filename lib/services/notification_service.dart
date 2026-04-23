import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/reminder_model.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  static const String _channelId = 'car_reminders_channel';
  static const String _channelName = 'Araç Hatırlatıcıları';
  static const String _channelDescription =
      'Sigorta, kasko, muayene gibi tarihlerin yaklaştığını bildirir.';

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

    await _plugin.initialize(initSettings);

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  /// Hatırlatıcıyı, bitiş tarihinden [daysBefore] gün önce saat 09:00'da planlar.
  Future<void> scheduleReminder(
    Reminder reminder, {
    String carLabel = '',
    int daysBefore = 7,
  }) async {
    await init();
    if (reminder.id == null) return;

    final DateTime triggerLocal = reminder.bitisTarihi
        .subtract(Duration(days: daysBefore))
        .copyWith(hour: 9, minute: 0, second: 0, millisecond: 0, microsecond: 0);

    if (triggerLocal.isBefore(DateTime.now())) {
      return;
    }

    final tz.TZDateTime tzTime =
        tz.TZDateTime.from(triggerLocal, tz.local);

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: iosDetails,
    );

    final String title = '${reminder.tur.label} hatırlatması';
    final String body = carLabel.isEmpty
        ? '${reminder.tur.label} bitişine $daysBefore gün kaldı.'
        : '$carLabel için ${reminder.tur.label} bitişine $daysBefore gün kaldı.';

    await _plugin.zonedSchedule(
      reminder.id!,
      title,
      body,
      tzTime,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'reminder_${reminder.id}',
    );
  }

  Future<void> cancelReminder(int reminderId) async {
    await init();
    await _plugin.cancel(reminderId);
  }

  Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }
}

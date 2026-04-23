import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum ReminderStatus {
  expired('Süresi Dolmuş'),
  critical('Kritik'),
  approaching('Yaklaşıyor'),
  safe('Güvenli');

  final String label;
  const ReminderStatus(this.label);
}

class DateHelper {
  DateHelper._();

  static final DateFormat _dateFormatter = DateFormat('dd MMM yyyy', 'tr_TR');
  static final DateFormat _shortDateFormatter = DateFormat('dd/MM/yyyy');

  /// Verilen tarih ile bugünün tarihi arasındaki gün farkı.
  /// Pozitif değer: tarih ileride. Negatif: geçmiş.
  static int daysUntil(DateTime date) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime target = DateTime(date.year, date.month, date.day);
    return target.difference(today).inDays;
  }

  static ReminderStatus statusFor(DateTime date) {
    final int diff = daysUntil(date);
    if (diff < 0) return ReminderStatus.expired;
    if (diff < 15) return ReminderStatus.critical;
    if (diff < 30) return ReminderStatus.approaching;
    return ReminderStatus.safe;
  }

  static Color colorFor(ReminderStatus status) {
    switch (status) {
      case ReminderStatus.expired:
        return const Color(0xFFB00020);
      case ReminderStatus.critical:
        return const Color(0xFFE53935);
      case ReminderStatus.approaching:
        return const Color(0xFFF9A825);
      case ReminderStatus.safe:
        return const Color(0xFF2E7D32);
    }
  }

  static IconData iconFor(ReminderStatus status) {
    switch (status) {
      case ReminderStatus.expired:
        return Icons.error;
      case ReminderStatus.critical:
        return Icons.warning_amber_rounded;
      case ReminderStatus.approaching:
        return Icons.access_time;
      case ReminderStatus.safe:
        return Icons.check_circle;
    }
  }

  static String formatLong(DateTime date) => _dateFormatter.format(date);
  static String formatShort(DateTime date) => _shortDateFormatter.format(date);

  static String humanizeRemaining(DateTime date) {
    final int diff = daysUntil(date);
    if (diff < 0) return '${diff.abs()} gün önce doldu';
    if (diff == 0) return 'Bugün son gün';
    if (diff == 1) return 'Yarın son gün';
    return '$diff gün kaldı';
  }
}

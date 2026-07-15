import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/reminder_model.dart';

enum ReminderStatus {
  expired,
  critical,
  approaching,
  safe,
}

class DateHelper {
  DateHelper._();

  /// Km kalan ≤ bu değer → critical (bildirim eşiği ile uyumlu).
  static const int kmCriticalThreshold = 500;

  /// Km kalan ≤ bu değer → approaching.
  static const int kmApproachingThreshold = 1000;

  static DateFormat dateFormatterFor(String localeTag) =>
      DateFormat('dd MMM yyyy', localeTag);

  static final DateFormat _shortDateFormatter = DateFormat('dd/MM/yyyy');

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

  /// Hedef km − güncel km. [targetKm] yoksa null.
  static int? kmRemaining(Reminder r, int currentKm) {
    final int? target = r.targetKm;
    if (target == null) return null;
    return target - currentKm;
  }

  /// Km tabanlı hatırlatıcıda odometre; değilse bitiş tarihine göre durum.
  static ReminderStatus statusForReminder(
    Reminder r, {
    required int currentKm,
  }) {
    if (r.isKmBased) {
      final int? remaining = kmRemaining(r, currentKm);
      if (remaining == null) return ReminderStatus.safe;
      if (remaining <= 0) return ReminderStatus.expired;
      if (remaining <= kmCriticalThreshold) return ReminderStatus.critical;
      if (remaining <= kmApproachingThreshold) {
        return ReminderStatus.approaching;
      }
      return ReminderStatus.safe;
    }
    final DateTime? date = r.bitisTarihi;
    if (date == null) return ReminderStatus.safe;
    return statusFor(date);
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

  static String formatLong(DateTime date, String localeTag) =>
      dateFormatterFor(localeTag).format(date);

  static String formatShort(DateTime date) => _shortDateFormatter.format(date);
}

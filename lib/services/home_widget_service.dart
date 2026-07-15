import 'package:home_widget/home_widget.dart';

import '../l10n/l10n_ext.dart';
import '../models/car_model.dart';
import '../models/reminder_model.dart';
import 'date_helper.dart';
import 'locale_controller.dart';

/// Ana ekran widget verisini yazar.
///
/// iOS: Flutter tarafında [HomeWidget.saveWidgetData] yeterli; Widget Extension
/// bu görev kapsamında eklenmedi (sonra eklenebilir).
class HomeWidgetService {
  HomeWidgetService._();
  static final HomeWidgetService instance = HomeWidgetService._();

  static const String androidName = 'MyGarajWidgetProvider';
  static const String iOSName = 'MyGarajWidget';

  Future<void> updateUpcoming({
    required List<Reminder> reminders,
    required List<Car> cars,
  }) async {
    final AppLocalizations l10n =
        lookupAppLocalizations(LocaleController.resolve(null));
    final String localeTag = localeTagFor(LocaleController.resolve(null));

    final Map<int, Car> carsById = <int, Car>{
      for (final Car c in cars)
        if (c.id != null) c.id!: c,
    };

    final List<Reminder> upcoming = List<Reminder>.of(reminders)
      ..sort((Reminder a, Reminder b) {
        final int rankA = _urgencyRank(a, carsById);
        final int rankB = _urgencyRank(b, carsById);
        final int cmp = rankA.compareTo(rankB);
        if (cmp != 0) return cmp;
        return _sortKey(a, carsById).compareTo(_sortKey(b, carsById));
      });

    final List<String> lines = <String>[];
    for (final Reminder r in upcoming.take(3)) {
      final Car? car = carsById[r.carId];
      final int km = car?.km ?? 0;
      final String type = r.tur.localizedLabel(l10n);
      final String plate = car?.plaka ?? '';
      final String human = humanizeReminder(
        r,
        l10n,
        currentKm: km,
        localeTag: localeTag,
      );
      lines.add(
        plate.isEmpty ? '$type · $human' : '$type · $plate · $human',
      );
    }

    final bool empty = lines.isEmpty;
    await HomeWidget.saveWidgetData<String>('title', l10n.homeWidgetTitle);
    await HomeWidget.saveWidgetData<bool>('empty', empty);
    await HomeWidget.saveWidgetData<String>(
      'line1',
      empty ? l10n.homeWidgetEmpty : lines[0],
    );
    await HomeWidget.saveWidgetData<String>(
      'line2',
      lines.length > 1 ? lines[1] : '',
    );
    await HomeWidget.saveWidgetData<String>(
      'line3',
      lines.length > 2 ? lines[2] : '',
    );

    await HomeWidget.updateWidget(
      name: androidName,
      androidName: androidName,
      iOSName: iOSName,
    );
  }

  static int _urgencyRank(Reminder r, Map<int, Car> carsById) {
    final int km = carsById[r.carId]?.km ?? 0;
    switch (DateHelper.statusForReminder(r, currentKm: km)) {
      case ReminderStatus.expired:
        return 0;
      case ReminderStatus.critical:
        return 1;
      case ReminderStatus.approaching:
        return 2;
      case ReminderStatus.safe:
        return 3;
    }
  }

  static int _sortKey(Reminder r, Map<int, Car> carsById) {
    if (r.isKmBased) {
      return DateHelper.kmRemaining(r, carsById[r.carId]?.km ?? 0) ??
          1 << 30;
    }
    final DateTime? d = r.bitisTarihi;
    if (d == null) return 1 << 30;
    return d.millisecondsSinceEpoch;
  }
}

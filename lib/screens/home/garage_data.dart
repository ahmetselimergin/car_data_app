part of 'package:car_data_app/screens/home_screen.dart';

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
        ..sort((Reminder a, Reminder b) {
          final DateTime? da = a.bitisTarihi;
          final DateTime? db = b.bitisTarihi;
          if (da == null && db == null) {
            final int ka = a.targetKm ?? 1 << 30;
            final int kb = b.targetKm ?? 1 << 30;
            return ka.compareTo(kb);
          }
          if (da == null) return 1;
          if (db == null) return -1;
          return da.compareTo(db);
        });

  List<Maintenance> maintenanceOf(int carId) =>
      maintenance[carId] ?? <Maintenance>[];
}

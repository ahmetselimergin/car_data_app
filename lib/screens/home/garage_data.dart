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
        ..sort((Reminder a, Reminder b) =>
            a.bitisTarihi.compareTo(b.bitisTarihi));

  List<Maintenance> maintenanceOf(int carId) =>
      maintenance[carId] ?? <Maintenance>[];
}

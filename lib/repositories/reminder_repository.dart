import '../models/reminder_model.dart';
import '../services/database_helper.dart';

abstract class ReminderRepository {
  Future<int> addReminder(Reminder reminder);
  Future<List<Reminder>> getAllReminders();
  Future<List<Reminder>> getRemindersByCarId(int carId);
  Future<int> updateReminder(Reminder reminder);
  Future<int> deleteReminder(int id);
}

class SqliteReminderRepository implements ReminderRepository {
  SqliteReminderRepository({DatabaseHelper? db})
      : _db = db ?? DatabaseHelper.instance;

  final DatabaseHelper _db;

  @override
  Future<int> addReminder(Reminder reminder) => _db.insertReminder(reminder);

  @override
  Future<List<Reminder>> getAllReminders() => _db.getAllReminders();

  @override
  Future<List<Reminder>> getRemindersByCarId(int carId) =>
      _db.getRemindersByCarId(carId);

  @override
  Future<int> updateReminder(Reminder reminder) =>
      _db.updateReminder(reminder);

  @override
  Future<int> deleteReminder(int id) => _db.deleteReminder(id);
}

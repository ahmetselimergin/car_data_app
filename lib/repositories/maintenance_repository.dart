import '../models/maintenance_model.dart';
import '../services/database_helper.dart';

abstract class MaintenanceRepository {
  Future<int> addMaintenance(Maintenance log);
  Future<List<Maintenance>> getMaintenanceByCarId(int carId);
  Future<int> deleteMaintenance(int id);
}

class SqliteMaintenanceRepository implements MaintenanceRepository {
  SqliteMaintenanceRepository({DatabaseHelper? db})
      : _db = db ?? DatabaseHelper.instance;

  final DatabaseHelper _db;

  @override
  Future<int> addMaintenance(Maintenance log) => _db.insertMaintenance(log);

  @override
  Future<List<Maintenance>> getMaintenanceByCarId(int carId) =>
      _db.getMaintenanceByCarId(carId);

  @override
  Future<int> deleteMaintenance(int id) => _db.deleteMaintenance(id);
}

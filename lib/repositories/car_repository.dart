import '../models/car_model.dart';
import '../services/database_helper.dart';

/// UI katmanının doğrudan veritabanıyla konuşmasını engelleyen soyutlama.
  /// İleride [SupabaseCarRepository] gibi farklı bir uygulaması yazılabilir.
abstract class CarRepository {
  Future<int> addCar(Car car);
  Future<List<Car>> getCars();
  Future<Car?> getCar(int id);
  Future<int> updateCar(Car car);
  Future<int> deleteCar(int id);
}

class SqliteCarRepository implements CarRepository {
  SqliteCarRepository({DatabaseHelper? db})
      : _db = db ?? DatabaseHelper.instance;

  final DatabaseHelper _db;

  @override
  Future<int> addCar(Car car) => _db.insertCar(car);

  @override
  Future<List<Car>> getCars() => _db.getAllCars();

  @override
  Future<Car?> getCar(int id) => _db.getCarById(id);

  @override
  Future<int> updateCar(Car car) => _db.updateCar(car);

  @override
  Future<int> deleteCar(int id) => _db.deleteCar(id);
}

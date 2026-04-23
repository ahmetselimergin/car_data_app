import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/car_model.dart';
import '../models/maintenance_model.dart';
import '../models/reminder_model.dart';

class DatabaseHelper {
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static const String _dbName = 'car_data.db';
  static const int _dbVersion = 3;

  static const String tableCars = 'cars';
  static const String tableReminders = 'reminders';
  static const String tableMaintenance = 'maintenance';

  Database? _database;

  Future<Database> get database async {
    return _database ??= await _initDatabase();
  }

  Future<Database> _initDatabase() async {
    final String dbPath = await getDatabasesPath();
    final String path = p.join(dbPath, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE $tableCars ADD COLUMN imagePath TEXT');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE $tableCars ADD COLUMN cardColor INTEGER');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableCars (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        plaka TEXT NOT NULL,
        marka TEXT NOT NULL,
        model TEXT NOT NULL,
        yil INTEGER NOT NULL,
        imagePath TEXT,
        cardColor INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableReminders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        carId INTEGER NOT NULL,
        tur TEXT NOT NULL,
        bitisTarihi TEXT NOT NULL,
        hatirlatmaYapildiMi INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (carId) REFERENCES $tableCars (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableMaintenance (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        carId INTEGER NOT NULL,
        islem TEXT NOT NULL,
        tarih TEXT NOT NULL,
        km INTEGER NOT NULL,
        maliyet REAL NOT NULL,
        FOREIGN KEY (carId) REFERENCES $tableCars (id) ON DELETE CASCADE
      )
    ''');
  }

  // ----------------------- CARS CRUD -----------------------

  Future<int> insertCar(Car car) async {
    final Database db = await database;
    return db.insert(tableCars, car.toMap()..remove('id'));
  }

  Future<List<Car>> getAllCars() async {
    final Database db = await database;
    final List<Map<String, dynamic>> rows =
        await db.query(tableCars, orderBy: 'id DESC');
    return rows.map(Car.fromMap).toList();
  }

  Future<Car?> getCarById(int id) async {
    final Database db = await database;
    final List<Map<String, dynamic>> rows = await db.query(
      tableCars,
      where: 'id = ?',
      whereArgs: <Object>[id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Car.fromMap(rows.first);
  }

  Future<int> updateCar(Car car) async {
    if (car.id == null) {
      throw ArgumentError('Güncellenecek aracın id alanı null olamaz.');
    }
    final Database db = await database;
    return db.update(
      tableCars,
      car.toMap(),
      where: 'id = ?',
      whereArgs: <Object>[car.id!],
    );
  }

  Future<int> deleteCar(int id) async {
    final Database db = await database;
    return db.delete(tableCars, where: 'id = ?', whereArgs: <Object>[id]);
  }

  // -------------------- REMINDERS CRUD ---------------------

  Future<int> insertReminder(Reminder reminder) async {
    final Database db = await database;
    return db.insert(tableReminders, reminder.toMap()..remove('id'));
  }

  Future<List<Reminder>> getAllReminders() async {
    final Database db = await database;
    final List<Map<String, dynamic>> rows =
        await db.query(tableReminders, orderBy: 'bitisTarihi ASC');
    return rows.map(Reminder.fromMap).toList();
  }

  Future<List<Reminder>> getRemindersByCarId(int carId) async {
    final Database db = await database;
    final List<Map<String, dynamic>> rows = await db.query(
      tableReminders,
      where: 'carId = ?',
      whereArgs: <Object>[carId],
      orderBy: 'bitisTarihi ASC',
    );
    return rows.map(Reminder.fromMap).toList();
  }

  Future<int> updateReminder(Reminder reminder) async {
    if (reminder.id == null) {
      throw ArgumentError('Güncellenecek hatırlatıcının id alanı null olamaz.');
    }
    final Database db = await database;
    return db.update(
      tableReminders,
      reminder.toMap(),
      where: 'id = ?',
      whereArgs: <Object>[reminder.id!],
    );
  }

  Future<int> deleteReminder(int id) async {
    final Database db = await database;
    return db.delete(tableReminders, where: 'id = ?', whereArgs: <Object>[id]);
  }

  // -------------------- MAINTENANCE CRUD --------------------

  Future<int> insertMaintenance(Maintenance log) async {
    final Database db = await database;
    return db.insert(tableMaintenance, log.toMap()..remove('id'));
  }

  Future<List<Maintenance>> getMaintenanceByCarId(int carId) async {
    final Database db = await database;
    final List<Map<String, dynamic>> rows = await db.query(
      tableMaintenance,
      where: 'carId = ?',
      whereArgs: <Object>[carId],
      orderBy: 'tarih DESC',
    );
    return rows.map(Maintenance.fromMap).toList();
  }

  Future<int> deleteMaintenance(int id) async {
    final Database db = await database;
    return db.delete(
      tableMaintenance,
      where: 'id = ?',
      whereArgs: <Object>[id],
    );
  }

  Future<void> close() async {
    final Database? db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}

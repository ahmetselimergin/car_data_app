import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/car_model.dart';
import '../models/maintenance_model.dart';
import '../models/reminder_model.dart';
import 'image_storage_service.dart';

class DatabaseHelper {
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static const String _dbName = 'car_data.db';
  static const int _dbVersion = 8;

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
    if (oldVersion < 4) {
      await db.execute(
        'ALTER TABLE $tableCars ADD COLUMN km INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute('ALTER TABLE $tableCars ADD COLUMN transmission TEXT');
      await db.execute('ALTER TABLE $tableCars ADD COLUMN fuelType TEXT');
    }
    if (oldVersion < 5) {
      await db.execute(
        'ALTER TABLE $tableMaintenance ADD COLUMN servisAdi TEXT',
      );
      await db.execute('ALTER TABLE $tableMaintenance ADD COLUMN notlar TEXT');
      await db.execute(
        'ALTER TABLE $tableMaintenance ADD COLUMN resmiServis INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE $tableMaintenance ADD COLUMN garantiKapsaminda INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE $tableMaintenance ADD COLUMN faturaAlindi INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE $tableMaintenance ADD COLUMN sigortaKarsiladi INTEGER NOT NULL DEFAULT 0',
      );
    }
    if (oldVersion < 6) {
      await db.execute(
        'ALTER TABLE $tableMaintenance ADD COLUMN bakimKalemleri TEXT',
      );
    }
    if (oldVersion < 7) {
      await db.execute('ALTER TABLE $tableReminders ADD COLUMN targetKm INTEGER');
    }
    if (oldVersion < 8) {
      await db.execute(
        'ALTER TABLE $tableMaintenance ADD COLUMN attachmentUrl TEXT',
      );
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
        cardColor INTEGER,
        km INTEGER NOT NULL DEFAULT 0,
        transmission TEXT,
        fuelType TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableReminders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        carId INTEGER NOT NULL,
        tur TEXT NOT NULL,
        bitisTarihi TEXT,
        targetKm INTEGER,
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
        servisAdi TEXT,
        notlar TEXT,
        resmiServis INTEGER NOT NULL DEFAULT 0,
        garantiKapsaminda INTEGER NOT NULL DEFAULT 0,
        faturaAlindi INTEGER NOT NULL DEFAULT 0,
        sigortaKarsiladi INTEGER NOT NULL DEFAULT 0,
        bakimKalemleri TEXT,
        attachmentUrl TEXT,
        FOREIGN KEY (carId) REFERENCES $tableCars (id) ON DELETE CASCADE
      )
    ''');
  }

  // ----------------------- CARS CRUD -----------------------

  Future<int> insertCar(Car car) async {
    final Database db = await database;
    return db.insert(tableCars, car.toMap()..remove('id'));
  }

  /// Supabase id'sini yerel FK'ler için aynen saklar.
  Future<int> insertCarWithId(Car car) async {
    if (car.id == null) {
      throw ArgumentError('insertCarWithId için id zorunlu.');
    }
    final Database db = await database;
    return db.insert(
      tableCars,
      car.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Car>> getAllCars() async {
    final Database db = await database;
    final List<Map<String, dynamic>> rows =
        await db.query(tableCars, orderBy: 'id DESC');
    final List<Car> cars = rows.map(Car.fromMap).toList();
    return _migrateCarImagePaths(cars);
  }

  /// Mutlak iOS yollarını göreli `car_images/…` formuna çevirir.
  Future<List<Car>> _migrateCarImagePaths(List<Car> cars) async {
    final List<Car> out = <Car>[];
    for (final Car car in cars) {
      final String? stored = car.imagePath;
      if (stored == null || stored.isEmpty || car.id == null) {
        out.add(car);
        continue;
      }
      final String? resolved =
          await ImageStorageService.instance.resolvePath(stored);
      if (resolved == null) {
        out.add(car);
        continue;
      }
      final String relative =
          ImageStorageService.instance.toRelative(resolved);
      if (relative == stored) {
        out.add(car);
        continue;
      }
      final Car updated = car.copyWith(imagePath: relative);
      await updateCar(updated);
      out.add(updated);
    }
    return out;
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

  /// Supabase id'sini yerel FK / bildirim id'si için aynen saklar.
  Future<int> insertReminderWithId(Reminder reminder) async {
    if (reminder.id == null) {
      throw ArgumentError('insertReminderWithId için id zorunlu.');
    }
    final Database db = await database;
    return db.insert(
      tableReminders,
      reminder.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
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

  /// Supabase id'sini yerel yansıma için aynen saklar.
  Future<int> insertMaintenanceWithId(Maintenance log) async {
    if (log.id == null) {
      throw ArgumentError('insertMaintenanceWithId için id zorunlu.');
    }
    final Database db = await database;
    return db.insert(
      tableMaintenance,
      log.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
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

  Future<int> updateMaintenance(Maintenance log) async {
    if (log.id == null) {
      throw ArgumentError('updateMaintenance requires id');
    }
    final Database db = await database;
    return db.update(
      tableMaintenance,
      log.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: <Object>[log.id!],
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

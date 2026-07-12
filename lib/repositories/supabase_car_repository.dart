import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/car_model.dart';
import '../services/database_helper.dart';
import '../services/image_storage_service.dart';
import 'car_repository.dart';

const String kCarImagesBucket = 'car-images';

/// Kullanıcı garaj arabaları → Supabase `cars` (+ yerel SQLite yansıması).
/// Fotoğraflar `car-images/{uid}/…` bucket'ına yüklenir; `image_url` public URL tutulur.
class SupabaseCarRepository implements CarRepository {
  SupabaseCarRepository({
    SupabaseClient? client,
    DatabaseHelper? db,
  })  : _client = client ?? Supabase.instance.client,
        _db = db ?? DatabaseHelper.instance;

  final SupabaseClient _client;
  final DatabaseHelper _db;

  String get _uid {
    final String? id = _client.auth.currentUser?.id;
    if (id == null || id.isEmpty) {
      throw StateError('Araç kaydı için giriş yapmış olmalısınız.');
    }
    return id;
  }

  static bool isRemoteUrl(String? value) {
    if (value == null || value.isEmpty) return false;
    return value.startsWith('http://') || value.startsWith('https://');
  }

  Map<String, dynamic> _toRow(
    Car car, {
    required String ownerUid,
    required String? imageUrl,
  }) {
    return <String, dynamic>{
      'plaka': car.plaka,
      'marka': car.marka,
      'model': car.model,
      'yil': car.yil,
      'km': car.km,
      'transmission': car.transmission,
      'fuel_type': car.fuelType,
      'image_url': imageUrl,
      'card_color': car.cardColor,
      'owner_uid': ownerUid,
    };
  }

  Car _fromRow(Map<String, dynamic> row) {
    return Car(
      id: (row['id'] as num?)?.toInt(),
      plaka: row['plaka'] as String? ?? '',
      marka: row['marka'] as String? ?? '',
      model: row['model'] as String? ?? '',
      yil: (row['yil'] as num?)?.toInt() ?? 0,
      imagePath: row['image_url'] as String?,
      cardColor: (row['card_color'] as num?)?.toInt(),
      km: (row['km'] as num?)?.toInt() ?? 0,
      transmission: row['transmission'] as String?,
      fuelType: row['fuel_type'] as String?,
    );
  }

  Future<void> _mirrorLocal(Car car) async {
    if (car.id == null) return;
    final Car? existing = await _db.getCarById(car.id!);
    if (existing == null) {
      await _db.insertCarWithId(car);
    } else {
      await _db.updateCar(car);
    }
  }

  String? _storagePathFromUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    final String marker = '/storage/v1/object/public/$kCarImagesBucket/';
    final int idx = url.indexOf(marker);
    if (idx == -1) return null;
    return Uri.decodeComponent(url.substring(idx + marker.length));
  }

  Future<void> _deleteRemoteIfOurs(String? url) async {
    final String? path = _storagePathFromUrl(url);
    if (path == null) return;
    try {
      await _client.storage.from(kCarImagesBucket).remove(<String>[path]);
    } catch (_) {}
  }

  Future<String> _uploadLocalImage(String localStored) async {
    final String? resolved =
        await ImageStorageService.instance.resolvePath(localStored);
    if (resolved == null || resolved.isEmpty) {
      throw StateError('Araç fotoğrafı bulunamadı.');
    }
    final File file = File(resolved);
    if (!await file.exists()) {
      throw StateError('Araç fotoğrafı bulunamadı.');
    }
    final Uint8List bytes = await file.readAsBytes();
    final String extRaw = p.extension(resolved).replaceFirst('.', '');
    final String ext = extRaw.isEmpty ? 'jpg' : extRaw.toLowerCase();
    final String path =
        '$_uid/car_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final String contentType = switch (ext) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'heic' => 'image/heic',
      _ => 'image/jpeg',
    };
    await _client.storage.from(kCarImagesBucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: contentType,
          ),
        );
    return _client.storage.from(kCarImagesBucket).getPublicUrl(path);
  }

  /// Yerel yol → Storage URL; zaten remote ise aynen bırakır.
  Future<String?> _resolveImageUrl(
    String? imagePath, {
    String? previousUrl,
  }) async {
    if (imagePath == null || imagePath.isEmpty) {
      if (previousUrl != null && previousUrl != imagePath) {
        await _deleteRemoteIfOurs(previousUrl);
      }
      return null;
    }
    if (isRemoteUrl(imagePath) || ImageStorageService.isRemoteUrl(imagePath)) {
      return imagePath;
    }
    try {
      final String url = await _uploadLocalImage(imagePath);
      if (previousUrl != null && previousUrl != url) {
        await _deleteRemoteIfOurs(previousUrl);
      }
      return url;
    } catch (_) {
      // Yerel dosya yoksa (ör. sadece metadata güncellemesi) mevcut URL kalsın.
      if (previousUrl != null &&
          (isRemoteUrl(previousUrl) ||
              ImageStorageService.isRemoteUrl(previousUrl))) {
        return previousUrl;
      }
      rethrow;
    }
  }

  @override
  Future<int> addCar(Car car) async {
    final String uid = _uid;
    final String? imageUrl = await _resolveImageUrl(car.imagePath);
    final Map<String, dynamic> row = await _client
        .from('cars')
        .insert(_toRow(car, ownerUid: uid, imageUrl: imageUrl))
        .select()
        .single();
    final Car saved = _fromRow(Map<String, dynamic>.from(row));
    await _mirrorLocal(saved);
    return saved.id!;
  }

  @override
  Future<List<Car>> getCars() async {
    final String uid = _uid;
    final List<dynamic> data = await _client
        .from('cars')
        .select()
        .eq('owner_uid', uid)
        .order('created_at', ascending: false);
    final List<Car> cars = data
        .map((dynamic e) => _fromRow(Map<String, dynamic>.from(e as Map)))
        .toList();
    for (final Car car in cars) {
      await _mirrorLocal(car);
    }
    return cars;
  }

  @override
  Future<Car?> getCar(int id) async {
    final String uid = _uid;
    final List<dynamic> data = await _client
        .from('cars')
        .select()
        .eq('id', id)
        .eq('owner_uid', uid)
        .limit(1);
    if (data.isEmpty) return null;
    final Car car = _fromRow(Map<String, dynamic>.from(data.first as Map));
    await _mirrorLocal(car);
    return car;
  }

  @override
  Future<int> updateCar(Car car) async {
    if (car.id == null) {
      throw ArgumentError('Güncellenecek aracın id alanı null olamaz.');
    }
    final String uid = _uid;
    final Car? previous = await getCar(car.id!);
    final String? imageUrl = await _resolveImageUrl(
      car.imagePath,
      previousUrl: previous?.imagePath,
    );
    final Map<String, dynamic> row = await _client
        .from('cars')
        .update(_toRow(car, ownerUid: uid, imageUrl: imageUrl))
        .eq('id', car.id!)
        .eq('owner_uid', uid)
        .select()
        .single();
    final Car saved = _fromRow(Map<String, dynamic>.from(row));
    await _mirrorLocal(saved);
    return 1;
  }

  @override
  Future<int> deleteCar(int id) async {
    final String uid = _uid;
    final Car? existing = await getCar(id);
    await _deleteRemoteIfOurs(existing?.imagePath);
    await _client.from('cars').delete().eq('id', id).eq('owner_uid', uid);
    await _db.deleteCar(id);
    return 1;
  }
}

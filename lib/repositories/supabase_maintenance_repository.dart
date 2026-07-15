import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/maintenance_item_catalog.dart';
import '../models/maintenance_model.dart';
import '../services/database_helper.dart';
import 'maintenance_repository.dart';

const String kMaintenanceDocsBucket = 'maintenance-docs';

/// Kullanıcı bakım kayıtları → Supabase `maintenance` (+ SQLite yansıması).
class SupabaseMaintenanceRepository implements MaintenanceRepository {
  SupabaseMaintenanceRepository({
    SupabaseClient? client,
    DatabaseHelper? db,
  })  : _client = client ?? Supabase.instance.client,
        _db = db ?? DatabaseHelper.instance;

  final SupabaseClient _client;
  final DatabaseHelper _db;

  String get _uid {
    final String? id = _client.auth.currentUser?.id;
    if (id == null || id.isEmpty) {
      throw StateError('Bakım kaydı için giriş yapmış olmalısınız.');
    }
    return id;
  }

  static bool isRemoteUrl(String? value) {
    if (value == null || value.isEmpty) return false;
    return value.startsWith('http://') || value.startsWith('https://');
  }

  static String _dateOnly(DateTime d) {
    final DateTime local = DateTime(d.year, d.month, d.day);
    final String m = local.month.toString().padLeft(2, '0');
    final String day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$m-$day';
  }

  static DateTime _parseDate(dynamic value) {
    if (value is DateTime) {
      return DateTime(value.year, value.month, value.day);
    }
    final String s = '$value';
    final DateTime parsed = DateTime.parse(s);
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  static List<String> _kalemlerFromRow(dynamic raw) {
    if (raw == null) return <String>[];
    if (raw is List) {
      return raw
          .map((dynamic e) => '$e')
          .where((String s) => s.isNotEmpty)
          .toList();
    }
    if (raw is String) {
      return MaintenanceItemCatalog.decodeIds(raw);
    }
    return <String>[];
  }

  Map<String, dynamic> _toRow(
    Maintenance m, {
    required String ownerUid,
    required String? attachmentUrl,
  }) {
    return <String, dynamic>{
      'car_id': m.carId,
      'owner_uid': ownerUid,
      'islem': m.islem,
      'tarih': _dateOnly(m.tarih),
      'km': m.km,
      'maliyet': m.maliyet,
      'servis_adi': m.servisAdi,
      'notlar': m.notlar,
      'bakim_kalemleri': m.bakimKalemleri,
      'attachment_url': attachmentUrl,
      'resmi_servis': m.resmiServis,
      'garanti_kapsaminda': m.garantiKapsaminda,
      'fatura_alindi': m.faturaAlindi,
      'sigorta_karsiladi': m.sigortaKarsiladi,
    };
  }

  Maintenance _fromRow(Map<String, dynamic> row) {
    final dynamic maliyetRaw = row['maliyet'];
    final double maliyet = maliyetRaw is num
        ? maliyetRaw.toDouble()
        : double.tryParse('$maliyetRaw') ?? 0;
    return Maintenance(
      id: (row['id'] as num?)?.toInt(),
      carId: (row['car_id'] as num).toInt(),
      islem: row['islem'] as String? ?? '',
      tarih: _parseDate(row['tarih']),
      km: (row['km'] as num?)?.toInt() ?? 0,
      maliyet: maliyet,
      servisAdi: row['servis_adi'] as String?,
      notlar: row['notlar'] as String?,
      bakimKalemleri: _kalemlerFromRow(row['bakim_kalemleri']),
      attachmentUrl: row['attachment_url'] as String?,
      resmiServis: row['resmi_servis'] as bool? ?? false,
      garantiKapsaminda: row['garanti_kapsaminda'] as bool? ?? false,
      faturaAlindi: row['fatura_alindi'] as bool? ?? false,
      sigortaKarsiladi: row['sigorta_karsiladi'] as bool? ?? false,
    );
  }

  Future<void> _mirrorLocal(Maintenance m) async {
    if (m.id == null) return;
    final List<Maintenance> existing =
        (await _db.getMaintenanceByCarId(m.carId))
            .where((Maintenance x) => x.id == m.id)
            .toList();
    if (existing.isEmpty) {
      await _db.insertMaintenanceWithId(m);
    } else {
      await _db.updateMaintenance(m);
    }
  }

  String? _storagePathFromUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    final String marker =
        '/storage/v1/object/public/$kMaintenanceDocsBucket/';
    final int idx = url.indexOf(marker);
    if (idx == -1) return null;
    return Uri.decodeComponent(url.substring(idx + marker.length));
  }

  Future<void> _deleteRemoteIfOurs(String? url) async {
    final String? path = _storagePathFromUrl(url);
    if (path == null) return;
    try {
      await _client.storage.from(kMaintenanceDocsBucket).remove(<String>[path]);
    } catch (_) {}
  }

  Future<String> _uploadLocalFile(String localPath) async {
    final File file = File(localPath);
    if (!await file.exists()) {
      throw StateError('Ek dosyası bulunamadı.');
    }
    final Uint8List bytes = await file.readAsBytes();
    final String extRaw = p.extension(localPath).replaceFirst('.', '');
    final String ext = extRaw.isEmpty ? 'jpg' : extRaw.toLowerCase();
    final String path =
        '$_uid/maint_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final String contentType = switch (ext) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'heic' => 'image/heic',
      'pdf' => 'application/pdf',
      _ => 'image/jpeg',
    };
    await _client.storage.from(kMaintenanceDocsBucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: contentType,
          ),
        );
    return _client.storage.from(kMaintenanceDocsBucket).getPublicUrl(path);
  }

  /// Remote URL keep; local path upload; on clear/update delete old remote if ours.
  Future<String?> _resolveAttachmentUrl(
    String? attachmentUrl, {
    String? previousUrl,
  }) async {
    if (attachmentUrl == null || attachmentUrl.trim().isEmpty) {
      if (previousUrl != null && previousUrl.isNotEmpty) {
        await _deleteRemoteIfOurs(previousUrl);
      }
      return null;
    }
    if (isRemoteUrl(attachmentUrl)) {
      return attachmentUrl;
    }
    final String url = await _uploadLocalFile(attachmentUrl);
    if (previousUrl != null &&
        previousUrl.isNotEmpty &&
        previousUrl != url) {
      await _deleteRemoteIfOurs(previousUrl);
    }
    return url;
  }

  @override
  Future<int> addMaintenance(Maintenance log) async {
    final String uid = _uid;
    final String? attachmentUrl =
        await _resolveAttachmentUrl(log.attachmentUrl);
    final Map<String, dynamic> row = await _client
        .from('maintenance')
        .insert(_toRow(log, ownerUid: uid, attachmentUrl: attachmentUrl))
        .select()
        .single();
    final Maintenance saved = _fromRow(Map<String, dynamic>.from(row));
    await _mirrorLocal(saved);
    return saved.id!;
  }

  @override
  Future<int> updateMaintenance(Maintenance log) async {
    if (log.id == null) {
      throw ArgumentError('updateMaintenance requires id');
    }
    final String uid = _uid;
    final List<Maintenance> existingLocal =
        (await _db.getMaintenanceByCarId(log.carId))
            .where((Maintenance x) => x.id == log.id)
            .toList();
    String? previousUrl = existingLocal.isEmpty
        ? null
        : existingLocal.first.attachmentUrl;
    if (previousUrl == null) {
      try {
        final Map<String, dynamic> prev = await _client
            .from('maintenance')
            .select('attachment_url')
            .eq('id', log.id!)
            .eq('owner_uid', uid)
            .single();
        previousUrl = prev['attachment_url'] as String?;
      } catch (_) {}
    }
    final String? attachmentUrl = await _resolveAttachmentUrl(
      log.attachmentUrl,
      previousUrl: previousUrl,
    );
    final Map<String, dynamic> row = await _client
        .from('maintenance')
        .update(_toRow(log, ownerUid: uid, attachmentUrl: attachmentUrl))
        .eq('id', log.id!)
        .eq('owner_uid', uid)
        .select()
        .single();
    final Maintenance saved = _fromRow(Map<String, dynamic>.from(row));
    await _mirrorLocal(saved);
    return 1;
  }

  @override
  Future<List<Maintenance>> getMaintenanceByCarId(int carId) async {
    final String uid = _uid;
    final List<dynamic> data = await _client
        .from('maintenance')
        .select()
        .eq('owner_uid', uid)
        .eq('car_id', carId)
        .order('tarih', ascending: false);
    final List<Maintenance> list = data
        .map((dynamic e) => _fromRow(Map<String, dynamic>.from(e as Map)))
        .toList();
    for (final Maintenance m in list) {
      await _mirrorLocal(m);
    }
    return list;
  }

  @override
  Future<int> deleteMaintenance(int id) async {
    final String uid = _uid;
    try {
      final Map<String, dynamic>? prev = await _client
          .from('maintenance')
          .select('attachment_url')
          .eq('id', id)
          .eq('owner_uid', uid)
          .maybeSingle();
      if (prev != null) {
        await _deleteRemoteIfOurs(prev['attachment_url'] as String?);
      }
    } catch (_) {}
    await _client
        .from('maintenance')
        .delete()
        .eq('id', id)
        .eq('owner_uid', uid);
    await _db.deleteMaintenance(id);
    return 1;
  }
}

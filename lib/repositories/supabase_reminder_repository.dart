import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/reminder_model.dart';
import '../services/database_helper.dart';
import 'reminder_repository.dart';

/// Kullanıcı hatırlatıcıları → Supabase `reminders` (+ SQLite yansıması).
class SupabaseReminderRepository implements ReminderRepository {
  SupabaseReminderRepository({
    SupabaseClient? client,
    DatabaseHelper? db,
  })  : _client = client ?? Supabase.instance.client,
        _db = db ?? DatabaseHelper.instance;

  final SupabaseClient _client;
  final DatabaseHelper _db;

  String get _uid {
    final String? id = _client.auth.currentUser?.id;
    if (id == null || id.isEmpty) {
      throw StateError('Hatırlatıcı için giriş yapmış olmalısınız.');
    }
    return id;
  }

  static String _dateOnly(DateTime d) {
    final DateTime local = DateTime(d.year, d.month, d.day);
    final String m = local.month.toString().padLeft(2, '0');
    final String day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$m-$day';
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) {
      return DateTime(value.year, value.month, value.day);
    }
    final String s = '$value'.trim();
    if (s.isEmpty || s == 'null') return null;
    final DateTime parsed = DateTime.parse(s);
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  Map<String, dynamic> _toRow(Reminder r, {required String ownerUid}) {
    return <String, dynamic>{
      'car_id': r.carId,
      'owner_uid': ownerUid,
      'tur': r.tur.name,
      'bitis_tarihi':
          r.bitisTarihi == null ? null : _dateOnly(r.bitisTarihi!),
      'target_km': r.targetKm,
      'hatirlatma_yapildi': r.hatirlatmaYapildiMi,
    };
  }

  Reminder _fromRow(Map<String, dynamic> row) {
    return Reminder(
      id: (row['id'] as num?)?.toInt(),
      carId: (row['car_id'] as num).toInt(),
      tur: ReminderType.fromString(row['tur'] as String? ?? 'sigorta'),
      bitisTarihi: _parseDate(row['bitis_tarihi']),
      targetKm: (row['target_km'] as num?)?.toInt(),
      hatirlatmaYapildiMi: row['hatirlatma_yapildi'] as bool? ?? false,
    );
  }

  Future<void> _mirrorLocal(Reminder r) async {
    if (r.id == null) return;
    final List<Reminder> existing =
        (await _db.getRemindersByCarId(r.carId))
            .where((Reminder x) => x.id == r.id)
            .toList();
    if (existing.isEmpty) {
      await _db.insertReminderWithId(r);
    } else {
      await _db.updateReminder(r);
    }
  }

  @override
  Future<int> addReminder(Reminder reminder) async {
    final String uid = _uid;
    final Map<String, dynamic> row = await _client
        .from('reminders')
        .insert(_toRow(reminder, ownerUid: uid))
        .select()
        .single();
    final Reminder saved = _fromRow(Map<String, dynamic>.from(row));
    await _mirrorLocal(saved);
    return saved.id!;
  }

  @override
  Future<List<Reminder>> getAllReminders() async {
    final String uid = _uid;
    final List<dynamic> data = await _client
        .from('reminders')
        .select()
        .eq('owner_uid', uid)
        .order('bitis_tarihi', ascending: true, nullsFirst: false);
    final List<Reminder> list = data
        .map((dynamic e) => _fromRow(Map<String, dynamic>.from(e as Map)))
        .toList();
    for (final Reminder r in list) {
      await _mirrorLocal(r);
    }
    return list;
  }

  @override
  Future<List<Reminder>> getRemindersByCarId(int carId) async {
    final String uid = _uid;
    final List<dynamic> data = await _client
        .from('reminders')
        .select()
        .eq('owner_uid', uid)
        .eq('car_id', carId)
        .order('bitis_tarihi', ascending: true, nullsFirst: false);
    final List<Reminder> list = data
        .map((dynamic e) => _fromRow(Map<String, dynamic>.from(e as Map)))
        .toList();
    for (final Reminder r in list) {
      await _mirrorLocal(r);
    }
    return list;
  }

  @override
  Future<int> updateReminder(Reminder reminder) async {
    if (reminder.id == null) {
      throw ArgumentError('Güncellenecek hatırlatıcının id alanı null olamaz.');
    }
    final String uid = _uid;
    final Map<String, dynamic> row = await _client
        .from('reminders')
        .update(_toRow(reminder, ownerUid: uid))
        .eq('id', reminder.id!)
        .eq('owner_uid', uid)
        .select()
        .single();
    final Reminder saved = _fromRow(Map<String, dynamic>.from(row));
    await _mirrorLocal(saved);
    return 1;
  }

  @override
  Future<int> deleteReminder(int id) async {
    final String uid = _uid;
    await _client
        .from('reminders')
        .delete()
        .eq('id', id)
        .eq('owner_uid', uid);
    await _db.deleteReminder(id);
    return 1;
  }
}

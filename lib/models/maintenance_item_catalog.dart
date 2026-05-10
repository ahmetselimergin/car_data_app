import 'dart:convert';

/// Önceden tanımlı bakım kalemleri (checkbox listesi); `id` veritabanında saklanır.
class MaintenanceItemCatalog {
  MaintenanceItemCatalog._();

  static const List<(String id, String label)> entries = <(String, String)>[
    ('yag_degisimi', 'Yağ değişimi'),
    ('yag_filtresi', 'Yağ filtresi'),
    ('hava_filtresi', 'Hava filtresi'),
    ('polen_filtresi', 'Polen filtresi'),
    ('yakit_filtresi', 'Yakıt filtresi'),
    ('su_filtresi', 'Su filtresi (dizel)'),
    ('on_fren_balata', 'Ön fren balatası'),
    ('arka_fren_balata', 'Arka fren balatası'),
    ('fren_disk', 'Fren diski'),
    ('fren_hidrolik', 'Fren hidroliği'),
    ('rot_baslari', 'Rot başları'),
    ('rotil', 'Rotil'),
    ('amortisor', 'Amortisör'),
    ('lastik', 'Lastik değişimi / rotasyon'),
    ('jant_denge', 'Balans ayarı'),
    ('aku', 'Akü'),
    ('buji', 'Buji / ateşleme'),
    ('triger_set', 'Triger seti / zincir'),
    ('debriyaj', 'Debriyaj'),
    ('sogutma', 'Soğutma suyu / hortum'),
    ('klima', 'Klima gazı / bakım'),
    ('egzoz', 'Egzoz / susturucu'),
    ('silecek', 'Silecek'),
    ('far_ampul', 'Far / sinyal ampulü'),
    ('genel_kontrol', 'Genel kontrol'),
  ];

  static String? labelForId(String id) {
    for (final (String i, String l) in entries) {
      if (i == id) return l;
    }
    return null;
  }

  /// Katalog sırasına göre etiketler; bilinmeyen id'ler sonda eklenir.
  static List<String> labelsInCatalogOrder(Iterable<String> ids) {
    final Set<String> remaining = ids.toSet();
    final List<String> ordered = <String>[];
    for (final (String id, String label) in entries) {
      if (remaining.remove(id)) ordered.add(label);
    }
    for (final String id in remaining) {
      ordered.add(labelForId(id) ?? id);
    }
    return ordered;
  }

  static String joinLabels(Iterable<String> ids) =>
      labelsInCatalogOrder(ids).join(', ');

  /// Kayıt için id sırası (katalog sırası + bilinmeyenler).
  static List<String> idsInCatalogOrder(Set<String> ids) {
    final Set<String> remaining = Set<String>.from(ids);
    final List<String> ordered = <String>[];
    for (final (String id, _) in entries) {
      if (remaining.remove(id)) ordered.add(id);
    }
    ordered.addAll(remaining);
    return ordered;
  }

  static List<String> decodeIds(String? jsonStr) {
    if (jsonStr == null || jsonStr.isEmpty) return <String>[];
    try {
      final Object? decoded = jsonDecode(jsonStr);
      if (decoded is List<dynamic>) {
        return decoded
            .map((dynamic e) => '$e')
            .where((String s) => s.isNotEmpty)
            .toList();
      }
    } catch (_) {}
    return <String>[];
  }

  static String? encodeIds(List<String> ids) {
    if (ids.isEmpty) return null;
    return jsonEncode(ids);
  }
}

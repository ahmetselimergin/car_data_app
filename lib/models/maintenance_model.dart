import 'maintenance_item_catalog.dart';

class Maintenance {
  final int? id;
  final int carId;
  final String islem;
  final DateTime tarih;
  final int km;
  final double maliyet;

  /// Servis / ustanın adı (isteğe bağlı).
  final String? servisAdi;

  /// Serbest notlar (eski kayıtlar; yeni formda kullanılmıyor).
  final String? notlar;

  /// Checkbox ile seçilen bakım kalemi id'leri (JSON olarak saklanır).
  final List<String> bakimKalemleri;

  /// Resmi yetkili serviste yapıldı.
  final bool resmiServis;

  /// Garanti kapsamındaydı (maliyet 0 olabilir).
  final bool garantiKapsaminda;

  /// Fatura veya fiş alındı.
  final bool faturaAlindi;

  /// Sigorta / kasko karşıladı (maliyet 0 veya muafiyat olabilir).
  final bool sigortaKarsiladi;

  const Maintenance({
    this.id,
    required this.carId,
    required this.islem,
    required this.tarih,
    required this.km,
    required this.maliyet,
    this.servisAdi,
    this.notlar,
    this.bakimKalemleri = const <String>[],
    this.resmiServis = false,
    this.garantiKapsaminda = false,
    this.faturaAlindi = false,
    this.sigortaKarsiladi = false,
  });

  bool get hasDetailFlags =>
      resmiServis ||
      garantiKapsaminda ||
      faturaAlindi ||
      sigortaKarsiladi;

  Maintenance copyWith({
    int? id,
    int? carId,
    String? islem,
    DateTime? tarih,
    int? km,
    double? maliyet,
    String? servisAdi,
    String? notlar,
    List<String>? bakimKalemleri,
    bool? resmiServis,
    bool? garantiKapsaminda,
    bool? faturaAlindi,
    bool? sigortaKarsiladi,
  }) {
    return Maintenance(
      id: id ?? this.id,
      carId: carId ?? this.carId,
      islem: islem ?? this.islem,
      tarih: tarih ?? this.tarih,
      km: km ?? this.km,
      maliyet: maliyet ?? this.maliyet,
      servisAdi: servisAdi ?? this.servisAdi,
      notlar: notlar ?? this.notlar,
      bakimKalemleri: bakimKalemleri ?? this.bakimKalemleri,
      resmiServis: resmiServis ?? this.resmiServis,
      garantiKapsaminda: garantiKapsaminda ?? this.garantiKapsaminda,
      faturaAlindi: faturaAlindi ?? this.faturaAlindi,
      sigortaKarsiladi: sigortaKarsiladi ?? this.sigortaKarsiladi,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'carId': carId,
      'islem': islem,
      'tarih': tarih.toIso8601String(),
      'km': km,
      'maliyet': maliyet,
      'servisAdi': servisAdi,
      'notlar': notlar,
      'bakimKalemleri': MaintenanceItemCatalog.encodeIds(bakimKalemleri),
      'resmiServis': resmiServis ? 1 : 0,
      'garantiKapsaminda': garantiKapsaminda ? 1 : 0,
      'faturaAlindi': faturaAlindi ? 1 : 0,
      'sigortaKarsiladi': sigortaKarsiladi ? 1 : 0,
    };
  }

  factory Maintenance.fromMap(Map<String, dynamic> map) {
    return Maintenance(
      id: map['id'] as int?,
      carId: map['carId'] as int,
      islem: map['islem'] as String,
      tarih: DateTime.parse(map['tarih'] as String),
      km: map['km'] as int,
      maliyet: (map['maliyet'] as num).toDouble(),
      servisAdi: map['servisAdi'] as String?,
      notlar: map['notlar'] as String?,
      bakimKalemleri: MaintenanceItemCatalog.decodeIds(
        map['bakimKalemleri'] as String?,
      ),
      resmiServis: (map['resmiServis'] as int?) == 1,
      garantiKapsaminda: (map['garantiKapsaminda'] as int?) == 1,
      faturaAlindi: (map['faturaAlindi'] as int?) == 1,
      sigortaKarsiladi: (map['sigortaKarsiladi'] as int?) == 1,
    );
  }

  @override
  String toString() =>
      'Maintenance(id: $id, carId: $carId, islem: $islem, '
      'tarih: $tarih, km: $km, maliyet: $maliyet)';
}

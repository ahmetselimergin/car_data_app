class Maintenance {
  final int? id;
  final int carId;
  final String islem;
  final DateTime tarih;
  final int km;
  final double maliyet;

  const Maintenance({
    this.id,
    required this.carId,
    required this.islem,
    required this.tarih,
    required this.km,
    required this.maliyet,
  });

  Maintenance copyWith({
    int? id,
    int? carId,
    String? islem,
    DateTime? tarih,
    int? km,
    double? maliyet,
  }) {
    return Maintenance(
      id: id ?? this.id,
      carId: carId ?? this.carId,
      islem: islem ?? this.islem,
      tarih: tarih ?? this.tarih,
      km: km ?? this.km,
      maliyet: maliyet ?? this.maliyet,
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
    );
  }

  @override
  String toString() =>
      'Maintenance(id: $id, carId: $carId, islem: $islem, '
      'tarih: $tarih, km: $km, maliyet: $maliyet)';
}

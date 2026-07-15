enum ReminderType {
  sigorta,
  kasko,
  muayene,
  egzoz,
  /// Kilometre tabanlı bakım hatırlatıcısı (yağ / periyodik).
  bakimKm;

  static ReminderType fromString(String value) {
    return ReminderType.values.firstWhere(
      (ReminderType t) => t.name == value,
      orElse: () => ReminderType.sigorta,
    );
  }

  bool get isKmBased => this == ReminderType.bakimKm;
}

class Reminder {
  final int? id;
  final int carId;
  final ReminderType tur;
  /// Tarih tabanlı türler için zorunlu; km türünde null olabilir.
  final DateTime? bitisTarihi;
  /// Km tabanlı hedef odometre (araç km'si buna ulaşınca hatırlat).
  final int? targetKm;
  final bool hatirlatmaYapildiMi;

  const Reminder({
    this.id,
    required this.carId,
    required this.tur,
    this.bitisTarihi,
    this.targetKm,
    this.hatirlatmaYapildiMi = false,
  });

  bool get isKmBased => tur.isKmBased || targetKm != null;

  Reminder copyWith({
    int? id,
    int? carId,
    ReminderType? tur,
    DateTime? bitisTarihi,
    int? targetKm,
    bool? hatirlatmaYapildiMi,
    bool clearBitisTarihi = false,
    bool clearTargetKm = false,
  }) {
    return Reminder(
      id: id ?? this.id,
      carId: carId ?? this.carId,
      tur: tur ?? this.tur,
      bitisTarihi:
          clearBitisTarihi ? null : (bitisTarihi ?? this.bitisTarihi),
      targetKm: clearTargetKm ? null : (targetKm ?? this.targetKm),
      hatirlatmaYapildiMi: hatirlatmaYapildiMi ?? this.hatirlatmaYapildiMi,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'carId': carId,
      'tur': tur.name,
      'bitisTarihi': bitisTarihi?.toIso8601String(),
      'targetKm': targetKm,
      'hatirlatmaYapildiMi': hatirlatmaYapildiMi ? 1 : 0,
    };
  }

  factory Reminder.fromMap(Map<String, dynamic> map) {
    final String? bitisRaw = map['bitisTarihi'] as String?;
    return Reminder(
      id: map['id'] as int?,
      carId: map['carId'] as int,
      tur: ReminderType.fromString(map['tur'] as String),
      bitisTarihi: (bitisRaw == null || bitisRaw.isEmpty)
          ? null
          : DateTime.parse(bitisRaw),
      targetKm: (map['targetKm'] as num?)?.toInt(),
      hatirlatmaYapildiMi: (map['hatirlatmaYapildiMi'] as int?) == 1,
    );
  }

  @override
  String toString() =>
      'Reminder(id: $id, carId: $carId, tur: $tur, '
      'bitisTarihi: $bitisTarihi, targetKm: $targetKm, '
      'hatirlatmaYapildiMi: $hatirlatmaYapildiMi)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Reminder &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          carId == other.carId &&
          tur == other.tur &&
          bitisTarihi == other.bitisTarihi &&
          targetKm == other.targetKm &&
          hatirlatmaYapildiMi == other.hatirlatmaYapildiMi;

  @override
  int get hashCode => Object.hash(
        id,
        carId,
        tur,
        bitisTarihi,
        targetKm,
        hatirlatmaYapildiMi,
      );
}

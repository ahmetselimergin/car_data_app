enum ReminderType {
  sigorta,
  kasko,
  muayene,
  egzoz;

  static ReminderType fromString(String value) {
    return ReminderType.values.firstWhere(
      (ReminderType t) => t.name == value,
      orElse: () => ReminderType.sigorta,
    );
  }
}

class Reminder {
  final int? id;
  final int carId;
  final ReminderType tur;
  final DateTime bitisTarihi;
  final bool hatirlatmaYapildiMi;

  const Reminder({
    this.id,
    required this.carId,
    required this.tur,
    required this.bitisTarihi,
    this.hatirlatmaYapildiMi = false,
  });

  Reminder copyWith({
    int? id,
    int? carId,
    ReminderType? tur,
    DateTime? bitisTarihi,
    bool? hatirlatmaYapildiMi,
  }) {
    return Reminder(
      id: id ?? this.id,
      carId: carId ?? this.carId,
      tur: tur ?? this.tur,
      bitisTarihi: bitisTarihi ?? this.bitisTarihi,
      hatirlatmaYapildiMi: hatirlatmaYapildiMi ?? this.hatirlatmaYapildiMi,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'carId': carId,
      'tur': tur.name,
      'bitisTarihi': bitisTarihi.toIso8601String(),
      'hatirlatmaYapildiMi': hatirlatmaYapildiMi ? 1 : 0,
    };
  }

  factory Reminder.fromMap(Map<String, dynamic> map) {
    return Reminder(
      id: map['id'] as int?,
      carId: map['carId'] as int,
      tur: ReminderType.fromString(map['tur'] as String),
      bitisTarihi: DateTime.parse(map['bitisTarihi'] as String),
      hatirlatmaYapildiMi: (map['hatirlatmaYapildiMi'] as int) == 1,
    );
  }

  @override
  String toString() =>
      'Reminder(id: $id, carId: $carId, tur: $tur, '
      'bitisTarihi: $bitisTarihi, hatirlatmaYapildiMi: $hatirlatmaYapildiMi)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Reminder &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          carId == other.carId &&
          tur == other.tur &&
          bitisTarihi == other.bitisTarihi &&
          hatirlatmaYapildiMi == other.hatirlatmaYapildiMi;

  @override
  int get hashCode =>
      Object.hash(id, carId, tur, bitisTarihi, hatirlatmaYapildiMi);
}

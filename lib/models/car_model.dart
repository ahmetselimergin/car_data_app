class Car {
  final int? id;
  final String plaka;
  final String marka;
  final String model;
  final int yil;
  final String? imagePath;

  /// Hero kartının arka plan rengi (ARGB int olarak saklanır).
  /// Null ise UI tarafında car id'sine göre paletten otomatik seçilir.
  final int? cardColor;

  /// Son bilinen kilometre (formda girilir; bakım kayıtlarıyla birlikte gösterimde max alınır).
  final int km;

  /// Şanzıman tipi (örn. Manuel, Otomatik).
  final String? transmission;

  /// Yakıt tipi (örn. Benzin, Dizel).
  final String? fuelType;

  const Car({
    this.id,
    required this.plaka,
    required this.marka,
    required this.model,
    required this.yil,
    this.imagePath,
    this.cardColor,
    this.km = 0,
    this.transmission,
    this.fuelType,
  });

  Car copyWith({
    int? id,
    String? plaka,
    String? marka,
    String? model,
    int? yil,
    String? imagePath,
    int? cardColor,
    int? km,
    String? transmission,
    String? fuelType,
    bool clearImage = false,
    bool clearCardColor = false,
    bool clearTransmission = false,
    bool clearFuelType = false,
  }) {
    return Car(
      id: id ?? this.id,
      plaka: plaka ?? this.plaka,
      marka: marka ?? this.marka,
      model: model ?? this.model,
      yil: yil ?? this.yil,
      imagePath: clearImage ? null : (imagePath ?? this.imagePath),
      cardColor: clearCardColor ? null : (cardColor ?? this.cardColor),
      km: km ?? this.km,
      transmission: clearTransmission
          ? null
          : (transmission ?? this.transmission),
      fuelType: clearFuelType ? null : (fuelType ?? this.fuelType),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'plaka': plaka,
      'marka': marka,
      'model': model,
      'yil': yil,
      'imagePath': imagePath,
      'cardColor': cardColor,
      'km': km,
      'transmission': transmission,
      'fuelType': fuelType,
    };
  }

  factory Car.fromMap(Map<String, dynamic> map) {
    return Car(
      id: map['id'] as int?,
      plaka: map['plaka'] as String,
      marka: map['marka'] as String,
      model: map['model'] as String,
      yil: map['yil'] as int,
      imagePath: map['imagePath'] as String?,
      cardColor: map['cardColor'] as int?,
      km: (map['km'] as num?)?.toInt() ?? 0,
      transmission: map['transmission'] as String?,
      fuelType: map['fuelType'] as String?,
    );
  }

  @override
  String toString() =>
      'Car(id: $id, plaka: $plaka, marka: $marka, model: $model, yil: $yil, '
      'imagePath: $imagePath, cardColor: $cardColor, km: $km, '
      'transmission: $transmission, fuelType: $fuelType)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Car &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          plaka == other.plaka &&
          marka == other.marka &&
          model == other.model &&
          yil == other.yil &&
          imagePath == other.imagePath &&
          cardColor == other.cardColor &&
          km == other.km &&
          transmission == other.transmission &&
          fuelType == other.fuelType;

  @override
  int get hashCode => Object.hash(
        id,
        plaka,
        marka,
        model,
        yil,
        imagePath,
        cardColor,
        km,
        transmission,
        fuelType,
      );
}

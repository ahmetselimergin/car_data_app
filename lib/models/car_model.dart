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

  const Car({
    this.id,
    required this.plaka,
    required this.marka,
    required this.model,
    required this.yil,
    this.imagePath,
    this.cardColor,
  });

  Car copyWith({
    int? id,
    String? plaka,
    String? marka,
    String? model,
    int? yil,
    String? imagePath,
    int? cardColor,
    bool clearImage = false,
    bool clearCardColor = false,
  }) {
    return Car(
      id: id ?? this.id,
      plaka: plaka ?? this.plaka,
      marka: marka ?? this.marka,
      model: model ?? this.model,
      yil: yil ?? this.yil,
      imagePath: clearImage ? null : (imagePath ?? this.imagePath),
      cardColor: clearCardColor ? null : (cardColor ?? this.cardColor),
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
    );
  }

  @override
  String toString() =>
      'Car(id: $id, plaka: $plaka, marka: $marka, model: $model, yil: $yil, '
      'imagePath: $imagePath, cardColor: $cardColor)';

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
          cardColor == other.cardColor;

  @override
  int get hashCode =>
      Object.hash(id, plaka, marka, model, yil, imagePath, cardColor);
}

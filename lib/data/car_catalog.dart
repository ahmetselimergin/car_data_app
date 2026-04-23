/// Statik araç markası ve modeli kataloğu.
/// Türkiye pazarında yaygın olan markalar ve modeller.
class CarCatalog {
  CarCatalog._();

  static const Map<String, List<String>> brands = <String, List<String>>{
    'Audi': <String>['A1', 'A3', 'A4', 'A5', 'A6', 'A7', 'A8', 'Q2', 'Q3', 'Q5', 'Q7', 'Q8', 'e-tron'],
    'BMW': <String>['1 Serisi', '2 Serisi', '3 Serisi', '4 Serisi', '5 Serisi', '7 Serisi', 'X1', 'X2', 'X3', 'X4', 'X5', 'X6', 'M3', 'M4', 'i4', 'iX'],
    'Chery': <String>['Tiggo 7 Pro', 'Tiggo 8 Pro', 'Omoda 5'],
    'Citroen': <String>['C3', 'C4', 'C5 Aircross', 'Berlingo'],
    'Cupra': <String>['Formentor', 'Leon', 'Born'],
    'Dacia': <String>['Sandero', 'Duster', 'Logan', 'Jogger', 'Spring'],
    'DS': <String>['DS 3', 'DS 4', 'DS 7'],
    'Fiat': <String>['Egea', 'Panda', '500', '500X', '500L', 'Doblo', 'Tipo'],
    'Ford': <String>['Fiesta', 'Focus', 'Mondeo', 'Kuga', 'Puma', 'EcoSport', 'Tourneo Connect', 'Transit', 'Mustang', 'Ranger'],
    'Honda': <String>['Civic', 'City', 'Jazz', 'CR-V', 'HR-V'],
    'Hyundai': <String>['i10', 'i20', 'i30', 'Accent', 'Elantra', 'Tucson', 'Santa Fe', 'Bayon', 'Kona', 'Ioniq 5'],
    'Jeep': <String>['Renegade', 'Compass', 'Wrangler', 'Grand Cherokee'],
    'Kia': <String>['Picanto', 'Rio', 'Ceed', 'Sportage', 'Sorento', 'Stonic', 'Niro', 'EV6'],
    'Land Rover': <String>['Defender', 'Discovery', 'Range Rover', 'Range Rover Sport', 'Range Rover Evoque'],
    'Mazda': <String>['2', '3', '6', 'CX-3', 'CX-5', 'CX-30', 'MX-5'],
    'Mercedes-Benz': <String>['A-Serisi', 'B-Serisi', 'C-Serisi', 'E-Serisi', 'S-Serisi', 'CLA', 'CLS', 'GLA', 'GLB', 'GLC', 'GLE', 'GLS', 'EQA', 'EQC', 'EQS', 'Vito'],
    'MG': <String>['MG3', 'MG4', 'ZS', 'HS'],
    'Mini': <String>['Cooper', 'Cooper S', 'Countryman', 'Clubman'],
    'Mitsubishi': <String>['ASX', 'Eclipse Cross', 'Outlander', 'L200'],
    'Nissan': <String>['Micra', 'Juke', 'Qashqai', 'X-Trail', 'Navara', 'Leaf'],
    'Opel': <String>['Corsa', 'Astra', 'Insignia', 'Crossland', 'Mokka', 'Grandland'],
    'Peugeot': <String>['208', '301', '308', '2008', '3008', '5008', 'Partner', 'Rifter'],
    'Porsche': <String>['911', 'Cayenne', 'Macan', 'Panamera', 'Taycan'],
    'Renault': <String>['Clio', 'Megane', 'Symbol', 'Captur', 'Kadjar', 'Talisman', 'Taliant', 'Austral', 'Kangoo', 'Trafic', 'Zoe'],
    'Seat': <String>['Ibiza', 'Leon', 'Arona', 'Ateca', 'Tarraco'],
    'Skoda': <String>['Fabia', 'Scala', 'Octavia', 'Superb', 'Kamiq', 'Karoq', 'Kodiaq', 'Enyaq'],
    'Subaru': <String>['Impreza', 'Forester', 'Outback', 'XV'],
    'Suzuki': <String>['Swift', 'Vitara', 'S-Cross', 'Jimny'],
    'Tesla': <String>['Model 3', 'Model Y', 'Model S', 'Model X'],
    'Togg': <String>['T10X', 'T10F'],
    'Toyota': <String>['Yaris', 'Corolla', 'Auris', 'Camry', 'C-HR', 'RAV4', 'Land Cruiser', 'Hilux', 'Proace', 'bZ4X'],
    'Volkswagen': <String>['Polo', 'Golf', 'Jetta', 'Passat', 'Arteon', 'T-Cross', 'Taigo', 'T-Roc', 'Tiguan', 'Touareg', 'Caddy', 'Transporter', 'ID.3', 'ID.4'],
    'Volvo': <String>['S60', 'S90', 'V60', 'XC40', 'XC60', 'XC90', 'EX30'],
  };

  /// Sıralı marka listesi.
  static List<String> get brandNames => brands.keys.toList()..sort();

  /// Verilen markaya ait sıralı model listesi.
  static List<String> modelsFor(String brand) {
    final List<String> list = List<String>.from(brands[brand] ?? const <String>[]);
    list.sort();
    return list;
  }

  /// Yıl seçenekleri (yeni → eski).
  static List<int> yearOptions({int minYear = 1980}) {
    final int now = DateTime.now().year;
    return <int>[for (int y = now + 1; y >= minYear; y--) y];
  }

  /// Marka katalogda yoksa "Diğer" olarak listelenir.
  static const String otherBrand = 'Diğer';
  static const String otherModel = 'Diğer';
}

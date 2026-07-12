/// Yerel marka logoları (`assets/brand_logos/*.png`).
/// Bilinmeyen / özel marka için null; UI harf fallback kullanır.
class BrandLogos {
  BrandLogos._();

  static const String _dir = 'assets/brand_logos';

  /// Katalog adı (veya yaygın alias) → asset yolu.
  static const Map<String, String> _byKey = <String, String>{
    'audi': '$_dir/audi.png',
    'bmw': '$_dir/bmw.png',
    'byd': '$_dir/byd.png',
    'chevrolet': '$_dir/chevrolet.png',
    'chery': '$_dir/chery.png',
    'citroen': '$_dir/citroen.png',
    'citroën': '$_dir/citroen.png',
    'cupra': '$_dir/cupra.png',
    'dacia': '$_dir/dacia.png',
    'ds': '$_dir/ds.png',
    'fiat': '$_dir/fiat.png',
    'ford': '$_dir/ford.png',
    'honda': '$_dir/honda.png',
    'hyundai': '$_dir/hyundai.png',
    'jaguar': '$_dir/jaguar.png',
    'jeep': '$_dir/jeep.png',
    'kia': '$_dir/kia.png',
    'land rover': '$_dir/land-rover.png',
    'land-rover': '$_dir/land-rover.png',
    'lexus': '$_dir/lexus.png',
    'mazda': '$_dir/mazda.png',
    'mercedes': '$_dir/mercedes-benz.png',
    'mercedes-benz': '$_dir/mercedes-benz.png',
    'mercedes benz': '$_dir/mercedes-benz.png',
    'mg': '$_dir/mg.png',
    'mini': '$_dir/mini.png',
    'mitsubishi': '$_dir/mitsubishi.png',
    'nissan': '$_dir/nissan.png',
    'opel': '$_dir/opel.png',
    'peugeot': '$_dir/peugeot.png',
    'porsche': '$_dir/porsche.png',
    'renault': '$_dir/renault.png',
    'seat': '$_dir/seat.png',
    'skoda': '$_dir/skoda.png',
    'škoda': '$_dir/skoda.png',
    'smart': '$_dir/smart.png',
    'ssangyong': '$_dir/ssangyong.png',
    'ssang yong': '$_dir/ssangyong.png',
    'subaru': '$_dir/subaru.png',
    'suzuki': '$_dir/suzuki.png',
    'tesla': '$_dir/tesla.png',
    'togg': '$_dir/togg.png',
    'toyota': '$_dir/toyota.png',
    'volkswagen': '$_dir/volkswagen.png',
    'vw': '$_dir/volkswagen.png',
    'volvo': '$_dir/volvo.png',
  };

  /// CDN URL (admin seed / Supabase `logo_url`) — thumb PNG.
  static const String cdnBase =
      'https://raw.githubusercontent.com/filippofilip95/car-logos-dataset/master/logos/thumb';

  static const Map<String, String> _cdnFile = <String, String>{
    'audi': 'audi.png',
    'bmw': 'bmw.png',
    'byd': 'byd.png',
    'chevrolet': 'chevrolet.png',
    'chery': 'chery.png',
    'citroen': 'citroen.png',
    'cupra': 'cupra.png',
    'dacia': 'dacia.png',
    'ds': 'ds.png',
    'fiat': 'fiat.png',
    'ford': 'ford.png',
    'honda': 'honda.png',
    'hyundai': 'hyundai.png',
    'jaguar': 'jaguar.png',
    'jeep': 'jeep.png',
    'kia': 'kia.png',
    'land-rover': 'land-rover.png',
    'lexus': 'lexus.png',
    'mazda': 'mazda.png',
    'mercedes-benz': 'mercedes-benz.png',
    'mg': 'mg.png',
    'mini': 'mini.png',
    'mitsubishi': 'mitsubishi.png',
    'nissan': 'nissan.png',
    'opel': 'opel.png',
    'peugeot': 'peugeot.png',
    'porsche': 'porsche.png',
    'renault': 'renault.png',
    'seat': 'seat.png',
    'skoda': 'skoda.png',
    'smart': 'smart.png',
    'ssangyong': 'ssangyong.png',
    'subaru': 'subaru.png',
    'suzuki': 'suzuki.png',
    'tesla': 'tesla.png',
    'toyota': 'toyota.png',
    'volkswagen': 'volkswagen.png',
    'volvo': 'volvo.png',
  };

  /// Togg Wikimedia (dataset’te yok).
  static const String toggCdnUrl =
      'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Togg_Official_Logo.svg&width=256';

  static String _normalize(String marka) {
    var s = marka.trim().toLowerCase();
    s = s
        .replaceAll('é', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('š', 's')
        .replaceAll('ş', 's');
    return s;
  }

  /// Mobil: yerel asset yolu.
  static String? assetFor(String marka) {
    final key = _normalize(marka);
    return _byKey[key];
  }

  /// Seed / admin: kalıcı CDN URL (slug ile).
  static String? cdnUrlForSlug(String slug) {
    final s = slug.trim().toLowerCase();
    if (s == 'togg') return toggCdnUrl;
    final file = _cdnFile[s];
    if (file == null) return null;
    return '$cdnBase/$file';
  }
}

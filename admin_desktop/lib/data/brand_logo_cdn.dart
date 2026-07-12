/// Admin / seed için marka logo CDN (PNG). Flutter Image.network SVG okuyamaz.
class BrandLogoCdn {
  BrandLogoCdn._();

  static const String base =
      'https://raw.githubusercontent.com/filippofilip95/car-logos-dataset/master/logos/thumb';

  static const String toggUrl =
      'https://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/Togg_Official_Logo.svg&width=256';

  static const Map<String, String> _fileBySlug = {
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

  static String? urlForSlug(String slug) {
    final s = slug.trim().toLowerCase();
    if (s == 'togg') return toggUrl;
    final file = _fileBySlug[s];
    if (file == null) return null;
    return '$base/$file';
  }

  /// SVG / Simple Icons vb. Flutter Image.network ile çizilemez.
  static bool isUsableRasterUrl(String? url) {
    if (url == null || url.trim().isEmpty) return false;
    final u = url.toLowerCase();
    if (u.contains('simpleicons.org')) return false;
    if (u.contains('/uploads/brands/')) return false;
    if (u.endsWith('.svg') || u.contains('.svg?')) return false;
    return u.startsWith('http://') || u.startsWith('https://');
  }

  /// Katalog CDN varsa onu kullan (eski storage / SVG yüklemelerini ezer).
  static String? effectiveUrl({required String slug, String? stored}) {
    final cdn = urlForSlug(slug);
    if (cdn != null) return cdn;
    if (isUsableRasterUrl(stored)) return stored;
    return null;
  }
}

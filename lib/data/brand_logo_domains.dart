/// Clearbit Logo API: `https://logo.clearbit.com/{domain}` (PNG).
/// Bilinmeyen / özel marka için null döner; UI harf fallback kullanır.
class BrandLogoDomains {
  BrandLogoDomains._();

  static const Map<String, String> _domains = <String, String>{
    'Audi': 'audi.com',
    'BMW': 'bmw.com',
    'Chery': 'chery.com',
    'Citroen': 'citroen.com',
    'Cupra': 'cupraofficial.com',
    'Dacia': 'dacia.com',
    'DS': 'dsautomobiles.com',
    'Fiat': 'fiat.com',
    'Ford': 'ford.com',
    'Honda': 'honda.com',
    'Hyundai': 'hyundai.com',
    'Jeep': 'jeep.com',
    'Kia': 'kia.com',
    'Land Rover': 'landrover.com',
    'Mazda': 'mazda.com',
    'Mercedes-Benz': 'mercedes-benz.com',
    'MG': 'mgmotor.com',
    'Mini': 'mini.com',
    'Mitsubishi': 'mitsubishi-motors.com',
    'Nissan': 'nissan.com',
    'Opel': 'opel.com',
    'Peugeot': 'peugeot.com',
    'Porsche': 'porsche.com',
    'Renault': 'renault.com',
    'Seat': 'seat.com',
    'Skoda': 'skoda-auto.com',
    'Subaru': 'subaru.com',
    'Suzuki': 'suzuki.com',
    'Tesla': 'tesla.com',
    'Togg': 'togg.com.tr',
    'Toyota': 'toyota.com',
    'Volkswagen': 'volkswagen.com',
    'Volvo': 'volvocars.com',
  };

  static String? clearbitDomainFor(String marka) {
    final String key = marka.trim();
    if (key.isEmpty) return null;
    return _domains[key];
  }
}

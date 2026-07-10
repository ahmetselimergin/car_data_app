class Brand {
  const Brand({
    required this.id,
    required this.slug,
    required this.name,
    this.logoUrl,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String slug;
  final String name;
  final String? logoUrl;
  final int sortOrder;
  final String createdAt;
  final String updatedAt;

  factory Brand.fromJson(Map<String, dynamic> j) => Brand(
        id: j['id'] as int,
        slug: j['slug'] as String,
        name: j['name'] as String,
        logoUrl: j['logo_url'] as String?,
        sortOrder: (j['sort_order'] as num?)?.toInt() ?? 0,
        createdAt: j['created_at'] as String? ?? '',
        updatedAt: j['updated_at'] as String? ?? '',
      );
}

class CarModel {
  const CarModel({
    required this.id,
    required this.brandId,
    required this.name,
    this.bodyType,
    this.yearStart,
    this.yearEnd,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int brandId;
  final String name;
  final String? bodyType;
  final int? yearStart;
  final int? yearEnd;
  final String? notes;
  final String createdAt;
  final String updatedAt;

  factory CarModel.fromJson(Map<String, dynamic> j) => CarModel(
        id: j['id'] as int,
        brandId: j['brand_id'] as int,
        name: j['name'] as String,
        bodyType: j['body_type'] as String?,
        yearStart: (j['year_start'] as num?)?.toInt(),
        yearEnd: (j['year_end'] as num?)?.toInt(),
        notes: j['notes'] as String?,
        createdAt: j['created_at'] as String? ?? '',
        updatedAt: j['updated_at'] as String? ?? '',
      );
}

class Car {
  const Car({
    required this.id,
    required this.plaka,
    required this.marka,
    required this.model,
    required this.yil,
    required this.km,
    this.transmission,
    this.fuelType,
    this.color,
    this.imageUrl,
    this.notes,
    this.brandId,
    this.brand,
    this.ownerUid,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String plaka;
  final String marka;
  final String model;
  final int yil;
  final int km;
  final String? transmission;
  final String? fuelType;
  final String? color;
  final String? imageUrl;
  final String? notes;
  final int? brandId;
  final Brand? brand;
  final String? ownerUid;
  final String createdAt;
  final String updatedAt;

  factory Car.fromJson(Map<String, dynamic> j) {
    Brand? brand;
    final raw = j['brands'];
    if (raw is Map<String, dynamic>) {
      brand = Brand.fromJson(raw);
    } else if (raw is List && raw.isNotEmpty && raw.first is Map) {
      brand = Brand.fromJson(Map<String, dynamic>.from(raw.first as Map));
    }
    return Car(
      id: j['id'] as int,
      plaka: j['plaka'] as String,
      marka: j['marka'] as String,
      model: j['model'] as String,
      yil: (j['yil'] as num).toInt(),
      km: (j['km'] as num?)?.toInt() ?? 0,
      transmission: j['transmission'] as String?,
      fuelType: j['fuel_type'] as String?,
      color: j['color'] as String?,
      imageUrl: j['image_url'] as String?,
      notes: j['notes'] as String?,
      brandId: (j['brand_id'] as num?)?.toInt(),
      brand: brand,
      ownerUid: j['owner_uid'] as String?,
      createdAt: j['created_at'] as String? ?? '',
      updatedAt: j['updated_at'] as String? ?? '',
    );
  }
}

class Workshop {
  const Workshop({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.notes,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? notes;
  final bool active;
  final String createdAt;
  final String updatedAt;

  factory Workshop.fromJson(Map<String, dynamic> j) => Workshop(
        id: j['id'] as int,
        name: j['name'] as String,
        phone: j['phone'] as String?,
        email: j['email'] as String?,
        address: j['address'] as String?,
        notes: j['notes'] as String?,
        active: j['active'] as bool? ?? true,
        createdAt: j['created_at'] as String? ?? '',
        updatedAt: j['updated_at'] as String? ?? '',
      );
}

class InsuranceCompany {
  const InsuranceCompany({
    required this.id,
    required this.name,
    required this.type,
    this.phone,
    this.email,
    this.website,
    this.address,
    this.notes,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String name;
  final String type;
  final String? phone;
  final String? email;
  final String? website;
  final String? address;
  final String? notes;
  final bool active;
  final String createdAt;
  final String updatedAt;

  static const types = [
    ('insurance', 'Trafik'),
    ('casco', 'Kasko'),
    ('both', 'Trafik + Kasko'),
  ];

  String get typeLabel =>
      types.where((t) => t.$1 == type).map((t) => t.$2).firstOrNull ?? type;

  factory InsuranceCompany.fromJson(Map<String, dynamic> j) =>
      InsuranceCompany(
        id: j['id'] as int,
        name: j['name'] as String,
        type: j['type'] as String? ?? 'both',
        phone: j['phone'] as String?,
        email: j['email'] as String?,
        website: j['website'] as String?,
        address: j['address'] as String?,
        notes: j['notes'] as String?,
        active: j['active'] as bool? ?? true,
        createdAt: j['created_at'] as String? ?? '',
        updatedAt: j['updated_at'] as String? ?? '',
      );
}

class ProfileUser {
  const ProfileUser({
    required this.id,
    required this.username,
    required this.email,
    required this.userType,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String username;
  final String email;
  final String userType;
  final String createdAt;
  final String updatedAt;

  static const typeOptions = [
    ('admin', 'Admin'),
    ('partner_user', 'Partner'),
    ('normal_user', 'Kullanıcı'),
  ];

  String get typeLabel =>
      typeOptions.where((t) => t.$1 == userType).map((t) => t.$2).firstOrNull ??
      userType;

  factory ProfileUser.fromJson(Map<String, dynamic> j) => ProfileUser(
        id: j['id'] as String,
        username: j['username'] as String? ?? '',
        email: j['email'] as String? ?? '',
        userType: j['user_type'] as String? ?? 'normal_user',
        createdAt: j['created_at'] as String? ?? '',
        updatedAt: j['updated_at'] as String? ?? '',
      );
}

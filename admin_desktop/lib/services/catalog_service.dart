import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';

const brandLogosBucket = 'brand-logos';

String normalizeSlug(String raw) {
  return raw
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), '-')
      .replaceAll(RegExp(r'[^a-z0-9-]'), '');
}

class CatalogService {
  CatalogService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String? _storagePathFromLogoUrl(String? url) {
    if (url == null) return null;
    final marker = '/storage/v1/object/public/$brandLogosBucket/';
    final idx = url.indexOf(marker);
    if (idx == -1) return null;
    return Uri.decodeComponent(url.substring(idx + marker.length));
  }

  Future<String> _uploadBrandLogo({
    required String slug,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final ext = p.extension(fileName).replaceFirst('.', '');
    final safeExt = ext.isEmpty ? 'png' : ext.toLowerCase();
    final path = '$slug-${DateTime.now().millisecondsSinceEpoch}.$safeExt';
    await _client.storage.from(brandLogosBucket).uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );
    return _client.storage.from(brandLogosBucket).getPublicUrl(path);
  }

  Future<void> _deleteBrandLogoIfStored(String? url) async {
    final path = _storagePathFromLogoUrl(url);
    if (path == null) return;
    await _client.storage.from(brandLogosBucket).remove([path]);
  }

  // ——— Brands ———

  Future<List<Brand>> listBrands() async {
    final data = await _client
        .from('brands')
        .select()
        .order('sort_order')
        .order('name');
    return (data as List)
        .map((e) => Brand.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<Brand> createBrand({
    required String slug,
    required String name,
    required int sortOrder,
    Uint8List? logoBytes,
    String? logoFileName,
  }) async {
    final s = normalizeSlug(slug);
    String? logoUrl;
    if (logoBytes != null && logoFileName != null) {
      logoUrl = await _uploadBrandLogo(
        slug: s,
        bytes: logoBytes,
        fileName: logoFileName,
      );
    }
    final row = await _client
        .from('brands')
        .insert({
          'slug': s,
          'name': name.trim(),
          'sort_order': sortOrder,
          'logo_url': logoUrl,
        })
        .select()
        .single();
    return Brand.fromJson(Map<String, dynamic>.from(row));
  }

  Future<Brand> updateBrand({
    required int id,
    required String slug,
    required String name,
    required int sortOrder,
    Uint8List? logoBytes,
    String? logoFileName,
    bool removeLogo = false,
    String? existingLogoUrl,
  }) async {
    final s = normalizeSlug(slug);
    var logoUrl = existingLogoUrl;
    if (removeLogo && logoUrl != null) {
      await _deleteBrandLogoIfStored(logoUrl);
      logoUrl = null;
    }
    if (logoBytes != null && logoFileName != null) {
      if (logoUrl != null) await _deleteBrandLogoIfStored(logoUrl);
      logoUrl = await _uploadBrandLogo(
        slug: s,
        bytes: logoBytes,
        fileName: logoFileName,
      );
    }
    final row = await _client
        .from('brands')
        .update({
          'slug': s,
          'name': name.trim(),
          'sort_order': sortOrder,
          'logo_url': logoUrl,
        })
        .eq('id', id)
        .select()
        .single();
    return Brand.fromJson(Map<String, dynamic>.from(row));
  }

  Future<void> deleteBrand(Brand brand) async {
    await _deleteBrandLogoIfStored(brand.logoUrl);
    await _client.from('brands').delete().eq('id', brand.id);
  }

  // ——— Models ———

  Future<List<CarModel>> listModels({int? brandId}) async {
    var q = _client.from('models').select();
    if (brandId != null) {
      q = q.eq('brand_id', brandId);
    }
    final data = await q.order('brand_id').order('name');
    return (data as List)
        .map((e) => CarModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<CarModel> createModel({
    required int brandId,
    required String name,
    String? bodyType,
    int? yearStart,
    int? yearEnd,
    String? notes,
  }) async {
    final row = await _client
        .from('models')
        .insert({
          'brand_id': brandId,
          'name': name.trim(),
          'body_type': bodyType,
          'year_start': yearStart,
          'year_end': yearEnd,
          'notes': notes,
        })
        .select()
        .single();
    return CarModel.fromJson(Map<String, dynamic>.from(row));
  }

  Future<CarModel> updateModel({
    required int id,
    required int brandId,
    required String name,
    String? bodyType,
    int? yearStart,
    int? yearEnd,
    String? notes,
  }) async {
    final row = await _client
        .from('models')
        .update({
          'brand_id': brandId,
          'name': name.trim(),
          'body_type': bodyType,
          'year_start': yearStart,
          'year_end': yearEnd,
          'notes': notes,
        })
        .eq('id', id)
        .select()
        .single();
    return CarModel.fromJson(Map<String, dynamic>.from(row));
  }

  Future<void> deleteModel(int id) async {
    await _client.from('models').delete().eq('id', id);
  }

  // ——— Cars ———

  Future<List<Car>> listCars({String? ownerUid}) async {
    var q = _client.from('cars').select('*, brands(*)');
    if (ownerUid != null) {
      q = q.eq('owner_uid', ownerUid);
    }
    final data = await q.order('created_at', ascending: false);
    return (data as List)
        .map((e) => Car.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<Car> createCar(Map<String, dynamic> input) async {
    final row = await _client
        .from('cars')
        .insert(input)
        .select('*, brands(*)')
        .single();
    return Car.fromJson(Map<String, dynamic>.from(row));
  }

  Future<Car> updateCar(int id, Map<String, dynamic> input) async {
    final row = await _client
        .from('cars')
        .update(input)
        .eq('id', id)
        .select('*, brands(*)')
        .single();
    return Car.fromJson(Map<String, dynamic>.from(row));
  }

  Future<void> deleteCar(int id) async {
    await _client.from('cars').delete().eq('id', id);
  }

  // ——— Workshops ———

  Future<List<Workshop>> listWorkshops() async {
    final data = await _client
        .from('workshops')
        .select()
        .order('active', ascending: false)
        .order('name');
    return (data as List)
        .map((e) => Workshop.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<Workshop> createWorkshop(Map<String, dynamic> input) async {
    final row =
        await _client.from('workshops').insert(input).select().single();
    return Workshop.fromJson(Map<String, dynamic>.from(row));
  }

  Future<Workshop> updateWorkshop(int id, Map<String, dynamic> input) async {
    final row = await _client
        .from('workshops')
        .update(input)
        .eq('id', id)
        .select()
        .single();
    return Workshop.fromJson(Map<String, dynamic>.from(row));
  }

  Future<void> deleteWorkshop(int id) async {
    await _client.from('workshops').delete().eq('id', id);
  }

  // ——— Insurance ———

  Future<List<InsuranceCompany>> listInsurance() async {
    final data = await _client
        .from('insurance_companies')
        .select()
        .order('active', ascending: false)
        .order('name');
    return (data as List)
        .map(
          (e) =>
              InsuranceCompany.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  }

  Future<InsuranceCompany> createInsurance(Map<String, dynamic> input) async {
    final row = await _client
        .from('insurance_companies')
        .insert(input)
        .select()
        .single();
    return InsuranceCompany.fromJson(Map<String, dynamic>.from(row));
  }

  Future<InsuranceCompany> updateInsurance(
    int id,
    Map<String, dynamic> input,
  ) async {
    final row = await _client
        .from('insurance_companies')
        .update(input)
        .eq('id', id)
        .select()
        .single();
    return InsuranceCompany.fromJson(Map<String, dynamic>.from(row));
  }

  Future<void> deleteInsurance(int id) async {
    await _client.from('insurance_companies').delete().eq('id', id);
  }
}

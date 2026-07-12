import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../models/models.dart';
import '../services/catalog_service.dart';
import '../widgets/common.dart';
import '../widgets/form_dialog.dart';

const _transmissions = [
  'Manuel',
  'Otomatik',
  'Yarı otomatik',
  'CVT',
];

const _fuels = [
  'Benzin',
  'Dizel',
  'LPG',
  'Hibrit',
  'Plug-in hibrit',
  'Elektrik',
];

List<int> _yearOptions({int minYear = 1980}) {
  final now = DateTime.now().year;
  return [for (var y = now + 1; y >= minYear; y--) y];
}

class CarsScreen extends StatefulWidget {
  const CarsScreen({super.key, required this.catalog});

  final CatalogService catalog;

  @override
  State<CarsScreen> createState() => _CarsScreenState();
}

class _CarsScreenState extends State<CarsScreen> {
  var _loading = true;
  String? _error;
  List<Car> _items = [];
  List<Brand> _brands = [];
  List<CarModel> _models = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        widget.catalog.listBrands(),
        widget.catalog.listModels(),
        widget.catalog.listCars(),
      ]);
      if (!mounted) return;
      setState(() {
        _brands = results[0] as List<Brand>;
        _models = results[1] as List<CarModel>;
        _items = results[2] as List<Car>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<CarModel> _modelsForBrand(int? brandId) {
    if (brandId == null) return const [];
    return _models.where((m) => m.brandId == brandId).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  Brand? _brandById(int? id) {
    if (id == null) return null;
    for (final b in _brands) {
      if (b.id == id) return b;
    }
    return null;
  }

  Map<String, dynamic> _payload({
    required String plaka,
    required String marka,
    required String model,
    required int yil,
    required int km,
    String? transmission,
    String? fuelType,
    String? color,
    String? imageUrl,
    String? notes,
    int? brandId,
    String? ownerUid,
  }) =>
      {
        'plaka': plaka.trim(),
        'marka': marka.trim(),
        'model': model.trim(),
        'yil': yil,
        'km': km,
        'transmission': transmission,
        'fuel_type': fuelType,
        'color': color,
        'image_url': imageUrl,
        'notes': notes,
        'brand_id': brandId,
        'owner_uid': ownerUid,
      };

  Future<void> _openForm({Car? editing}) async {
    final plaka = TextEditingController(text: editing?.plaka ?? '');
    final km = TextEditingController(text: '${editing?.km ?? 0}');
    final color = TextEditingController(text: editing?.color ?? '');
    final imageUrl = TextEditingController(text: editing?.imageUrl ?? '');
    final notes = TextEditingController(text: editing?.notes ?? '');
    final ownerUid = TextEditingController(text: editing?.ownerUid ?? '');

    int? brandId = editing?.brandId;
    if (brandId == null && editing != null) {
      for (final b in _brands) {
        if (b.name.toLowerCase() == editing.marka.toLowerCase()) {
          brandId = b.id;
          break;
        }
      }
    }

    String? modelName = editing?.model;
    if (brandId != null && modelName != null) {
      final match = _modelsForBrand(brandId)
          .where((m) => m.name == modelName)
          .firstOrNull;
      modelName = match?.name ?? modelName;
    }

    var yil = editing?.yil ?? DateTime.now().year;
    String? transmission = editing?.transmission;
    if (transmission != null && !_transmissions.contains(transmission)) {
      // Eski serbest metin — listede yoksa null (yeniden seçilsin)
      if (!_transmissions.any(
        (t) => t.toLowerCase() == transmission!.toLowerCase(),
      )) {
        transmission = null;
      } else {
        transmission = _transmissions.firstWhere(
          (t) => t.toLowerCase() == transmission!.toLowerCase(),
        );
      }
    }

    String? fuelType = editing?.fuelType;
    if (fuelType != null) {
      final lower = fuelType.toLowerCase();
      if (lower == 'petrol' ||
          lower == 'benzin' ||
          lower == 'gasolina' ||
          lower == 'gasoline') {
        fuelType = 'Benzin';
      } else {
        fuelType = _fuels
            .where((f) => f.toLowerCase() == lower)
            .firstOrNull;
      }
    }

    final years = _yearOptions();
    if (!years.contains(yil)) {
      years.insert(0, yil);
    }

    final saved = await showFormDialog(
      context: context,
      title: editing == null ? 'Yeni araç' : 'Aracı düzenle',
      width: 480,
      builder: (ctx, setLocal) {
        final brandModels = _modelsForBrand(brandId);
        final modelItems = <(String, String)>[
          for (final m in brandModels) (m.name, m.name),
        ];
        if (modelName != null &&
            modelName!.isNotEmpty &&
            !modelItems.any((e) => e.$1 == modelName)) {
          modelItems.insert(0, (modelName!, modelName!));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FormLabeledField(
              label: 'Plaka',
              child: TextField(
                controller: plaka,
                placeholder: const Text('34 ABC 123'),
              ),
            ),
            const Gap(14),
            FormLabeledField(
              label: 'Marka',
              child: AppSelect<int>(
                value: brandId,
                placeholder: 'Marka seç',
                items: [
                  for (final b in _brands) (b.id, b.name),
                ],
                onChanged: (v) {
                  setLocal(() {
                    brandId = v;
                    modelName = null;
                  });
                },
              ),
            ),
            const Gap(14),
            FormLabeledField(
              label: 'Model',
              child: AppSelect<String>(
                value: modelName,
                placeholder: brandId == null ? 'Önce marka seç' : 'Model seç',
                items: modelItems,
                onChanged: brandId == null
                    ? (_) {}
                    : (v) => setLocal(() => modelName = v),
              ),
            ),
            const Gap(14),
            Row(
              children: [
                Expanded(
                  child: FormLabeledField(
                    label: 'Yıl',
                    child: AppSelect<int>(
                      value: yil,
                      items: [
                        for (final y in years) (y, '$y'),
                      ],
                      onChanged: (v) {
                        if (v != null) setLocal(() => yil = v);
                      },
                    ),
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: FormLabeledField(
                    label: 'Km',
                    child: TextField(
                      controller: km,
                      keyboardType: TextInputType.number,
                      placeholder: const Text('0'),
                    ),
                  ),
                ),
              ],
            ),
            const Gap(14),
            FormLabeledField(
              label: 'Vites',
              child: AppSelect<String>(
                value: transmission,
                placeholder: 'Vites seç',
                items: [
                  for (final t in _transmissions) (t, t),
                ],
                onChanged: (v) => setLocal(() => transmission = v),
              ),
            ),
            const Gap(14),
            FormLabeledField(
              label: 'Yakıt',
              child: AppSelect<String>(
                value: fuelType,
                placeholder: 'Yakıt seç',
                items: [
                  for (final f in _fuels) (f, f),
                ],
                onChanged: (v) => setLocal(() => fuelType = v),
              ),
            ),
            const Gap(14),
            FormLabeledField(
              label: 'Renk',
              child: TextField(
                controller: color,
                placeholder: const Text('Opsiyonel'),
              ),
            ),
            const Gap(14),
            FormLabeledField(
              label: 'Görsel URL',
              child: TextField(
                controller: imageUrl,
                placeholder: const Text('https://…'),
              ),
            ),
            const Gap(14),
            FormLabeledField(
              label: 'Sahip kullanıcı ID',
              helper: 'Supabase Auth kullanıcı id',
              child: TextField(
                controller: ownerUid,
                placeholder: const Text('uuid'),
              ),
            ),
            const Gap(14),
            FormLabeledField(
              label: 'Notlar',
              child: TextField(
                controller: notes,
                placeholder: const Text('Opsiyonel'),
                maxLines: 3,
              ),
            ),
          ],
        );
      },
    );

    if (saved != true || !mounted) return;

    final brand = _brandById(brandId);
    if (brand == null) {
      showSnack(context, 'Marka seçilmedi.', error: true);
      return;
    }
    if (modelName == null || modelName!.trim().isEmpty) {
      showSnack(context, 'Model seçilmedi.', error: true);
      return;
    }
    if (transmission == null || transmission!.isEmpty) {
      showSnack(context, 'Vites seçilmedi.', error: true);
      return;
    }
    if (fuelType == null || fuelType!.isEmpty) {
      showSnack(context, 'Yakıt seçilmedi.', error: true);
      return;
    }

    final body = _payload(
      plaka: plaka.text,
      marka: brand.name,
      model: modelName!.trim(),
      yil: yil,
      km: int.tryParse(km.text) ?? 0,
      transmission: transmission,
      fuelType: fuelType,
      color: color.text.trim().isEmpty ? null : color.text.trim(),
      imageUrl: imageUrl.text.trim().isEmpty ? null : imageUrl.text.trim(),
      notes: notes.text.trim().isEmpty ? null : notes.text.trim(),
      brandId: brandId,
      ownerUid: ownerUid.text.trim().isEmpty ? null : ownerUid.text.trim(),
    );
    try {
      if (editing == null) {
        await widget.catalog.createCar(body);
      } else {
        await widget.catalog.updateCar(editing.id, body);
      }
      await _load();
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      eyebrow: 'Katalog',
      title: 'Araçlar',
      subtitle: '${_items.length} plaka kaydı',
      actions: [
        IconButton.ghost(
          onPressed: _load,
          icon: const Icon(LucideIcons.refreshCw, size: 16),
        ),
        PrimaryButton(
          onPressed: _brands.isEmpty ? null : () => _openForm(),
          leading: const Icon(LucideIcons.plus, size: 14),
          child: const Text('Ekle'),
        ),
      ],
      child: AsyncBody(
        loading: _loading,
        error: _error,
        isEmpty: _items.isEmpty,
        emptyMessage: 'Araç yok.',
        emptySubtitle: 'Plaka kaydı ekleyerek başla.',
        emptyIcon: LucideIcons.car,
        onRetry: _load,
        child: DataPanel(
          child: ListView.builder(
            itemCount: _items.length,
            itemBuilder: (context, i) {
              final c = _items[i];
              return CatalogRow(
                leading: AvatarTile(
                  imageUrl: c.imageUrl,
                  fallbackIcon: LucideIcons.car,
                ),
                title: '${c.plaka} — ${c.marka} ${c.model}',
                subtitle:
                    '${c.yil} · ${c.km} km${c.ownerUid != null ? ' · ${c.ownerUid}' : ''}',
                meta: c.fuelType != null ? MetaChip(c.fuelType!) : null,
                onEdit: () => _openForm(editing: c),
                onDelete: () async {
                  final ok = await confirmDelete(
                    context,
                    title: 'Aracı sil',
                    message: '"${c.plaka}" silinsin mi?',
                  );
                  if (!ok) return;
                  try {
                    await widget.catalog.deleteCar(c.id);
                    await _load();
                  } catch (e) {
                    if (context.mounted) {
                      showSnack(context, e.toString(), error: true);
                    }
                  }
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../models/models.dart';
import '../services/catalog_service.dart';
import '../widgets/common.dart';
import '../widgets/form_dialog.dart';

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
      final brands = await widget.catalog.listBrands();
      final cars = await widget.catalog.listCars();
      if (!mounted) return;
      setState(() {
        _brands = brands;
        _items = cars;
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
    final marka = TextEditingController(text: editing?.marka ?? '');
    final model = TextEditingController(text: editing?.model ?? '');
    final yil = TextEditingController(
      text: '${editing?.yil ?? DateTime.now().year}',
    );
    final km = TextEditingController(text: '${editing?.km ?? 0}');
    final transmission =
        TextEditingController(text: editing?.transmission ?? '');
    final fuelType = TextEditingController(text: editing?.fuelType ?? '');
    final color = TextEditingController(text: editing?.color ?? '');
    final imageUrl = TextEditingController(text: editing?.imageUrl ?? '');
    final notes = TextEditingController(text: editing?.notes ?? '');
    final ownerUid = TextEditingController(text: editing?.ownerUid ?? '');
    int? brandId = editing?.brandId;

    final saved = await showFormDialog(
      context: context,
      title: editing == null ? 'Yeni araç' : 'Aracı düzenle',
      width: 480,
      builder: (ctx, setLocal) => Column(
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
            label: 'Marka (katalog)',
            child: AppSelect<int>(
              value: brandId,
              canUnselect: true,
              placeholder: '—',
              items: [
                for (final b in _brands) (b.id, b.name),
              ],
              onChanged: (v) {
                setLocal(() {
                  brandId = v;
                  if (v != null) {
                    final b = _brands.firstWhere((x) => x.id == v);
                    marka.text = b.name;
                  }
                });
              },
            ),
          ),
          const Gap(14),
          FormLabeledField(
            label: 'Marka metni',
            child: TextField(
              controller: marka,
              placeholder: const Text('Marka'),
            ),
          ),
          const Gap(14),
          FormLabeledField(
            label: 'Model',
            child: TextField(
              controller: model,
              placeholder: const Text('Model'),
            ),
          ),
          const Gap(14),
          Row(
            children: [
              Expanded(
                child: FormLabeledField(
                  label: 'Yıl',
                  child: TextField(
                    controller: yil,
                    keyboardType: TextInputType.number,
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
                  ),
                ),
              ),
            ],
          ),
          const Gap(14),
          FormLabeledField(
            label: 'Vites',
            child: TextField(
              controller: transmission,
              placeholder: const Text('Opsiyonel'),
            ),
          ),
          const Gap(14),
          FormLabeledField(
            label: 'Yakıt',
            child: TextField(
              controller: fuelType,
              placeholder: const Text('Opsiyonel'),
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
      ),
    );

    if (saved != true || !mounted) return;
    final body = _payload(
      plaka: plaka.text,
      marka: marka.text,
      model: model.text,
      yil: int.tryParse(yil.text) ?? DateTime.now().year,
      km: int.tryParse(km.text) ?? 0,
      transmission:
          transmission.text.trim().isEmpty ? null : transmission.text.trim(),
      fuelType: fuelType.text.trim().isEmpty ? null : fuelType.text.trim(),
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
          onPressed: () => _openForm(),
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

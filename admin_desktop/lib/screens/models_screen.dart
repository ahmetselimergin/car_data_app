import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../models/models.dart';
import '../services/catalog_service.dart';
import '../widgets/brand_logo_thumb.dart';
import '../widgets/common.dart';
import '../widgets/form_dialog.dart';

const bodyTypes = [
  'Sedan',
  'Hatchback',
  'SUV',
  'Crossover',
  'Coupe',
  'Cabrio',
  'Pickup',
  'Van',
  'Station Wagon',
];

class ModelsScreen extends StatefulWidget {
  const ModelsScreen({super.key, required this.catalog});

  final CatalogService catalog;

  @override
  State<ModelsScreen> createState() => _ModelsScreenState();
}

class _ModelsScreenState extends State<ModelsScreen> {
  var _loading = true;
  String? _error;
  List<CarModel> _items = [];
  List<Brand> _brands = [];
  int? _filterBrandId;

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
      final models = await widget.catalog.listModels();
      if (!mounted) return;
      setState(() {
        _brands = brands;
        _items = models;
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

  String _brandName(int id) =>
      _brands.where((b) => b.id == id).map((b) => b.name).firstOrNull ?? '#$id';

  Brand? _brandOf(int id) {
    for (final b in _brands) {
      if (b.id == id) return b;
    }
    return null;
  }

  List<CarModel> get _visible {
    if (_filterBrandId == null) return _items;
    return _items.where((m) => m.brandId == _filterBrandId).toList();
  }

  Future<void> _openForm({CarModel? editing}) async {
    var brandId = editing?.brandId ??
        _filterBrandId ??
        (_brands.isNotEmpty ? _brands.first.id : null);
    final name = TextEditingController(text: editing?.name ?? '');
    var bodyType = editing?.bodyType;
    final yearStart = TextEditingController(
      text: editing?.yearStart?.toString() ?? '',
    );
    final yearEnd = TextEditingController(
      text: editing?.yearEnd?.toString() ?? '',
    );
    final notes = TextEditingController(text: editing?.notes ?? '');

    final saved = await showFormDialog(
      context: context,
      title: editing == null ? 'Yeni model' : 'Modeli düzenle',
      builder: (ctx, setLocal) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FormLabeledField(
            label: 'Marka',
            child: AppSelect<int>(
              value: brandId,
              items: [
                for (final b in _brands) (b.id, b.name),
              ],
              onChanged: (v) => setLocal(() => brandId = v),
            ),
          ),
          const Gap(14),
          FormLabeledField(
            label: 'Model adı',
            child: TextField(
              controller: name,
              placeholder: const Text('Model'),
            ),
          ),
          const Gap(14),
          FormLabeledField(
            label: 'Kasa tipi',
            child: AppSelect<String>(
              value: bodyType,
              canUnselect: true,
              placeholder: '—',
              items: [
                for (final t in bodyTypes) (t, t),
              ],
              onChanged: (v) => setLocal(() => bodyType = v),
            ),
          ),
          const Gap(14),
          Row(
            children: [
              Expanded(
                child: FormLabeledField(
                  label: 'Yıl başlangıç',
                  child: TextField(
                    controller: yearStart,
                    placeholder: const Text('2018'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ),
              const Gap(12),
              Expanded(
                child: FormLabeledField(
                  label: 'Yıl bitiş',
                  child: TextField(
                    controller: yearEnd,
                    placeholder: const Text('2024'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ),
            ],
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

    if (saved != true || !mounted || brandId == null) return;
    try {
      if (editing == null) {
        await widget.catalog.createModel(
          brandId: brandId!,
          name: name.text,
          bodyType: bodyType,
          yearStart: int.tryParse(yearStart.text),
          yearEnd: int.tryParse(yearEnd.text),
          notes: notes.text.trim().isEmpty ? null : notes.text.trim(),
        );
      } else {
        await widget.catalog.updateModel(
          id: editing.id,
          brandId: brandId!,
          name: name.text,
          bodyType: bodyType,
          yearStart: int.tryParse(yearStart.text),
          yearEnd: int.tryParse(yearEnd.text),
          notes: notes.text.trim().isEmpty ? null : notes.text.trim(),
        );
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
      title: 'Modeller',
      subtitle: '${_visible.length} görünür kayıt',
      actions: [
        SizedBox(
          width: 200,
          child: AppSelect<int>(
            value: _filterBrandId,
            canUnselect: true,
            placeholder: 'Tüm markalar',
            items: [
              for (final b in _brands) (b.id, b.name),
            ],
            onChanged: (v) => setState(() => _filterBrandId = v),
          ),
        ),
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
        isEmpty: _visible.isEmpty,
        emptyMessage: 'Model yok.',
        emptySubtitle: 'Markaya bağlı modeller burada listelenir.',
        emptyIcon: LucideIcons.layers,
        onRetry: _load,
        child: DataPanel(
          child: ListView.builder(
            itemCount: _visible.length,
            itemBuilder: (context, i) {
              final m = _visible[i];
              final years = [
                if (m.yearStart != null) '${m.yearStart}',
                if (m.yearEnd != null) '${m.yearEnd}',
              ].join('–');
              return CatalogRow(
                leading: BrandLogoThumb(
                  brand: _brandOf(m.brandId),
                  fallbackIcon: LucideIcons.layers,
                ),
                title: m.name,
                subtitle:
                    '${_brandName(m.brandId)}${m.bodyType != null ? ' · ${m.bodyType}' : ''}',
                meta: years.isEmpty ? null : MetaChip(years),
                onEdit: () => _openForm(editing: m),
                onDelete: () async {
                  final ok = await confirmDelete(
                    context,
                    title: 'Modeli sil',
                    message: '"${m.name}" silinsin mi?',
                  );
                  if (!ok) return;
                  try {
                    await widget.catalog.deleteModel(m.id);
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

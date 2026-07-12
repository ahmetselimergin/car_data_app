import 'dart:typed_data';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../models/models.dart';
import '../services/catalog_service.dart';
import '../widgets/brand_logo_thumb.dart';
import '../widgets/common.dart';
import '../widgets/form_dialog.dart';

class BrandsScreen extends StatefulWidget {
  const BrandsScreen({super.key, required this.catalog});

  final CatalogService catalog;

  @override
  State<BrandsScreen> createState() => _BrandsScreenState();
}

class _BrandsScreenState extends State<BrandsScreen> {
  var _loading = true;
  String? _error;
  List<Brand> _items = [];
  Map<int, int> _modelCounts = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool syncLogos = true}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (syncLogos) {
        try {
          final n = await widget.catalog.syncBrandLogoUrls();
          if (n > 0 && mounted) {
            showSnack(context, '$n marka logosu güncellendi.');
          }
        } catch (_) {
          // Görüntüleme CDN fallback ile devam eder; DB yazılamasa da UI dolsun.
        }
      }
      final results = await Future.wait([
        widget.catalog.listBrands(),
        widget.catalog.listModels(),
      ]);
      final brands = results[0] as List<Brand>;
      final models = results[1] as List<CarModel>;
      final counts = <int, int>{};
      for (final m in models) {
        counts[m.brandId] = (counts[m.brandId] ?? 0) + 1;
      }
      if (!mounted) return;
      setState(() {
        _items = brands;
        _modelCounts = counts;
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

  Future<void> _openForm({Brand? editing}) async {
    final slug = TextEditingController(text: editing?.slug ?? '');
    final name = TextEditingController(text: editing?.name ?? '');
    final sort = TextEditingController(text: '${editing?.sortOrder ?? 0}');
    Uint8List? logoBytes;
    String? logoName;
    var removeLogo = false;

    final saved = await showFormDialog(
      context: context,
      title: editing == null ? 'Yeni marka' : 'Markayı düzenle',
      width: 420,
      builder: (ctx, setLocal) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FormLabeledField(
            label: 'Slug',
            child: TextField(
              controller: slug,
              placeholder: const Text('ornek-marka'),
            ),
          ),
          const Gap(14),
          FormLabeledField(
            label: 'Ad',
            child: TextField(
              controller: name,
              placeholder: const Text('Marka adı'),
            ),
          ),
          const Gap(14),
          FormLabeledField(
            label: 'Sıra',
            child: TextField(
              controller: sort,
              placeholder: const Text('0'),
              keyboardType: TextInputType.number,
            ),
          ),
          const Gap(14),
          FormLabeledField(
            label: 'Logo',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlineButton(
                  onPressed: () async {
                    final r = await FilePicker.platform.pickFiles(
                      type: FileType.image,
                      withData: true,
                    );
                    if (r == null || r.files.isEmpty) return;
                    final f = r.files.first;
                    setLocal(() {
                      logoBytes = f.bytes;
                      logoName = f.name;
                      removeLogo = false;
                    });
                  },
                  leading: const Icon(LucideIcons.image, size: 14),
                  child: Text(logoName ?? 'Logo seç'),
                ),
                if (editing?.logoUrl != null && logoBytes == null) ...[
                  const Gap(10),
                  Checkbox(
                    state: removeLogo
                        ? CheckboxState.checked
                        : CheckboxState.unchecked,
                    onChanged: (s) => setLocal(
                      () => removeLogo = s == CheckboxState.checked,
                    ),
                    trailing: const Text('Logoyu kaldır').small(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    if (saved != true || !mounted) return;
    try {
      if (editing == null) {
        await widget.catalog.createBrand(
          slug: slug.text,
          name: name.text,
          sortOrder: int.tryParse(sort.text) ?? 0,
          logoBytes: logoBytes,
          logoFileName: logoName,
        );
      } else {
        await widget.catalog.updateBrand(
          id: editing.id,
          slug: slug.text,
          name: name.text,
          sortOrder: int.tryParse(sort.text) ?? 0,
          logoBytes: logoBytes,
          logoFileName: logoName,
          removeLogo: removeLogo,
          existingLogoUrl: editing.logoUrl,
        );
      }
      await _load();
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    }
  }

  Future<void> _delete(Brand b) async {
    final ok = await confirmDelete(
      context,
      title: 'Markayı sil',
      message: '"${b.name}" silinsin mi?',
    );
    if (!ok) return;
    try {
      await widget.catalog.deleteBrand(b);
      await _load();
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      eyebrow: 'Katalog',
      title: 'Markalar',
      subtitle: '${_items.length} kayıt',
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
        emptyMessage: 'Henüz marka yok.',
        emptySubtitle: 'İlk markayı ekleyerek kataloğu başlat.',
        emptyIcon: LucideIcons.tag,
        onRetry: _load,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final cols = w >= 1100
                ? 4
                : w >= 820
                    ? 3
                    : w >= 520
                        ? 2
                        : 1;
            final gap = 14.0;
            final cardWidth = (w - gap * (cols - 1)) / cols;

            return SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24, top: 4),
              child: Wrap(
                spacing: gap,
                runSpacing: 16,
                children: [
                  for (final b in _items)
                    SizedBox(
                      width: cardWidth,
                      child: _BrandCard(
                        brand: b,
                        modelCount: _modelCounts[b.id] ?? 0,
                        onEdit: () => _openForm(editing: b),
                        onDelete: () => _delete(b),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BrandCard extends StatefulWidget {
  const _BrandCard({
    required this.brand,
    required this.modelCount,
    required this.onEdit,
    required this.onDelete,
  });

  final Brand brand;
  final int modelCount;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  State<_BrandCard> createState() => _BrandCardState();
}

class _BrandCardState extends State<_BrandCard> {
  var _active = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final b = widget.brand;
    const radius = 14.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _active = true),
      onExit: (_) => setState(() => _active = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        height: 84,
        decoration: BoxDecoration(
          color: theme.colorScheme.secondary,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: _active
                ? theme.colorScheme.foreground.withValues(alpha: 0.55)
                : theme.colorScheme.border,
            width: 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: BrandLogoThumb(
                      brand: b,
                      size: 56,
                      radius: 12,
                      padding: 6,
                    ),
                  ),
                  const Gap(14),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          b.name.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ).large().semiBold(),
                        const Gap(4),
                        Text(
                          '${widget.modelCount} Model',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ).small().muted(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                ignoring: !_active,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 160),
                  opacity: _active ? 1 : 0,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: ColoredBox(
                      color: theme.colorScheme.background.withValues(alpha: 0.45),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _GlassAction(
                            icon: LucideIcons.pencil,
                            tooltip: 'Düzenle',
                            onPressed: widget.onEdit,
                          ),
                          const Gap(12),
                          _GlassAction(
                            icon: LucideIcons.trash2,
                            tooltip: 'Sil',
                            destructive: true,
                            onPressed: widget.onDelete,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassAction extends StatefulWidget {
  const _GlassAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.destructive = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool destructive;

  @override
  State<_GlassAction> createState() => _GlassActionState();
}

class _GlassActionState extends State<_GlassAction> {
  var _hover = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = widget.destructive
        ? theme.colorScheme.destructive
        : theme.colorScheme.foreground;

    return Tooltip(
      tooltip: (_) => TooltipContainer(child: Text(widget.tooltip)),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _hover
                  ? accent.withValues(alpha: 0.18)
                  : theme.colorScheme.card.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: accent.withValues(alpha: _hover ? 0.7 : 0.35),
              ),
            ),
            child: Icon(widget.icon, size: 18, color: accent),
          ),
        ),
      ),
    );
  }
}


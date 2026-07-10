import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../models/models.dart';
import '../services/catalog_service.dart';
import '../widgets/common.dart';
import '../widgets/form_dialog.dart';

class InsuranceScreen extends StatefulWidget {
  const InsuranceScreen({super.key, required this.catalog});

  final CatalogService catalog;

  @override
  State<InsuranceScreen> createState() => _InsuranceScreenState();
}

class _InsuranceScreenState extends State<InsuranceScreen> {
  var _loading = true;
  String? _error;
  List<InsuranceCompany> _items = [];

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
      final items = await widget.catalog.listInsurance();
      if (!mounted) return;
      setState(() {
        _items = items;
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

  Future<void> _openForm({InsuranceCompany? editing}) async {
    final name = TextEditingController(text: editing?.name ?? '');
    var type = editing?.type ?? 'both';
    final phone = TextEditingController(text: editing?.phone ?? '');
    final email = TextEditingController(text: editing?.email ?? '');
    final website = TextEditingController(text: editing?.website ?? '');
    final address = TextEditingController(text: editing?.address ?? '');
    final notes = TextEditingController(text: editing?.notes ?? '');
    var active = editing?.active ?? true;

    final saved = await showFormDialog(
      context: context,
      title: editing == null ? 'Yeni sigorta' : 'Sigortayı düzenle',
      builder: (ctx, setLocal) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FormLabeledField(
            label: 'Ad',
            child: TextField(
              controller: name,
              placeholder: const Text('Şirket adı'),
            ),
          ),
          const Gap(14),
          FormLabeledField(
            label: 'Tür',
            child: AppSelect<String>(
              value: type,
              items: [
                for (final t in InsuranceCompany.types) (t.$1, t.$2),
              ],
              onChanged: (v) => setLocal(() => type = v ?? 'both'),
            ),
          ),
          const Gap(14),
          FormLabeledField(
            label: 'Telefon',
            child: TextField(
              controller: phone,
              placeholder: const Text('Opsiyonel'),
            ),
          ),
          const Gap(14),
          FormLabeledField(
            label: 'E-posta',
            child: TextField(
              controller: email,
              placeholder: const Text('Opsiyonel'),
              keyboardType: TextInputType.emailAddress,
            ),
          ),
          const Gap(14),
          FormLabeledField(
            label: 'Web sitesi',
            child: TextField(
              controller: website,
              placeholder: const Text('https://…'),
            ),
          ),
          const Gap(14),
          FormLabeledField(
            label: 'Adres',
            child: TextField(
              controller: address,
              placeholder: const Text('Opsiyonel'),
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
          const Gap(14),
          FormActiveSwitch(
            value: active,
            onChanged: (v) => setLocal(() => active = v),
          ),
        ],
      ),
    );

    if (saved != true || !mounted) return;
    final body = {
      'name': name.text.trim(),
      'type': type,
      'phone': phone.text.trim().isEmpty ? null : phone.text.trim(),
      'email': email.text.trim().isEmpty ? null : email.text.trim(),
      'website': website.text.trim().isEmpty ? null : website.text.trim(),
      'address': address.text.trim().isEmpty ? null : address.text.trim(),
      'notes': notes.text.trim().isEmpty ? null : notes.text.trim(),
      'active': active,
    };
    try {
      if (editing == null) {
        await widget.catalog.createInsurance(body);
      } else {
        await widget.catalog.updateInsurance(editing.id, body);
      }
      await _load();
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      eyebrow: 'Ağ',
      title: 'Sigorta & Kasko',
      subtitle: '${_items.length} şirket',
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
        emptyMessage: 'Kayıt yok.',
        emptySubtitle: 'Sigorta ve kasko şirketlerini ekle.',
        emptyIcon: LucideIcons.shield,
        onRetry: _load,
        child: DataPanel(
          child: ListView.builder(
            itemCount: _items.length,
            itemBuilder: (context, i) {
              final c = _items[i];
              return CatalogRow(
                leading: const AvatarTile(fallbackIcon: LucideIcons.shield),
                title: c.name,
                subtitle: c.typeLabel,
                meta: StatusPill(active: c.active),
                onEdit: () => _openForm(editing: c),
                onDelete: () async {
                  final ok = await confirmDelete(
                    context,
                    title: 'Kaydı sil',
                    message: '"${c.name}" silinsin mi?',
                  );
                  if (!ok) return;
                  try {
                    await widget.catalog.deleteInsurance(c.id);
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

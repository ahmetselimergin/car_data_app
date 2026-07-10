import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../models/models.dart';
import '../services/catalog_service.dart';
import '../widgets/common.dart';
import '../widgets/form_dialog.dart';

class WorkshopsScreen extends StatefulWidget {
  const WorkshopsScreen({super.key, required this.catalog});

  final CatalogService catalog;

  @override
  State<WorkshopsScreen> createState() => _WorkshopsScreenState();
}

class _WorkshopsScreenState extends State<WorkshopsScreen> {
  var _loading = true;
  String? _error;
  List<Workshop> _items = [];

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
      final items = await widget.catalog.listWorkshops();
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

  Future<void> _openForm({Workshop? editing}) async {
    final name = TextEditingController(text: editing?.name ?? '');
    final phone = TextEditingController(text: editing?.phone ?? '');
    final email = TextEditingController(text: editing?.email ?? '');
    final address = TextEditingController(text: editing?.address ?? '');
    final notes = TextEditingController(text: editing?.notes ?? '');
    var active = editing?.active ?? true;

    final saved = await showFormDialog(
      context: context,
      title: editing == null ? 'Yeni tamirhane' : 'Tamirhaneyi düzenle',
      builder: (ctx, setLocal) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FormLabeledField(
            label: 'Ad',
            child: TextField(
              controller: name,
              placeholder: const Text('Servis adı'),
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
      'phone': phone.text.trim().isEmpty ? null : phone.text.trim(),
      'email': email.text.trim().isEmpty ? null : email.text.trim(),
      'address': address.text.trim().isEmpty ? null : address.text.trim(),
      'notes': notes.text.trim().isEmpty ? null : notes.text.trim(),
      'active': active,
    };
    try {
      if (editing == null) {
        await widget.catalog.createWorkshop(body);
      } else {
        await widget.catalog.updateWorkshop(editing.id, body);
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
      title: 'Tamirhaneler',
      subtitle: '${_items.length} servis noktası',
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
        emptyMessage: 'Tamirhane yok.',
        emptySubtitle: 'Servis ağını buradan yönet.',
        emptyIcon: LucideIcons.wrench,
        onRetry: _load,
        child: DataPanel(
          child: ListView.builder(
            itemCount: _items.length,
            itemBuilder: (context, i) {
              final w = _items[i];
              return CatalogRow(
                leading: const AvatarTile(fallbackIcon: LucideIcons.wrench),
                title: w.name,
                subtitle: [
                  if (w.phone != null) w.phone!,
                  if (w.email != null) w.email!,
                ].join(' · '),
                meta: StatusPill(active: w.active),
                onEdit: () => _openForm(editing: w),
                onDelete: () async {
                  final ok = await confirmDelete(
                    context,
                    title: 'Tamirhaneyi sil',
                    message: '"${w.name}" silinsin mi?',
                  );
                  if (!ok) return;
                  try {
                    await widget.catalog.deleteWorkshop(w.id);
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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../models/car_model.dart';
import '../models/maintenance_item_catalog.dart';
import '../models/maintenance_model.dart';
import '../repositories/maintenance_repository.dart';
import '../services/date_helper.dart';
import '../theme/car_card_palette.dart';

bool _maintenanceListThreeLine(Maintenance m) {
  return (m.servisAdi?.trim().isNotEmpty == true) ||
      (m.notlar?.trim().isNotEmpty == true) ||
      m.bakimKalemleri.isNotEmpty ||
      m.hasDetailFlags;
}

Widget _maintenanceListSubtitle(BuildContext context, Maintenance m) {
  final TextTheme tt = Theme.of(context).textTheme;
  final Color muted =
      tt.bodySmall?.color ?? Theme.of(context).colorScheme.onSurfaceVariant;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Text(
        '${DateHelper.formatLong(m.tarih)} • ${m.km} km',
        style: tt.bodySmall,
      ),
      if (m.servisAdi?.trim().isNotEmpty == true) ...<Widget>[
        const SizedBox(height: 4),
        Text(
          m.servisAdi!.trim(),
          style: tt.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: muted,
          ),
        ),
      ],
      if (m.bakimKalemleri.isNotEmpty) ...<Widget>[
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: <Widget>[
            for (final String label in MaintenanceItemCatalog.labelsInCatalogOrder(
                m.bakimKalemleri))
              _maintenanceKalemChip(context, label),
          ],
        ),
      ],
      if (m.notlar?.trim().isNotEmpty == true) ...<Widget>[
        const SizedBox(height: 4),
        Text(
          m.notlar!.trim(),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: tt.bodySmall?.copyWith(color: muted),
        ),
      ],
      if (m.hasDetailFlags) ...<Widget>[
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: <Widget>[
            if (m.resmiServis) _maintenanceDetailChip(context, 'Resmi servis'),
            if (m.garantiKapsaminda) _maintenanceDetailChip(context, 'Garanti'),
            if (m.faturaAlindi) _maintenanceDetailChip(context, 'Fatura/fiş'),
            if (m.sigortaKarsiladi) _maintenanceDetailChip(context, 'Sigorta'),
          ],
        ),
      ],
    ],
  );
}

Widget _maintenanceDetailChip(BuildContext context, String label) {
  final ColorScheme scheme = Theme.of(context).colorScheme;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: scheme.primary.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: scheme.primary,
      ),
    ),
  );
}

Widget _maintenanceKalemChip(BuildContext context, String label) {
  final ColorScheme scheme = Theme.of(context).colorScheme;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: scheme.onSurfaceVariant,
      ),
    ),
  );
}

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key, required this.car});
  final Car car;

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  final MaintenanceRepository _repo = SqliteMaintenanceRepository();
  late Future<List<Maintenance>> _future;

  static final NumberFormat _money =
      NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Maintenance>> _load() =>
      _repo.getMaintenanceByCarId(widget.car.id!);

  void _refresh() {
    if (!mounted) return;
    setState(() {
      _future = _load();
    });
  }

  Future<void> _addEntry() async {
    final Maintenance? log = await showModalBottomSheet<Maintenance>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _MaintenanceEditor(carId: widget.car.id!),
    );
    if (log == null) return;
    await _repo.addMaintenance(log);
    _refresh();
  }

  Future<void> _delete(Maintenance log) async {
    if (log.id == null) return;
    await _repo.deleteMaintenance(log.id!);
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bakım günlüğü'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${widget.car.marka} ${widget.car.model} • ${widget.car.plaka}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addEntry,
        icon: const Icon(Icons.add),
        label: const Text('Bakım ekle'),
      ),
      body: SafeArea(
        child: FutureBuilder<List<Maintenance>>(
          future: _future,
          builder: (BuildContext context,
              AsyncSnapshot<List<Maintenance>> snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final List<Maintenance> items = snap.data ?? <Maintenance>[];
            final double total =
                items.fold<double>(0, (double s, Maintenance m) => s + m.maliyet);

            return Column(
              children: <Widget>[
                _SummaryCard(
                  car: widget.car,
                  total: total,
                  count: items.length,
                  money: _money,
                ),
                Expanded(
                  child: items.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'Henüz bakım kaydı yok.\nİlk bakımı eklemek için + tuşuna bas.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                          itemCount: items.length,
                          separatorBuilder: (BuildContext _, int _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (BuildContext c, int i) {
                            final Maintenance m = items[i];
                            return Card(
                              child: ListTile(
                                titleAlignment: ListTileTitleAlignment.top,
                                isThreeLine: _maintenanceListThreeLine(m),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                leading: const CircleAvatar(
                                  child: Icon(Icons.build_outlined),
                                ),
                                title: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Expanded(
                                      child: Text(
                                        m.islem,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _money.format(m.maliyet),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                                subtitle:
                                    _maintenanceListSubtitle(context, m),
                                trailing: IconButton(
                                  tooltip: 'Sil',
                                  icon: const Icon(Icons.delete_outline,
                                      size: 22),
                                  onPressed: () => _delete(m),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 40,
                                    minHeight: 40,
                                  ),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.car,
    required this.total,
    required this.count,
    required this.money,
  });

  final Car car;
  final double total;
  final int count;
  final NumberFormat money;

  @override
  Widget build(BuildContext context) {
    final Color accent =
        CarCardPalette.resolve(argbValue: car.cardColor, seed: car.id);
    final Color accentSoft = Color.lerp(accent, Colors.white, 0.32)!;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            accent,
            accentSoft,
          ],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Toplam harcama',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.85))),
                const SizedBox(height: 4),
                Text(
                  money.format(total),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: <Widget>[
                Text('$count',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800)),
                Text('kayıt',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MaintenanceEditor extends StatefulWidget {
  const _MaintenanceEditor({required this.carId});
  final int carId;

  @override
  State<_MaintenanceEditor> createState() => _MaintenanceEditorState();
}

class _MaintenanceEditorState extends State<_MaintenanceEditor> {
  static const double _kKalemGridHeight = 228;
  static const double _kKalemRowExtent = 46;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _islem = TextEditingController();
  final TextEditingController _km = TextEditingController();
  final TextEditingController _maliyet = TextEditingController();
  final TextEditingController _servisAdi = TextEditingController();
  final TextEditingController _kalemArama = TextEditingController();
  final Set<String> _secilenKalemIds = <String>{};
  DateTime _tarih = DateTime.now();
  bool _resmiServis = false;
  bool _garantiKapsaminda = false;
  bool _faturaAlindi = false;
  bool _sigortaKarsiladi = false;

  bool get _maliyetIstegeBagli =>
      _garantiKapsaminda || _sigortaKarsiladi;

  List<(String, String)> get _filtrelenmisKalemler {
    final String q = _kalemArama.text.trim().toLowerCase();
    if (q.isEmpty) {
      return List<(String, String)>.from(MaintenanceItemCatalog.entries);
    }
    return MaintenanceItemCatalog.entries
        .where(( (String, String) e) => e.$2.toLowerCase().contains(q))
        .toList();
  }

  void _toggleKalem(String id, bool? checked) {
    setState(() {
      if (checked == true) {
        _secilenKalemIds.add(id);
      } else {
        _secilenKalemIds.remove(id);
      }
    });
    _formKey.currentState?.validate();
  }

  @override
  void dispose() {
    _islem.dispose();
    _km.dispose();
    _maliyet.dispose();
    _servisAdi.dispose();
    _kalemArama.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _tarih,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('tr', 'TR'),
    );
    if (picked != null) setState(() => _tarih = picked);
  }

  String? _validateMaliyet(String? v) {
    final String s = (v ?? '').trim().replaceAll(',', '.');
    if (s.isEmpty) {
      return _maliyetIstegeBagli ? null : 'Maliyet gerekli';
    }
    if (double.tryParse(s) == null) {
      return 'Geçerli bir tutar gir';
    }
    return null;
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final List<String> kalemlerOrdered =
        MaintenanceItemCatalog.idsInCatalogOrder(_secilenKalemIds);
    final String manualIslem = _islem.text.trim();
    final String islem = manualIslem.isNotEmpty
        ? manualIslem
        : MaintenanceItemCatalog.joinLabels(kalemlerOrdered);
    final String rawMaliyet =
        _maliyet.text.trim().replaceAll(',', '.');
    final double maliyet = rawMaliyet.isEmpty
        ? 0
        : double.parse(rawMaliyet);
    final Maintenance log = Maintenance(
      carId: widget.carId,
      islem: islem,
      tarih: _tarih,
      km: int.parse(_km.text.trim()),
      maliyet: maliyet,
      servisAdi: _servisAdi.text.trim().isEmpty
          ? null
          : _servisAdi.text.trim(),
      notlar: null,
      bakimKalemleri: kalemlerOrdered,
      resmiServis: _resmiServis,
      garantiKapsaminda: _garantiKapsaminda,
      faturaAlindi: _faturaAlindi,
      sigortaKarsiladi: _sigortaKarsiladi,
    );
    Navigator.pop(context, log);
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme tt = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Yeni bakım kaydı',
                style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _islem,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Başlık (isteğe bağlı)',
                  hintText: 'Boş bırakırsanız seçtiklerinizden oluşturulur',
                  prefixIcon: Icon(Icons.title_outlined),
                ),
                validator: (String? v) {
                  final String t = (v ?? '').trim();
                  if (t.isNotEmpty) return null;
                  if (_secilenKalemIds.isNotEmpty) return null;
                  return 'Başlık yazın veya alttan işlem seçin';
                },
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(14),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Tarih',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  child: Text(DateHelper.formatLong(_tarih)),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextFormField(
                      controller: _km,
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: const InputDecoration(
                        labelText: 'KM',
                        prefixIcon: Icon(Icons.speed_outlined),
                      ),
                      validator: (String? v) {
                        if ((v ?? '').trim().isEmpty) return 'KM gerekli';
                        if (int.tryParse(v!.trim()) == null) {
                          return 'Geçerli bir sayı gir';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _maliyet,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9.,]')),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Maliyet (₺)',
                        hintText: _maliyetIstegeBagli ? 'İsteğe bağlı' : null,
                        prefixIcon: const Icon(Icons.payments_outlined),
                      ),
                      validator: _validateMaliyet,
                    ),
                  ),
                ],
              ),
              if (_maliyetIstegeBagli) ...<Widget>[
                const SizedBox(height: 6),
                Text(
                  'Garanti veya sigorta seçiliyse tutarı boş veya 0 bırakabilirsiniz.',
                  style: tt.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Text(
                'Ek bilgiler',
                style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _servisAdi,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Servis veya usta (isteğe bağlı)',
                  prefixIcon: Icon(Icons.storefront_outlined),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Yapılan işlemler',
                style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _kalemArama,
                onChanged: (_) => setState(() {}),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'İşlem ara…',
                  prefixIcon: const Icon(Icons.search, size: 22),
                  suffixIcon: _kalemArama.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Temizle',
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _kalemArama.clear();
                            setState(() {});
                          },
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: SizedBox(
                    height: _kKalemGridHeight,
                    child: _filtrelenmisKalemler.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                'Aramanızla eşleşen işlem yok',
                                textAlign: TextAlign.center,
                                style: tt.bodySmall?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisExtent: _kKalemRowExtent,
                              crossAxisSpacing: 4,
                              mainAxisSpacing: 2,
                            ),
                            itemCount: _filtrelenmisKalemler.length,
                            itemBuilder: (BuildContext context, int index) {
                              final (String, String) kayit =
                                  _filtrelenmisKalemler[index];
                              final String id = kayit.$1;
                              final String label = kayit.$2;
                              final bool secili =
                                  _secilenKalemIds.contains(id);
                              return InkWell(
                                onTap: () =>
                                    _toggleKalem(id, !secili),
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 2,
                                    vertical: 2,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: <Widget>[
                                      SizedBox(
                                        width: 26,
                                        height: 26,
                                        child: Checkbox(
                                          value: secili,
                                          materialTapTargetSize:
                                              MaterialTapTargetSize
                                                  .shrinkWrap,
                                          visualDensity: VisualDensity.compact,
                                          onChanged: (bool? v) =>
                                              _toggleKalem(id, v),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          label,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: tt.bodySmall?.copyWith(
                                            height: 1.15,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  _secilenKalemIds.isEmpty
                      ? 'Henüz seçim yok · Kutunun içinde kaydırarak tümünü görün'
                      : '${_secilenKalemIds.length} işlem seçildi',
                  style: tt.bodySmall?.copyWith(
                    color:
                        Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Ödeme ve belge',
                style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              CheckboxListTile(
                value: _resmiServis,
                onChanged: (bool? v) =>
                    setState(() => _resmiServis = v ?? false),
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text('Resmi yetkili serviste yapıldı'),
              ),
              CheckboxListTile(
                value: _garantiKapsaminda,
                onChanged: (bool? v) {
                  setState(() => _garantiKapsaminda = v ?? false);
                  _formKey.currentState?.validate();
                },
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text('Garanti kapsamındaydı'),
              ),
              CheckboxListTile(
                value: _faturaAlindi,
                onChanged: (bool? v) =>
                    setState(() => _faturaAlindi = v ?? false),
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text('Fatura veya fiş alındı'),
              ),
              CheckboxListTile(
                value: _sigortaKarsiladi,
                onChanged: (bool? v) {
                  setState(() => _sigortaKarsiladi = v ?? false);
                  _formKey.currentState?.validate();
                },
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text('Sigorta / kasko karşıladı'),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Kaydet'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

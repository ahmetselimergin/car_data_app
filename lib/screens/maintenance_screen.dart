import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../models/car_model.dart';
import '../models/maintenance_model.dart';
import '../repositories/maintenance_repository.dart';
import '../services/date_helper.dart';

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
                _SummaryCard(total: total, count: items.length, money: _money),
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
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 6),
                                leading: const CircleAvatar(
                                  child: Icon(Icons.build_outlined),
                                ),
                                title: Text(m.islem,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700)),
                                subtitle: Text(
                                  '${DateHelper.formatLong(m.tarih)} • ${m.km} km',
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: <Widget>[
                                    Text(_money.format(m.maliyet),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700)),
                                    IconButton(
                                      tooltip: 'Sil',
                                      icon: const Icon(Icons.delete_outline,
                                          size: 20),
                                      onPressed: () => _delete(m),
                                    ),
                                  ],
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
    required this.total,
    required this.count,
    required this.money,
  });

  final double total;
  final int count;
  final NumberFormat money;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            scheme.primary,
            scheme.primary.withValues(alpha: 0.7),
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
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _islem = TextEditingController();
  final TextEditingController _km = TextEditingController();
  final TextEditingController _maliyet = TextEditingController();
  DateTime _tarih = DateTime.now();

  @override
  void dispose() {
    _islem.dispose();
    _km.dispose();
    _maliyet.dispose();
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

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final Maintenance log = Maintenance(
      carId: widget.carId,
      islem: _islem.text.trim(),
      tarih: _tarih,
      km: int.parse(_km.text.trim()),
      maliyet: double.parse(_maliyet.text.trim().replaceAll(',', '.')),
    );
    Navigator.pop(context, log);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Yeni bakım kaydı',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _islem,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Yapılan işlem',
                hintText: 'Yağ değişimi, hava filtresi...',
                prefixIcon: Icon(Icons.build_outlined),
              ),
              validator: (String? v) =>
                  (v ?? '').trim().isEmpty ? 'İşlem gerekli' : null,
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
                    decoration: const InputDecoration(
                      labelText: 'Maliyet (₺)',
                      prefixIcon: Icon(Icons.payments_outlined),
                    ),
                    validator: (String? v) {
                      final String s =
                          (v ?? '').trim().replaceAll(',', '.');
                      if (s.isEmpty) return 'Maliyet gerekli';
                      if (double.tryParse(s) == null) {
                        return 'Geçerli bir tutar gir';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }
}

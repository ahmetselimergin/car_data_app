import 'package:flutter/material.dart';

import '../models/car_model.dart';
import '../models/reminder_model.dart';
import '../repositories/reminder_repository.dart';
import '../services/date_helper.dart';
import '../services/notification_service.dart';
import 'maintenance_screen.dart';

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key, required this.car});

  final Car car;

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  final ReminderRepository _repo = SqliteReminderRepository();
  late Future<List<Reminder>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Reminder>> _load() =>
      _repo.getRemindersByCarId(widget.car.id!);

  void _refresh() {
    if (!mounted) return;
    setState(() {
      _future = _load();
    });
  }

  Future<void> _addOrEditReminder({Reminder? existing}) async {
    final Reminder? saved = await showModalBottomSheet<Reminder>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ReminderEditor(
        carId: widget.car.id!,
        existing: existing,
      ),
    );

    if (saved == null) return;

    if (existing == null) {
      final int id = await _repo.addReminder(saved);
      final Reminder withId = saved.copyWith(id: id);
      await NotificationService.instance.scheduleReminder(
        withId,
        carLabel: '${widget.car.marka} ${widget.car.model} (${widget.car.plaka})',
      );
    } else {
      await _repo.updateReminder(saved);
      await NotificationService.instance.cancelReminder(saved.id!);
      await NotificationService.instance.scheduleReminder(
        saved,
        carLabel: '${widget.car.marka} ${widget.car.model} (${widget.car.plaka})',
      );
    }
    _refresh();
  }

  Future<void> _delete(Reminder r) async {
    if (r.id == null) return;
    await _repo.deleteReminder(r.id!);
    await NotificationService.instance.cancelReminder(r.id!);
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.car.marka} ${widget.car.model}'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Bakım günlüğü',
            icon: const Icon(Icons.build_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => MaintenanceScreen(car: widget.car),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addOrEditReminder(),
        icon: const Icon(Icons.add),
        label: const Text('Hatırlatıcı ekle'),
      ),
      body: SafeArea(
        child: FutureBuilder<List<Reminder>>(
          future: _future,
          builder: (BuildContext context, AsyncSnapshot<List<Reminder>> snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final List<Reminder> items = snap.data ?? <Reminder>[];
            if (items.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(Icons.event_note_outlined,
                          size: 56, color: Theme.of(context).hintColor),
                      const SizedBox(height: 12),
                      const Text('Henüz hatırlatıcı eklenmemiş.',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      const Text(
                          'Sigorta, kasko, muayene veya egzoz bitiş tarihi ekleyebilirsin.',
                          textAlign: TextAlign.center),
                    ],
                  ),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: items.length,
              separatorBuilder: (BuildContext _, int _) =>
                  const SizedBox(height: 10),
              itemBuilder: (BuildContext c, int i) {
                final Reminder r = items[i];
                final ReminderStatus status =
                    DateHelper.statusFor(r.bitisTarihi);
                final Color color = DateHelper.colorFor(status);
                return Dismissible(
                  key: ValueKey<int>(r.id ?? i),
                  background: Container(
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (_) async {
                    return await showDialog<bool>(
                          context: context,
                          builder: (BuildContext c) => AlertDialog(
                            title: const Text('Sil'),
                            content: Text(
                                '${r.tur.label} hatırlatıcısı silinsin mi?'),
                            actions: <Widget>[
                              TextButton(
                                  onPressed: () => Navigator.pop(c, false),
                                  child: const Text('Vazgeç')),
                              FilledButton(
                                  onPressed: () => Navigator.pop(c, true),
                                  child: const Text('Sil')),
                            ],
                          ),
                        ) ??
                        false;
                  },
                  onDismissed: (_) => _delete(r),
                  child: Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      onTap: () => _addOrEditReminder(existing: r),
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child:
                            Icon(DateHelper.iconFor(status), color: color),
                      ),
                      title: Text(
                        r.tur.label,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        '${DateHelper.formatLong(r.bitisTarihi)}\n'
                        '${DateHelper.humanizeRemaining(r.bitisTarihi)} • ${status.label}',
                        style: TextStyle(color: color),
                      ),
                      isThreeLine: true,
                      trailing: const Icon(Icons.chevron_right),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _ReminderEditor extends StatefulWidget {
  const _ReminderEditor({required this.carId, this.existing});

  final int carId;
  final Reminder? existing;

  @override
  State<_ReminderEditor> createState() => _ReminderEditorState();
}

class _ReminderEditorState extends State<_ReminderEditor> {
  late ReminderType _tur;
  DateTime? _date;

  @override
  void initState() {
    super.initState();
    _tur = widget.existing?.tur ?? ReminderType.sigorta;
    _date = widget.existing?.bitisTarihi;
  }

  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime initial = _date ?? now;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
      helpText: 'Bitiş tarihini seç',
      locale: const Locale('tr', 'TR'),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _submit() {
    if (_date == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir bitiş tarihi seç')),
      );
      return;
    }
    final Reminder r = Reminder(
      id: widget.existing?.id,
      carId: widget.carId,
      tur: _tur,
      bitisTarihi: _date!,
      hatirlatmaYapildiMi: widget.existing?.hatirlatmaYapildiMi ?? false,
    );
    Navigator.pop(context, r);
  }

  @override
  Widget build(BuildContext context) {
    final ReminderStatus? status =
        _date == null ? null : DateHelper.statusFor(_date!);
    final Color? color =
        status == null ? null : DateHelper.colorFor(status);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            widget.existing == null
                ? 'Yeni hatırlatıcı'
                : 'Hatırlatıcıyı düzenle',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ReminderType.values.map((ReminderType t) {
              final bool selected = t == _tur;
              return ChoiceChip(
                label: Text(t.label),
                selected: selected,
                onSelected: (_) => setState(() => _tur = t),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Row(
                children: <Widget>[
                  Icon(Icons.calendar_today_outlined,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text('Bitiş tarihi',
                            style: TextStyle(fontSize: 12)),
                        const SizedBox(height: 2),
                        Text(
                          _date == null
                              ? 'Tarih seçilmedi'
                              : DateHelper.formatLong(_date!),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _date == null
                                ? Theme.of(context).hintColor
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (status != null)
                    Icon(DateHelper.iconFor(status), color: color),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (status != null && color != null)
            Row(
              children: <Widget>[
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                      color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text(
                  '${status.label} • ${DateHelper.humanizeRemaining(_date!)}',
                  style:
                      TextStyle(color: color, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }
}

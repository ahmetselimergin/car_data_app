import 'package:flutter/material.dart';
import 'package:ms_undraw/ms_undraw.dart';

import '../l10n/l10n_ext.dart';
import '../models/car_model.dart';
import '../models/reminder_model.dart';
import '../repositories/reminder_repository.dart';
import '../services/date_helper.dart';
import '../services/notification_service.dart';
import '../theme/car_card_palette.dart';
import '../widgets/undraw_empty_state.dart';
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
    final AppLocalizations l10n = context.l10n;
    final String localeTag =
        localeTagFor(Localizations.localeOf(context));

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.car.marka} ${widget.car.model}'),
        actions: <Widget>[
          IconButton(
            tooltip: l10n.maintenanceLogTooltip,
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
        label: Text(l10n.addReminder),
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
              final Color accent = CarCardPalette.resolve(
                argbValue: widget.car.cardColor,
                seed: widget.car.id,
              );
              return Center(
                child: UndrawEmptyState(
                  illustration: UnDrawIllustration.digital_calendar,
                  title: l10n.remindersEmptyTitle,
                  subtitle: l10n.remindersEmptySubtitle,
                  color: accent,
                  height: 190,
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
                            title: Text(l10n.delete),
                            content: Text(
                              l10n.deleteReminderMessage(
                                r.tur.localizedLabel(l10n),
                              ),
                            ),
                            actions: <Widget>[
                              TextButton(
                                  onPressed: () => Navigator.pop(c, false),
                                  child: Text(l10n.dismiss)),
                              FilledButton(
                                  onPressed: () => Navigator.pop(c, true),
                                  child: Text(l10n.delete)),
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
                        r.tur.localizedLabel(l10n),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        '${DateHelper.formatLong(r.bitisTarihi, localeTag)}\n'
                        '${humanizeRemaining(l10n, r.bitisTarihi)} • ${status.localizedLabel(l10n)}',
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
      helpText: context.l10n.selectExpiryDate,
      locale: Localizations.localeOf(context),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _submit() {
    if (_date == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.expiryDateRequired)),
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
    final AppLocalizations l10n = context.l10n;
    final String localeTag =
        localeTagFor(Localizations.localeOf(context));
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
            widget.existing == null ? l10n.newReminder : l10n.editReminder,
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
                label: Text(t.localizedLabel(l10n)),
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
                        Text(l10n.expiryDateLabel,
                            style: const TextStyle(fontSize: 12)),
                        const SizedBox(height: 2),
                        Text(
                          _date == null
                              ? l10n.dateNotSelected
                              : DateHelper.formatLong(_date!, localeTag),
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
                  '${status.localizedLabel(l10n)} • ${humanizeRemaining(l10n, _date!)}',
                  style:
                      TextStyle(color: color, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.save_outlined),
            label: Text(l10n.saveButton),
          ),
        ],
      ),
    );
  }
}

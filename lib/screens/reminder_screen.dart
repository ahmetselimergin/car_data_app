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

IconData _iconForReminderType(ReminderType t) {
  switch (t) {
    case ReminderType.sigorta:
      return Icons.shield_outlined;
    case ReminderType.kasko:
      return Icons.security_outlined;
    case ReminderType.muayene:
      return Icons.fact_check_outlined;
    case ReminderType.egzoz:
      return Icons.air;
  }
}

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key, required this.car});

  final Car car;

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  final ReminderRepository _repo = SqliteReminderRepository();
  late Future<List<Reminder>> _future;
  bool _didChange = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Reminder>> _load() =>
      _repo.getRemindersByCarId(widget.car.id!);

  void _refresh() {
    if (!mounted) return;
    _didChange = true;
    setState(() {
      _future = _load();
    });
  }

  Future<void> _addOrEditReminder({Reminder? existing}) async {
    final List<Reminder> current = await _load();
    final Set<ReminderType> taken = current
        .where((Reminder r) => existing == null || r.id != existing.id)
        .map((Reminder r) => r.tur)
        .toSet();

    if (existing == null && taken.length >= ReminderType.values.length) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.reminderAllTypesExist)),
      );
      return;
    }

    final List<ReminderType> available = existing != null
        ? <ReminderType>[existing.tur]
        : ReminderType.values
            .where((ReminderType t) => !taken.contains(t))
            .toList();

    if (available.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.reminderAllTypesExist)),
      );
      return;
    }

    if (!mounted) return;
    final Reminder? saved = await showModalBottomSheet<Reminder>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: const Color(0xFFF7F8FA),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _ReminderEditor(
        carId: widget.car.id!,
        existing: existing,
        availableTypes: available,
      ),
    );

    if (saved == null) return;

    if (existing == null) {
      final List<Reminder> latest = await _load();
      if (latest.any((Reminder r) => r.tur == saved.tur)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.reminderTypeAlreadyExists(
                saved.tur.localizedLabel(context.l10n),
              ),
            ),
          ),
        );
        return;
      }
      final int id = await _repo.addReminder(saved);
      final Reminder withId = saved.copyWith(id: id);
      await NotificationService.instance.scheduleReminder(
        withId,
        carLabel: '${widget.car.marka} ${widget.car.model} (${widget.car.plaka})',
      );
    } else {
      await _repo.updateReminder(saved);
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        Navigator.of(context).pop(_didChange);
      },
      child: Scaffold(
      appBar: AppBar(
        title: Text('${widget.car.marka} ${widget.car.model}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(_didChange),
        ),
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
                            actionsPadding: const EdgeInsets.fromLTRB(
                              16,
                              0,
                              16,
                              16,
                            ),
                            actions: <Widget>[
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () =>
                                          Navigator.pop(c, false),
                                      icon: const Icon(
                                        Icons.close_rounded,
                                        size: 18,
                                      ),
                                      label: Text(l10n.dismiss),
                                      style: OutlinedButton.styleFrom(
                                        minimumSize:
                                            const Size.fromHeight(48),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: FilledButton.icon(
                                      onPressed: () =>
                                          Navigator.pop(c, true),
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        size: 18,
                                      ),
                                      label: Text(l10n.delete),
                                      style: FilledButton.styleFrom(
                                        minimumSize:
                                            const Size.fromHeight(48),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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
      ),
    );
  }
}

class _ReminderEditor extends StatefulWidget {
  const _ReminderEditor({
    required this.carId,
    required this.availableTypes,
    this.existing,
  });

  final int carId;
  final Reminder? existing;
  final List<ReminderType> availableTypes;

  @override
  State<_ReminderEditor> createState() => _ReminderEditorState();
}

class _ReminderEditorState extends State<_ReminderEditor> {
  late ReminderType _tur;
  DateTime? _date;

  @override
  void initState() {
    super.initState();
    _tur = widget.existing?.tur ?? widget.availableTypes.first;
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
    final String localeTag = localeTagFor(Localizations.localeOf(context));
    final ReminderStatus? status =
        _date == null ? null : DateHelper.statusFor(_date!);
    final Color? statusColor =
        status == null ? null : DateHelper.colorFor(status);
    final bool locked = widget.existing != null;
    final bool isTr =
        Localizations.localeOf(context).languageCode == 'tr';

    return Padding(
      padding: EdgeInsets.only(
        left: 22,
        right: 22,
        top: 4,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F4F5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _iconForReminderType(_tur),
                  color: const Color(0xFF18181B),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      widget.existing == null
                          ? l10n.newReminder
                          : l10n.editReminder,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        color: Color(0xFF18181B),
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _tur.localizedLabel(l10n),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            isTr ? 'Tür' : 'Type',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.black.withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: widget.availableTypes.map((ReminderType t) {
              final bool selected = t == _tur;
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: locked ? null : () => setState(() => _tur = t),
                  borderRadius: BorderRadius.circular(18),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    width: 104,
                    height: 88,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFF18181B)
                            : const Color(0xFFE4E4E7),
                        width: selected ? 1.75 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          _iconForReminderType(t),
                          color: selected
                              ? const Color(0xFF18181B)
                              : const Color(0xFF71717A),
                          size: 22,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          t.localizedLabel(l10n),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                selected ? FontWeight.w800 : FontWeight.w600,
                            color: selected
                                ? const Color(0xFF18181B)
                                : const Color(0xFF3F3F46),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 22),
          Text(
            l10n.expiryDateLabel,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.black.withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(height: 10),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(20),
              child: Ink(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: statusColor?.withValues(alpha: 0.55) ??
                        const Color(0xFFE4E4E7),
                    width: status != null ? 1.5 : 1,
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F4F5),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.calendar_month_rounded,
                        color: Color(0xFF18181B),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            l10n.expiryDateLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.black.withValues(alpha: 0.4),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _date == null
                                ? l10n.dateNotSelected
                                : DateHelper.formatLong(_date!, localeTag),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _date == null
                                  ? const Color(0xFFA1A1AA)
                                  : const Color(0xFF18181B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.black.withValues(alpha: 0.28),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (status != null && statusColor != null) ...<Widget>[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: <Widget>[
                  Icon(DateHelper.iconFor(status), color: statusColor, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${status.localizedLabel(l10n)} · ${humanizeRemaining(l10n, _date!)}',
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 26),
          SizedBox(
            height: 54,
            child: FilledButton(
              onPressed: _submit,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF18181B),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: Text(
                l10n.saveButton,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

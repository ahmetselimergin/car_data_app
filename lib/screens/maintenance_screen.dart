import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:ms_undraw/ms_undraw.dart';

import '../l10n/l10n_ext.dart';
import '../models/car_model.dart';
import '../models/maintenance_item_catalog.dart';
import '../models/maintenance_model.dart';
import '../repositories/maintenance_repository.dart';
import '../repositories/supabase_maintenance_repository.dart';
import '../services/date_helper.dart';
import '../services/distance_unit_controller.dart';
import '../theme/car_card_palette.dart';
import '../utils/distance_format.dart';
import '../utils/user_facing_error.dart';
import '../widgets/app_confirm_dialog.dart';
import '../widgets/load_error_view.dart';
import '../widgets/undraw_empty_state.dart';

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
  final MaintenanceRepository _repo = SupabaseMaintenanceRepository();
  late Future<List<Maintenance>> _future;

  NumberFormat _moneyFor(BuildContext context) => NumberFormat.currency(
        locale: localeTagFor(Localizations.localeOf(context)),
        symbol: '₺',
        decimalDigits: 2,
      );

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

  Future<void> _openEditor({Maintenance? existing}) async {
    try {
      final Maintenance? log = await showModalBottomSheet<Maintenance>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        backgroundColor: const Color(0xFFF7F8FA),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (_) => _MaintenanceEditor(
          carId: widget.car.id!,
          existing: existing,
        ),
      );
      if (log == null) return;
      if (existing == null) {
        await _repo.addMaintenance(log);
      } else {
        await _repo.updateMaintenance(log);
      }
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFacingError(e, context.l10n))),
      );
    }
  }

  Future<void> _addEntry() => _openEditor();

  Future<void> _delete(Maintenance log) async {
    if (log.id == null) return;
    final AppLocalizations l10n = context.l10n;
    final bool ok = await showAppConfirmDialog(
      context: context,
      title: l10n.delete,
      message: l10n.deleteMaintenanceMessage,
      confirmLabel: l10n.delete,
      destructive: true,
      confirmIcon: Icons.delete_outline_rounded,
    );
    if (!ok || !mounted) return;
    try {
      await _repo.deleteMaintenance(log.id!);
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFacingError(e, context.l10n))),
      );
    }
  }

  Future<void> _openDetail(Maintenance log) async {
    final String? action = await showGeneralDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (BuildContext ctx, Animation<double> a1, Animation<double> a2) {
        return Align(
          alignment: Alignment.centerRight,
          child: _MaintenanceDetailShelf(
            log: log,
            money: _moneyFor(ctx),
          ),
        );
      },
      transitionBuilder: (
        BuildContext ctx,
        Animation<double> anim,
        Animation<double> _,
        Widget child,
      ) {
        final Animation<Offset> slide = Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
        return SlideTransition(position: slide, child: child);
      },
    );
    if (!mounted || action == null) return;
    if (action == 'edit') {
      await _openEditor(existing: log);
    } else if (action == 'delete') {
      await _delete(log);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final NumberFormat money = _moneyFor(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.maintenanceLogTitle),
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
        label: Text(l10n.addMaintenance),
      ),
      body: SafeArea(
        child: FutureBuilder<List<Maintenance>>(
          future: _future,
          builder: (BuildContext context,
              AsyncSnapshot<List<Maintenance>> snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return LoadErrorView(onRetry: _refresh);
            }
            final List<Maintenance> items = snap.data ?? <Maintenance>[];
            final double total =
                items.fold<double>(0, (double s, Maintenance m) => s + m.maliyet);

            final Color accent = CarCardPalette.resolve(
              argbValue: widget.car.cardColor,
              seed: widget.car.id,
            );

            return Column(
              children: <Widget>[
                _SummaryCard(
                  car: widget.car,
                  total: total,
                  count: items.length,
                  money: money,
                ),
                Expanded(
                  child: items.isEmpty
                      ? Center(
                          child: UndrawEmptyState(
                            illustration: UnDrawIllustration.car_repair,
                            title: l10n.noMaintenanceYet,
                            subtitle: l10n.maintenanceEmpty,
                            color: accent,
                            height: 190,
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                          itemCount: items.length,
                          separatorBuilder: (BuildContext _, int _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (BuildContext c, int i) {
                            final Maintenance m = items[i];
                            final String localeTag = localeTagFor(
                              Localizations.localeOf(context),
                            );
                            return Material(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(18),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: () => _openDetail(m),
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    14,
                                    14,
                                    10,
                                    14,
                                  ),
                                  child: Row(
                                    children: <Widget>[
                                      CircleAvatar(
                                        backgroundColor: accent
                                            .withValues(alpha: 0.16),
                                        child: Icon(
                                          Icons.build_outlined,
                                          color: accent,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: <Widget>[
                                            Text(
                                              m.islem,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 15,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${DateHelper.formatLong(m.tarih, localeTag)} • ${DistanceFormat.format(
                                                m.km,
                                                unit: DistanceUnitController
                                                    .instance.value,
                                                localeTag: localeTag,
                                                l10n: l10n,
                                              )}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        money.format(m.maliyet),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Icon(
                                        Icons.chevron_right_rounded,
                                        color: Colors.black
                                            .withValues(alpha: 0.28),
                                      ),
                                    ],
                                  ),
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

class _MaintenanceDetailShelf extends StatelessWidget {
  const _MaintenanceDetailShelf({
    required this.log,
    required this.money,
  });

  final Maintenance log;
  final NumberFormat money;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final String localeTag = localeTagFor(Localizations.localeOf(context));
    final double width = MediaQuery.sizeOf(context).width * 0.88;
    final TextTheme tt = Theme.of(context).textTheme;

    return Material(
      color: const Color(0xFFF7F8FA),
      elevation: 12,
      shadowColor: Colors.black26,
      borderRadius: const BorderRadius.horizontal(left: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: width.clamp(280.0, 420.0).toDouble(),
        height: MediaQuery.sizeOf(context).height,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        log.islem,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: Color(0xFF18181B),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.dismiss,
                      onPressed: () => Navigator.pop(context),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFF4F4F5),
                      ),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE4E4E7)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              money.format(log.maliyet),
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF18181B),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              DateHelper.formatLong(log.tarih, localeTag),
                              style: tt.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DistanceFormat.format(
                                log.km,
                                unit: DistanceUnitController.instance.value,
                                localeTag: localeTag,
                                l10n: l10n,
                              ),
                              style: tt.bodySmall?.copyWith(
                                color: const Color(0xFF71717A),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (log.servisAdi?.trim().isNotEmpty == true) ...<Widget>[
                        const SizedBox(height: 14),
                        Text(
                          l10n.additionalInfo,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.black.withValues(alpha: 0.45),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border:
                                Border.all(color: const Color(0xFFE4E4E7)),
                          ),
                          child: Row(
                            children: <Widget>[
                              const Icon(
                                Icons.storefront_outlined,
                                size: 20,
                                color: Color(0xFF71717A),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  log.servisAdi!.trim(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (log.bakimKalemleri.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 14),
                        Text(
                          l10n.workPerformed,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.black.withValues(alpha: 0.45),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: <Widget>[
                            for (final String label
                                in MaintenanceItemCatalog.labelsInCatalogOrder(
                              l10n,
                              log.bakimKalemleri,
                            ))
                              _maintenanceKalemChip(context, label),
                          ],
                        ),
                      ],
                      if (log.hasDetailFlags) ...<Widget>[
                        const SizedBox(height: 14),
                        Text(
                          l10n.paymentAndDocuments,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.black.withValues(alpha: 0.45),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: <Widget>[
                            if (log.resmiServis)
                              _maintenanceDetailChip(
                                context,
                                l10n.officialService,
                              ),
                            if (log.garantiKapsaminda)
                              _maintenanceDetailChip(context, l10n.warranty),
                            if (log.faturaAlindi)
                              _maintenanceDetailChip(
                                context,
                                l10n.invoiceReceipt,
                              ),
                            if (log.sigortaKarsiladi)
                              _maintenanceDetailChip(
                                context,
                                l10n.insurance,
                              ),
                          ],
                        ),
                      ],
                      if (log.hasAttachment) ...<Widget>[
                        const SizedBox(height: 14),
                        Text(
                          l10n.attachmentLabel,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.black.withValues(alpha: 0.45),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _AttachmentPreview(
                          url: log.attachmentUrl!,
                          openLabel: l10n.openAttachment,
                        ),
                      ],
                      if (log.notlar?.trim().isNotEmpty == true) ...<Widget>[
                        const SizedBox(height: 14),
                        Text(
                          log.notlar!.trim(),
                          style: tt.bodyMedium?.copyWith(
                            color: const Color(0xFF52525B),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context, 'delete'),
                        icon: const Icon(Icons.delete_outline_rounded, size: 18),
                        label: Text(l10n.delete),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFB91C1C),
                          side: BorderSide(
                            color: const Color(0xFFB91C1C)
                                .withValues(alpha: 0.35),
                          ),
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => Navigator.pop(context, 'edit'),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: Text(l10n.editAction),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
    final AppLocalizations l10n = context.l10n;
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
                Text(l10n.totalSpending,
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
                Text(l10n.recordsCount,
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
  const _MaintenanceEditor({
    required this.carId,
    this.existing,
  });
  final int carId;
  final Maintenance? existing;

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
  String? _attachmentPath;
  DistanceUnit _distanceUnit = DistanceUnitController.instance.value;

  bool get _maliyetIstegeBagli =>
      _garantiKapsaminda || _sigortaKarsiladi;

  List<String> _filtrelenmisKalemIds(AppLocalizations l10n) {
    final String q = _kalemArama.text.trim().toLowerCase();
    if (q.isEmpty) {
      return MaintenanceItemCatalog.entries.map((e) => e.$1).toList();
    }
    return MaintenanceItemCatalog.entries
        .where((e) =>
            maintenanceItemLabel(l10n, e.$1).toLowerCase().contains(q))
        .map((e) => e.$1)
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
  void initState() {
    super.initState();
    _distanceUnit = DistanceUnitController.instance.value;
    DistanceUnitController.instance.addListener(_onDistanceUnitChanged);
    final Maintenance? e = widget.existing;
    if (e != null) {
      _islem.text = e.islem;
      _km.text = DistanceFormat.toInputText(e.km, _distanceUnit);
      _maliyet.text = e.maliyet == 0
          ? ''
          : e.maliyet.toStringAsFixed(
              e.maliyet.truncateToDouble() == e.maliyet ? 0 : 2,
            );
      _servisAdi.text = e.servisAdi ?? '';
      _secilenKalemIds.addAll(e.bakimKalemleri);
      _tarih = e.tarih;
      _resmiServis = e.resmiServis;
      _garantiKapsaminda = e.garantiKapsaminda;
      _faturaAlindi = e.faturaAlindi;
      _sigortaKarsiladi = e.sigortaKarsiladi;
      _attachmentPath = e.attachmentUrl;
    }
  }

  void _onDistanceUnitChanged() {
    final DistanceUnit next = DistanceUnitController.instance.value;
    if (next == _distanceUnit) return;
    setState(() {
      _km.text = DistanceFormat.convertInputText(_km.text, _distanceUnit, next);
      _distanceUnit = next;
    });
  }

  @override
  void dispose() {
    DistanceUnitController.instance.removeListener(_onDistanceUnitChanged);
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
      locale: Localizations.localeOf(context),
    );
    if (picked != null) setState(() => _tarih = picked);
  }

  String? _validateMaliyet(String? v, AppLocalizations l10n) {
    final String s = (v ?? '').trim().replaceAll(',', '.');
    if (s.isEmpty) {
      return _maliyetIstegeBagli ? null : l10n.costRequired;
    }
    if (double.tryParse(s) == null) {
      return l10n.enterValidAmount;
    }
    return null;
  }

  Future<void> _pickAttachment() async {
    final ImagePicker picker = ImagePicker();
    final XFile? file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null) return;
    setState(() => _attachmentPath = file.path);
  }

  void _removeAttachment() {
    setState(() => _attachmentPath = null);
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final AppLocalizations l10n = context.l10n;
    final List<String> kalemlerOrdered =
        MaintenanceItemCatalog.idsInCatalogOrder(_secilenKalemIds);
    final String manualIslem = _islem.text.trim();
    final String islem = manualIslem.isNotEmpty
        ? manualIslem
        : MaintenanceItemCatalog.joinLabels(l10n, kalemlerOrdered);
    final String rawMaliyet =
        _maliyet.text.trim().replaceAll(',', '.');
    final double maliyet = rawMaliyet.isEmpty
        ? 0
        : double.parse(rawMaliyet);
    final String? attachment =
        (_attachmentPath == null || _attachmentPath!.trim().isEmpty)
            ? null
            : _attachmentPath!.trim();
    final Maintenance log = Maintenance(
      id: widget.existing?.id,
      carId: widget.carId,
      islem: islem,
      tarih: _tarih,
      km: DistanceFormat.parseInput(_km.text.trim(), _distanceUnit),
      maliyet: maliyet,
      servisAdi: _servisAdi.text.trim().isEmpty
          ? null
          : _servisAdi.text.trim(),
      notlar: widget.existing?.notlar,
      bakimKalemleri: kalemlerOrdered,
      attachmentUrl: attachment,
      resmiServis: _resmiServis,
      garantiKapsaminda: _garantiKapsaminda,
      faturaAlindi: _faturaAlindi,
      sigortaKarsiladi: _sigortaKarsiladi,
    );
    Navigator.pop(context, log);
  }

  void _close() => Navigator.pop(context);

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Colors.black.withValues(alpha: 0.45),
      ),
    );
  }

  Widget _flagChip({
    required String label,
    required bool selected,
    required ValueChanged<bool> onChanged,
  }) {
    return FilterChip(
      selected: selected,
      onSelected: onChanged,
      showCheckmark: false,
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: selected ? const Color(0xFF18181B) : const Color(0xFF52525B),
      ),
      selectedColor: Colors.white,
      backgroundColor: Colors.white,
      side: BorderSide(
        color: selected ? const Color(0xFF18181B) : const Color(0xFFE4E4E7),
        width: selected ? 1.6 : 1,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final String localeTag = localeTagFor(Localizations.localeOf(context));
    final TextTheme tt = Theme.of(context).textTheme;
    final DistanceUnit unit = _distanceUnit;
    final List<String> filtrelenmisIds = _filtrelenmisKalemIds(l10n);
    final double maxH = MediaQuery.sizeOf(context).height * 0.92;
    final double bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxH),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 12, 0),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F4F5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.build_circle_outlined,
                        color: Color(0xFF18181B),
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        widget.existing == null
                            ? l10n.newMaintenanceEntry
                            : l10n.editMaintenanceEntry,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color: Color(0xFF18181B),
                          height: 1.15,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.dismiss,
                      onPressed: _close,
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFF4F4F5),
                        foregroundColor: const Color(0xFF18181B),
                      ),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      TextFormField(
                        controller: _islem,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          labelText: l10n.titleOptional,
                          hintText: l10n.titleHint,
                          prefixIcon: const Icon(Icons.title_outlined),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (String? v) {
                          final String t = (v ?? '').trim();
                          if (t.isNotEmpty) return null;
                          if (_secilenKalemIds.isNotEmpty) return null;
                          return l10n.titleOrItemsRequired;
                        },
                      ),
                      const SizedBox(height: 12),
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
                                color: const Color(0xFFE4E4E7),
                              ),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        l10n.dateLabel,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black
                                              .withValues(alpha: 0.4),
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        DateHelper.formatLong(
                                          _tarih,
                                          localeTag,
                                        ),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF18181B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color:
                                      Colors.black.withValues(alpha: 0.28),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(
                            child: TextFormField(
                              controller: _km,
                              keyboardType: TextInputType.number,
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: InputDecoration(
                                labelText:
                                    DistanceFormat.fieldLabel(l10n, unit),
                                hintText:
                                    DistanceFormat.fieldHint(l10n, unit),
                                prefixIcon:
                                    const Icon(Icons.speed_outlined),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              validator: (String? v) {
                                if ((v ?? '').trim().isEmpty) {
                                  return DistanceFormat.fieldRequired(
                                    l10n,
                                    unit,
                                  );
                                }
                                if (int.tryParse(v!.trim()) == null) {
                                  return l10n.enterValidNumber;
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _maliyet,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9.,]'),
                                ),
                              ],
                              decoration: InputDecoration(
                                labelText: l10n.costLabel,
                                hintText: _maliyetIstegeBagli
                                    ? l10n.optional
                                    : null,
                                prefixIcon:
                                    const Icon(Icons.payments_outlined),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              validator: (String? v) =>
                                  _validateMaliyet(v, l10n),
                            ),
                          ),
                        ],
                      ),
                      if (_maliyetIstegeBagli) ...<Widget>[
                        const SizedBox(height: 6),
                        Text(
                          l10n.costOptionalWithWarranty,
                          style: tt.bodySmall?.copyWith(
                            color: const Color(0xFF71717A),
                          ),
                        ),
                      ],
                      const SizedBox(height: 22),
                      _sectionLabel(l10n.additionalInfo),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _servisAdi,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: l10n.serviceShopLabel,
                          prefixIcon:
                              const Icon(Icons.storefront_outlined),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 22),
                      _sectionLabel(l10n.workPerformed),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _kalemArama,
                        onChanged: (_) => setState(() {}),
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: l10n.searchWorkHint,
                          prefixIcon: const Icon(Icons.search, size: 22),
                          suffixIcon: _kalemArama.text.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: l10n.clear,
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _kalemArama.clear();
                                    setState(() {});
                                  },
                                ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFFE4E4E7),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFF18181B),
                              width: 1.4,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 10),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                            color: const Color(0xFFE4E4E7),
                          ),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(17),
                          child: SizedBox(
                            height: _kKalemGridHeight,
                            child: filtrelenmisIds.isEmpty
                                ? Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Text(
                                        l10n.noMatchingWork,
                                        textAlign: TextAlign.center,
                                        style: tt.bodySmall?.copyWith(
                                          color: const Color(0xFF71717A),
                                        ),
                                      ),
                                    ),
                                  )
                                : GridView.builder(
                                    padding: const EdgeInsets.fromLTRB(
                                      8,
                                      10,
                                      8,
                                      10,
                                    ),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      mainAxisExtent: _kKalemRowExtent,
                                      crossAxisSpacing: 4,
                                      mainAxisSpacing: 2,
                                    ),
                                    itemCount: filtrelenmisIds.length,
                                    itemBuilder:
                                        (BuildContext context, int index) {
                                      final String id =
                                          filtrelenmisIds[index];
                                      final String label =
                                          maintenanceItemLabel(l10n, id);
                                      final bool secili =
                                          _secilenKalemIds.contains(id);
                                      return InkWell(
                                        onTap: () =>
                                            _toggleKalem(id, !secili),
                                        borderRadius:
                                            BorderRadius.circular(10),
                                        child: Padding(
                                          padding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 2,
                                            vertical: 2,
                                          ),
                                          child: Row(
                                            children: <Widget>[
                                              SizedBox(
                                                width: 26,
                                                height: 26,
                                                child: Checkbox(
                                                  value: secili,
                                                  materialTapTargetSize:
                                                      MaterialTapTargetSize
                                                          .shrinkWrap,
                                                  visualDensity:
                                                      VisualDensity
                                                          .compact,
                                                  onChanged: (bool? v) =>
                                                      _toggleKalem(id, v),
                                                ),
                                              ),
                                              Expanded(
                                                child: Text(
                                                  label,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: tt.bodySmall
                                                      ?.copyWith(
                                                    height: 1.15,
                                                    fontWeight: secili
                                                        ? FontWeight.w700
                                                        : FontWeight.w500,
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
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _secilenKalemIds.isEmpty
                              ? l10n.noItemsSelectedHint
                              : l10n.itemsSelectedCount(
                                  _secilenKalemIds.length,
                                ),
                          style: tt.bodySmall?.copyWith(
                            color: const Color(0xFF71717A),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      _sectionLabel(l10n.paymentAndDocuments),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: <Widget>[
                          _flagChip(
                            label: l10n.flagOfficialShort,
                            selected: _resmiServis,
                            onChanged: (bool v) =>
                                setState(() => _resmiServis = v),
                          ),
                          _flagChip(
                            label: l10n.flagWarrantyShort,
                            selected: _garantiKapsaminda,
                            onChanged: (bool v) {
                              setState(() => _garantiKapsaminda = v);
                              _formKey.currentState?.validate();
                            },
                          ),
                          _flagChip(
                            label: l10n.flagReceiptShort,
                            selected: _faturaAlindi,
                            onChanged: (bool v) =>
                                setState(() => _faturaAlindi = v),
                          ),
                          _flagChip(
                            label: l10n.flagInsuranceShort,
                            selected: _sigortaKarsiladi,
                            onChanged: (bool v) {
                              setState(() => _sigortaKarsiladi = v);
                              _formKey.currentState?.validate();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _sectionLabel(l10n.attachmentLabel),
                      const SizedBox(height: 10),
                      if (_attachmentPath != null &&
                          _attachmentPath!.trim().isNotEmpty) ...<Widget>[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: AspectRatio(
                            aspectRatio: 16 / 9,
                            child: _attachmentPath!.startsWith('http')
                                ? Image.network(
                                    _attachmentPath!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Container(
                                      color: const Color(0xFFF4F4F5),
                                      alignment: Alignment.center,
                                      child: const Icon(Icons.broken_image_outlined),
                                    ),
                                  )
                                : Image.file(
                                    File(_attachmentPath!),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Container(
                                      color: const Color(0xFFF4F4F5),
                                      alignment: Alignment.center,
                                      child: const Icon(Icons.broken_image_outlined),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _pickAttachment,
                                icon: const Icon(Icons.photo_outlined, size: 18),
                                label: Text(l10n.changeAttachment),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              tooltip: l10n.removeAttachment,
                              onPressed: _removeAttachment,
                              style: IconButton.styleFrom(
                                backgroundColor: const Color(0xFFFEE2E2),
                                foregroundColor: const Color(0xFFB91C1C),
                              ),
                              icon: const Icon(Icons.delete_outline_rounded),
                            ),
                          ],
                        ),
                      ] else
                        OutlinedButton.icon(
                          onPressed: _pickAttachment,
                          icon: const Icon(Icons.add_photo_alternate_outlined),
                          label: Text(l10n.addAttachment),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            foregroundColor: const Color(0xFF18181B),
                            side: const BorderSide(color: Color(0xFFE4E4E7)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _close,
                        icon: const Icon(Icons.close_rounded, size: 18),
                        label: Text(l10n.dismiss),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          foregroundColor: const Color(0xFF18181B),
                          side: const BorderSide(color: Color(0xFFE4E4E7)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: FilledButton.icon(
                        onPressed: _submit,
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: Text(l10n.saveButton),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttachmentPreview extends StatelessWidget {
  const _AttachmentPreview({
    required this.url,
    required this.openLabel,
  });

  final String url;
  final String openLabel;

  bool get _isRemote =>
      url.startsWith('http://') || url.startsWith('https://');

  Future<void> _open(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: InteractiveViewer(
            child: _isRemote
                ? Image.network(url, fit: BoxFit.contain)
                : Image.file(File(url), fit: BoxFit.contain),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: _isRemote
                ? Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: const Color(0xFFF4F4F5),
                      alignment: Alignment.center,
                      child: const Icon(Icons.broken_image_outlined),
                    ),
                  )
                : Image.file(
                    File(url),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: const Color(0xFFF4F4F5),
                      alignment: Alignment.center,
                      child: const Icon(Icons.broken_image_outlined),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _open(context),
          icon: const Icon(Icons.open_in_full_rounded, size: 18),
          label: Text(openLabel),
        ),
      ],
    );
  }
}

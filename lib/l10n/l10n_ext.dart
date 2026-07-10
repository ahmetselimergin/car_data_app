import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/app_localizations.dart';
import '../models/maintenance_item_catalog.dart';
import '../models/reminder_model.dart';
import '../services/date_helper.dart';

export '../l10n/app_localizations.dart';

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

extension ReminderTypeL10n on ReminderType {
  String localizedLabel(AppLocalizations l10n) {
    switch (this) {
      case ReminderType.sigorta:
        return l10n.reminderTypeInsurance;
      case ReminderType.kasko:
        return l10n.reminderTypeComprehensive;
      case ReminderType.muayene:
        return l10n.reminderTypeInspection;
      case ReminderType.egzoz:
        return l10n.reminderTypeEmissions;
    }
  }
}

extension ReminderStatusL10n on ReminderStatus {
  String localizedLabel(AppLocalizations l10n) {
    switch (this) {
      case ReminderStatus.expired:
        return l10n.statusExpired;
      case ReminderStatus.critical:
        return l10n.statusCritical;
      case ReminderStatus.approaching:
        return l10n.statusApproaching;
      case ReminderStatus.safe:
        return l10n.statusSafe;
    }
  }
}

String authErrorMessage(AuthException e, AppLocalizations l10n) {
  final String msg = e.message.toLowerCase();
  final String code = (e.code ?? '').toLowerCase();
  if ((code.contains('invalid') && code.contains('email')) ||
      msg.contains('invalid email')) {
    return l10n.authInvalidEmail;
  }
  if (msg.contains('user is disabled') || code.contains('user_disabled')) {
    return l10n.authUserDisabled;
  }
  if (msg.contains('user not found') || code.contains('user_not_found')) {
    return l10n.authUserNotFound;
  }
  if (msg.contains('invalid login') ||
      msg.contains('invalid credentials') ||
      msg.contains('invalid_credentials')) {
    return l10n.authInvalidCredential;
  }
  if (msg.contains('already registered') ||
      msg.contains('already been registered') ||
      msg.contains('user_already_exists')) {
    return l10n.authEmailInUse;
  }
  if (msg.contains('password') &&
      (msg.contains('weak') || msg.contains('least') || msg.contains('short'))) {
    return l10n.authWeakPassword;
  }
  if (msg.contains('not enabled') || msg.contains('provider')) {
    return l10n.authOperationNotAllowed;
  }
  if (msg.contains('network') || msg.contains('fetch')) {
    return l10n.authNetworkError;
  }
  if (msg.contains('rate') || msg.contains('too many')) {
    return l10n.authTooManyRequests;
  }
  if (msg.contains('confirm') || code.contains('email_not_confirmed')) {
    return l10n.authEmailConfirmationRequired;
  }
  if (e.message.trim().isNotEmpty) return e.message;
  return l10n.authSignInFailed(e.code ?? 'unknown');
}

String maintenanceItemLabel(AppLocalizations l10n, String id) {
  switch (id) {
    case 'yag_degisimi':
      return l10n.maintOilChange;
    case 'yag_filtresi':
      return l10n.maintOilFilter;
    case 'hava_filtresi':
      return l10n.maintAirFilter;
    case 'polen_filtresi':
      return l10n.maintCabinFilter;
    case 'yakit_filtresi':
      return l10n.maintFuelFilter;
    case 'su_filtresi':
      return l10n.maintWaterFilterDiesel;
    case 'on_fren_balata':
      return l10n.maintFrontBrakePads;
    case 'arka_fren_balata':
      return l10n.maintRearBrakePads;
    case 'fren_disk':
      return l10n.maintBrakeDisc;
    case 'fren_hidrolik':
      return l10n.maintBrakeFluid;
    case 'rot_baslari':
      return l10n.maintTieRodEnds;
    case 'rotil':
      return l10n.maintBallJoint;
    case 'amortisor':
      return l10n.maintShockAbsorber;
    case 'lastik':
      return l10n.maintTireChangeRotation;
    case 'jant_denge':
      return l10n.maintWheelBalance;
    case 'aku':
      return l10n.maintBattery;
    case 'buji':
      return l10n.maintSparkPlugsIgnition;
    case 'triger_set':
      return l10n.maintTimingBeltChain;
    case 'debriyaj':
      return l10n.maintClutch;
    case 'sogutma':
      return l10n.maintCoolantHose;
    case 'klima':
      return l10n.maintAcService;
    case 'egzoz':
      return l10n.maintExhaustMuffler;
    case 'silecek':
      return l10n.maintWiper;
    case 'far_ampul':
      return l10n.maintHeadlightBulb;
    case 'genel_kontrol':
      return l10n.maintGeneralInspection;
    default:
      return id;
  }
}

List<String> maintenanceLabelsInCatalogOrder(
  AppLocalizations l10n,
  Iterable<String> ids,
) {
  final Set<String> remaining = ids.toSet();
  final List<String> ordered = <String>[];
  for (final (String id, _) in MaintenanceItemCatalog.entries) {
    if (remaining.remove(id)) ordered.add(maintenanceItemLabel(l10n, id));
  }
  for (final String id in remaining) {
    ordered.add(maintenanceItemLabel(l10n, id));
  }
  return ordered;
}

String humanizeRemaining(AppLocalizations l10n, DateTime date) {
  final int diff = DateHelper.daysUntil(date);
  if (diff < 0) return l10n.expiredDaysAgo(diff.abs());
  if (diff == 0) return l10n.lastDayToday;
  if (diff == 1) return l10n.lastDayTomorrow;
  return l10n.daysRemaining(diff);
}

String localeTagFor(Locale? locale) {
  final String code = locale?.languageCode ?? 'en';
  switch (code) {
    case 'tr':
      return 'tr_TR';
    case 'es':
      return 'es_ES';
    default:
      return 'en_US';
  }
}

String? plateFormError(AppLocalizations l10n, String? value, bool Function(String) isValid, bool Function(String) hasForbidden) {
  final String v = (value ?? '').trim();
  if (v.isEmpty) return l10n.plateRequired;
  final String c = v.toUpperCase().replaceAll(RegExp(r'\s+'), '');
  if (hasForbidden(c)) return l10n.plateForbiddenLetters;
  if (!isValid(v)) return l10n.plateInvalidFormat;
  return null;
}

List<String> localizedTransmissionOptions(AppLocalizations l10n) => <String>[
      l10n.transmissionManual,
      l10n.transmissionAutomatic,
      l10n.transmissionSemiAutomatic,
      l10n.transmissionCvt,
    ];

List<String> localizedFuelOptions(AppLocalizations l10n) => <String>[
      l10n.fuelPetrol,
      l10n.fuelDiesel,
      l10n.fuelLpg,
      l10n.fuelHybrid,
      l10n.fuelPlugInHybrid,
      l10n.fuelElectric,
    ];

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_session_gate.dart';
import 'l10n/app_localizations.dart';
import 'services/background_removal_service.dart';
import 'services/distance_unit_controller.dart';
import 'services/locale_controller.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  final url = dotenv.env['SUPABASE_URL']?.trim() ?? '';
  final key = dotenv.env['SUPABASE_ANON_KEY']?.trim() ?? '';
  if (url.isEmpty || key.isEmpty) {
    throw StateError(
      'SUPABASE_URL ve SUPABASE_ANON_KEY .env içinde tanımlı olmalı.',
    );
  }
  await Supabase.initialize(url: url, publishableKey: key);
  await initializeDateFormatting('en_US');
  await initializeDateFormatting('tr_TR');
  await initializeDateFormatting('es_ES');
  await ThemeController.instance.load();
  await LocaleController.instance.load();
  await DistanceUnitController.instance.load();
  await NotificationService.instance.init();
  unawaited(BackgroundRemovalService.instance.init());
  runApp(const CarDataApp());
}

class CarDataApp extends StatefulWidget {
  const CarDataApp({super.key});

  @override
  State<CarDataApp> createState() => _CarDataAppState();
}

class _CarDataAppState extends State<CarDataApp> {
  @override
  void initState() {
    super.initState();
    ThemeController.instance.addListener(_onThemeModeChanged);
    LocaleController.instance.addListener(_onLocaleChanged);
    DistanceUnitController.instance.addListener(_onDistanceUnitChanged);
  }

  @override
  void dispose() {
    ThemeController.instance.removeListener(_onThemeModeChanged);
    LocaleController.instance.removeListener(_onLocaleChanged);
    DistanceUnitController.instance.removeListener(_onDistanceUnitChanged);
    super.dispose();
  }

  void _onThemeModeChanged() {
    if (mounted) setState(() {});
  }

  void _onLocaleChanged() {
    if (mounted) setState(() {});
  }

  void _onDistanceUnitChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Garage',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeController.instance.value,
      locale: LocaleController.instance.value,
      localeResolutionCallback: (Locale? locale, Iterable<Locale> _) =>
          LocaleController.resolve(locale),
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: LocaleController.supported,
      home: const AppSessionGate(),
    );
  }
}

import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app_session_gate.dart';
import 'firebase_options.dart';
import 'services/background_removal_service.dart';
import 'services/google_auth_service.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('tr_TR');
  await ThemeController.instance.load();
  await GoogleAuthService.initialize();
  await NotificationService.instance.init();
  // ONNX runtime'ı arka planda başlat; ilk fotoğraf işleminde hazır olsun.
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
  }

  @override
  void dispose() {
    ThemeController.instance.removeListener(_onThemeModeChanged);
    super.dispose();
  }

  void _onThemeModeChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Garaj',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeController.instance.value,
      locale: const Locale('tr', 'TR'),
      supportedLocales: const <Locale>[
        Locale('tr', 'TR'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const <LocalizationsDelegate<Object>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AppSessionGate(),
    );
  }
}

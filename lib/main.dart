import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'screens/home_screen.dart';
import 'services/background_removal_service.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR');
  await ThemeController.instance.load();
  await NotificationService.instance.init();
  // ONNX runtime'ı arka planda başlat; ilk fotoğraf işleminde hazır olsun.
  unawaited(BackgroundRemovalService.instance.init());
  runApp(const CarDataApp());
}

class CarDataApp extends StatelessWidget {
  const CarDataApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance,
      builder: (BuildContext context, ThemeMode mode, _) {
        return MaterialApp(
          title: 'Garage',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: mode,
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
          home: const HomeScreen(),
        );
      },
    );
  }
}

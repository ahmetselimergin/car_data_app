import 'package:flutter/material.dart' as m;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/app_config.dart';
import 'screens/brands_screen.dart';
import 'screens/cars_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/insurance_screen.dart';
import 'screens/login_screen.dart';
import 'screens/models_screen.dart';
import 'screens/shell.dart';
import 'screens/users_screen.dart';
import 'screens/workshops_screen.dart';
import 'services/auth_service.dart';
import 'services/catalog_service.dart';
import 'services/users_service.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  AppConfig.validate();
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    publishableKey: AppConfig.supabaseAnonKey,
  );
  await ThemeController.instance.load();
  final auth = AuthService();
  await auth.restore();
  runApp(AdminDesktopApp(auth: auth));
}

class AdminDesktopApp extends StatefulWidget {
  const AdminDesktopApp({super.key, required this.auth});

  final AuthService auth;

  @override
  State<AdminDesktopApp> createState() => _AdminDesktopAppState();
}

class _AdminDesktopAppState extends State<AdminDesktopApp> {
  late final CatalogService _catalog = CatalogService();
  late final UsersService _users = UsersService();
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    ThemeController.instance.addListener(_onThemeChanged);
    _router = GoRouter(
      initialLocation: widget.auth.isLoggedIn ? '/dashboard' : '/login',
      refreshListenable: widget.auth,
      redirect: (context, state) {
        final loggedIn = widget.auth.isLoggedIn && widget.auth.canUseAdmin;
        final onLogin = state.matchedLocation == '/login';
        if (!loggedIn && !onLogin) return '/login';
        if (loggedIn && onLogin) return '/dashboard';
        if (loggedIn &&
            !(widget.auth.userType?.isAdmin ?? false) &&
            (state.matchedLocation == '/brands' ||
                state.matchedLocation == '/models' ||
                state.matchedLocation == '/cars' ||
                state.matchedLocation == '/users')) {
          return '/dashboard';
        }
        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          pageBuilder: (context, state) => NoTransitionPage<void>(
            key: state.pageKey,
            child: LoginScreen(auth: widget.auth),
          ),
        ),
        ShellRoute(
          builder: (context, state, child) => AdminShell(
            auth: widget.auth,
            child: child,
          ),
          routes: [
            GoRoute(
              path: '/dashboard',
              pageBuilder: (context, state) => NoTransitionPage<void>(
                key: state.pageKey,
                child: DashboardScreen(
                  catalog: _catalog,
                  users: _users,
                  isAdmin: widget.auth.userType?.isAdmin ?? false,
                ),
              ),
            ),
            GoRoute(
              path: '/brands',
              pageBuilder: (context, state) => NoTransitionPage<void>(
                key: state.pageKey,
                child: BrandsScreen(catalog: _catalog),
              ),
            ),
            GoRoute(
              path: '/models',
              pageBuilder: (context, state) => NoTransitionPage<void>(
                key: state.pageKey,
                child: ModelsScreen(catalog: _catalog),
              ),
            ),
            GoRoute(
              path: '/cars',
              pageBuilder: (context, state) => NoTransitionPage<void>(
                key: state.pageKey,
                child: CarsScreen(catalog: _catalog),
              ),
            ),
            GoRoute(
              path: '/workshops',
              pageBuilder: (context, state) => NoTransitionPage<void>(
                key: state.pageKey,
                child: WorkshopsScreen(catalog: _catalog),
              ),
            ),
            GoRoute(
              path: '/insurance',
              pageBuilder: (context, state) => NoTransitionPage<void>(
                key: state.pageKey,
                child: InsuranceScreen(catalog: _catalog),
              ),
            ),
            GoRoute(
              path: '/users',
              pageBuilder: (context, state) => NoTransitionPage<void>(
                key: state.pageKey,
                child: UsersScreen(users: _users),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    ThemeController.instance.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return ShadcnApp.router(
      title: 'Cardex Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeController.instance.value,
      materialTheme: m.ThemeData(
        colorScheme: m.ColorScheme.fromSeed(
          seedColor: const Color(0xFF18181B),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      cupertinoTheme: null,
      routerConfig: _router,
    );
  }
}

/// go_router sayfa geçişi — kaydırma yok.
class NoTransitionPage<T> extends CustomTransitionPage<T> {
  NoTransitionPage({required super.child, super.key})
      : super(
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              child,
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        );
}

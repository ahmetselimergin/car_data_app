import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/welcome_screen.dart';
import 'services/onboarding_controller.dart';
import 'services/session_controller.dart';

/// Supabase oturumu yoksa [LoginScreen], varsa [HomeScreen].
class AppSessionGate extends StatefulWidget {
  const AppSessionGate({super.key});

  @override
  State<AppSessionGate> createState() => _AppSessionGateState();
}

class _AppSessionGateState extends State<AppSessionGate> {
  bool _ready = false;
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    SessionController.instance.addListener(_onSessionChanged);
    OnboardingController.instance.addListener(_onSessionChanged);
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      SessionController.instance.syncFromUser(data.session?.user);
    });
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    SessionController.instance
        .syncFromUser(Supabase.instance.client.auth.currentUser);
    if (mounted) setState(() => _ready = true);
  }

  void _onSessionChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _authSub?.cancel();
    SessionController.instance.removeListener(_onSessionChanged);
    OnboardingController.instance.removeListener(_onSessionChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (SessionController.instance.value != null) {
      return const HomeScreen();
    }
    return OnboardingController.instance.hasSeenWelcome
        ? const LoginScreen()
        : const WelcomeScreen();
  }
}

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/session_controller.dart';

/// Firebase oturumu yoksa [LoginScreen], varsa [HomeScreen].
class AppSessionGate extends StatefulWidget {
  const AppSessionGate({super.key});

  @override
  State<AppSessionGate> createState() => _AppSessionGateState();
}

class _AppSessionGateState extends State<AppSessionGate> {
  bool _ready = false;
  StreamSubscription<User?>? _authSub;

  @override
  void initState() {
    super.initState();
    SessionController.instance.addListener(_onSessionChanged);
    _authSub = FirebaseAuth.instance.authStateChanges().listen(
      SessionController.instance.syncFromFirebaseUser,
    );
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    SessionController.instance
        .syncFromFirebaseUser(FirebaseAuth.instance.currentUser);
    if (mounted) setState(() => _ready = true);
  }

  void _onSessionChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _authSub?.cancel();
    SessionController.instance.removeListener(_onSessionChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return SessionController.instance.value != null
        ? const HomeScreen()
        : const LoginScreen();
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../services/auth_firebase_messages.dart';
import '../services/google_auth_service.dart';
import '../services/session_controller.dart';

Future<void> tryEstablishSessionWithGoogle(BuildContext context) async {
  final ScaffoldMessengerState? messenger =
      ScaffoldMessenger.maybeOf(context);
  try {
    await SessionController.instance.signInWithGoogle();
  } on GoogleSignInNotConfigured catch (e) {
    messenger?.showSnackBar(SnackBar(content: Text(e.message)));
  } on GoogleSignInException catch (e) {
    if (e.code == GoogleSignInExceptionCode.canceled) return;
    if (!context.mounted) return;
    messenger?.showSnackBar(
      SnackBar(
        content: Text(
          e.description ?? 'Google ile giriş tamamlanamadı',
        ),
      ),
    );
  } on FirebaseAuthException catch (e) {
    if (!context.mounted) return;
    messenger?.showSnackBar(
      SnackBar(content: Text(firebaseAuthMessage(e))),
    );
  } catch (e) {
    if (!context.mounted) return;
    messenger?.showSnackBar(
      SnackBar(content: Text('Google ile giriş: $e')),
    );
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'google_auth_service.dart';

/// Oturum özeti (Ayarlar vb.). Kaynak: [FirebaseAuth].
@immutable
class Session {
  const Session({
    required this.email,
    this.displayName,
  });

  final String email;
  final String? displayName;

  String get greetingName {
    final String? n = displayName?.trim();
    if (n != null && n.isNotEmpty) return n;
    final int at = email.indexOf('@');
    if (at > 0) return email.substring(0, at);
    return email;
  }

  factory Session.fromFirebaseUser(User user) {
    return Session(
      email: user.email ?? user.uid,
      displayName: user.displayName,
    );
  }
}

/// [FirebaseAuth] ile senkron; [syncFromFirebaseUser] ile güncellenir.
class SessionController extends ValueNotifier<Session?> {
  SessionController._() : super(null);

  static final SessionController instance = SessionController._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  void syncFromFirebaseUser(User? user) {
    if (user == null) {
      value = null;
      return;
    }
    value = Session.fromFirebaseUser(user);
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> register({
    required String email,
    required String password,
    required String confirmPassword,
    String? displayName,
  }) async {
    if (password != confirmPassword) {
      throw ArgumentError('Şifreler eşleşmiyor');
    }
    final UserCredential cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final String? name = displayName?.trim();
    if (name != null && name.isNotEmpty && cred.user != null) {
      await cred.user!.updateDisplayName(name);
      await cred.user!.reload();
      syncFromFirebaseUser(_auth.currentUser);
    }
  }

  /// Google hesabı ile Firebase oturumu ([GoogleAuthProvider]).
  Future<void> signInWithGoogle() async {
    if (!GoogleAuthService.isReady) {
      await GoogleAuthService.initialize();
    }
    if (!GoogleAuthService.isReady) {
      throw GoogleSignInNotConfigured(
        'Google ile giriş kullanılamıyor. google-services.json / '
        'GoogleService-Info.plist ve OAuth yapılandırmasını kontrol edin.',
      );
    }
    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      throw UnsupportedError('Bu ortamda Google ile giriş desteklenmiyor.');
    }
    final GoogleSignInAccount account =
        await GoogleSignIn.instance.authenticate(
      scopeHint: <String>['email', 'profile'],
    );
    final GoogleSignInAuthentication ga = account.authentication;
    final String? idToken = ga.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw FirebaseAuthException(
        code: 'google-no-id-token',
        message: 'Google kimlik jetonu alınamadı.',
      );
    }
    final OAuthCredential credential = GoogleAuthProvider.credential(
      idToken: idToken,
    );
    await _auth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    await GoogleAuthService.signOut();
    await _auth.signOut();
    value = null;
  }
}

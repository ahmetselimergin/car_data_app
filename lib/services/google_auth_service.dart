import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Google OAuth henüz yapılandırılmadığında veya init başarısız olduğunda.
class GoogleSignInNotConfigured implements Exception {
  GoogleSignInNotConfigured(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Google hesabı bilgisi (yerel oturum için).
@immutable
class GoogleAuthUser {
  const GoogleAuthUser({
    required this.email,
    this.displayName,
  });

  final String email;
  final String? displayName;
}

/// [google_sign_in] sarmalayıcı. Önce [initialize] çağrılmalıdır.
class GoogleAuthService {
  GoogleAuthService._();

  static bool _initialized = false;

  /// Uygulama başlangıcında bir kez çağırın. Başarısız olursa [isReady] false kalır.
  static Future<void> initialize() async {
    if (_initialized) return;
    try {
      await GoogleSignIn.instance.initialize();
      _initialized = true;
    } catch (e, st) {
      debugPrint('GoogleSignIn.initialize: $e\n$st');
    }
  }

  static bool get isReady => _initialized;

  /// İlk kullanımdan önce [initialize] tamamlanmış olmalıdır.
  static Future<GoogleAuthUser?> signInInteractive() async {
    if (!_initialized) {
      await initialize();
    }
    if (!_initialized) {
      throw GoogleSignInNotConfigured(
        'Google ile giriş şu an kullanılamıyor. Google Cloud Console’da '
        'OAuth istemcisi oluşturun; iOS için Info.plist’e URL şemasını '
        '(REVERSED_CLIENT_ID) ekleyin.',
      );
    }
    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      debugPrint('GoogleSignIn: bu platformda authenticate desteklenmiyor');
      return null;
    }
    try {
      final GoogleSignInAccount account =
          await GoogleSignIn.instance.authenticate(
        scopeHint: <String>['email', 'profile'],
      );
      final String email = account.email.trim();
      if (email.isEmpty) return null;
      return GoogleAuthUser(
        email: email,
        displayName: account.displayName?.trim(),
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return null;
      }
      rethrow;
    }
  }

  static Future<void> signOut() async {
    if (!_initialized) return;
    try {
      await GoogleSignIn.instance.signOut();
    } catch (e, st) {
      debugPrint('GoogleSignIn.signOut: $e\n$st');
    }
  }
}

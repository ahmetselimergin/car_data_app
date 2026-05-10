import 'package:firebase_auth/firebase_auth.dart';

/// FirebaseAuthException kodları için Türkçe kısa mesaj.
String firebaseAuthMessage(FirebaseAuthException e) {
  switch (e.code) {
    case 'invalid-email':
      return 'Geçersiz e-posta adresi.';
    case 'user-disabled':
      return 'Bu hesap devre dışı bırakılmış.';
    case 'user-not-found':
      return 'Bu e-posta ile kayıtlı kullanıcı bulunamadı.';
    case 'wrong-password':
      return 'Şifre hatalı.';
    case 'invalid-credential':
    case 'invalid-login-credentials':
      return 'Giriş bilgileri geçersiz veya süresi dolmuş.';
    case 'email-already-in-use':
      return 'Bu e-posta adresi zaten kullanılıyor.';
    case 'weak-password':
      return 'Şifre çok zayıf; daha güçlü bir şifre seçin.';
    case 'operation-not-allowed':
      return 'Bu giriş yöntemi etkin değil (Firebase Console).';
    case 'network-request-failed':
      return 'Ağ hatası. Bağlantınızı kontrol edin.';
    case 'too-many-requests':
      return 'Çok fazla deneme. Bir süre sonra tekrar deneyin.';
    case 'account-exists-with-different-credential':
      return 'Bu e-posta başka bir giriş yöntemiyle kayıtlı.';
    default:
      return e.message?.trim().isNotEmpty == true
          ? e.message!
          : 'Giriş işlemi tamamlanamadı (${e.code}).';
  }
}

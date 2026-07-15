import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/l10n_ext.dart';

/// Kullanıcıya gösterilecek kısa hata metni. Ham exception metnini sızdırmaz.
String userFacingError(Object error, AppLocalizations l10n) {
  debugPrint('userFacingError: $error');
  if (error is AuthException) {
    return authErrorMessage(error, l10n);
  }
  final String s = error.toString().toLowerCase();
  if (s.contains('giriş yapmış') ||
      s.contains('not authenticated') ||
      s.contains('jwt') ||
      s.contains('auth session')) {
    return l10n.signInRequired;
  }
  if (s.contains('fotoğraf') ||
      s.contains('photograph') ||
      s.contains('photo not') ||
      s.contains('image')) {
    return l10n.photoNotFoundFriendly;
  }
  if (s.contains('socket') ||
      s.contains('network') ||
      s.contains('failed host') ||
      s.contains('timed out') ||
      s.contains('timeout') ||
      s.contains('connection')) {
    return l10n.authNetworkError;
  }
  return l10n.somethingWentWrong;
}

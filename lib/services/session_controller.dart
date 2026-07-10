import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/app_localizations.dart';
import 'locale_controller.dart';

/// Oturum özeti (Ayarlar vb.). Kaynak: Supabase Auth.
@immutable
class Session {
  const Session({
    required this.email,
    this.displayName,
    this.username,
    this.userId,
  });

  final String email;
  final String? displayName;
  final String? username;
  final String? userId;

  String get greetingName {
    final String? u = username?.trim();
    if (u != null && u.isNotEmpty) return u;
    final String? n = displayName?.trim();
    if (n != null && n.isNotEmpty) return n;
    final int at = email.indexOf('@');
    if (at > 0) return email.substring(0, at);
    return email;
  }

  factory Session.fromUser(User user) {
    final meta = user.userMetadata;
    final String? name = meta?['display_name'] as String? ??
        meta?['full_name'] as String? ??
        meta?['name'] as String?;
    final String? username = meta?['username'] as String?;
    return Session(
      email: user.email ?? user.id,
      displayName: name,
      username: username,
      userId: user.id,
    );
  }
}

/// Supabase Auth ile senkron.
class SessionController extends ValueNotifier<Session?> {
  SessionController._() : super(null);

  static final SessionController instance = SessionController._();

  GoTrueClient get _auth => Supabase.instance.client.auth;
  SupabaseClient get _client => Supabase.instance.client;

  static final RegExp usernamePattern = RegExp(r'^[a-z0-9_]{3,32}$');

  void syncFromUser(User? user) {
    if (user == null) {
      value = null;
      return;
    }
    value = Session.fromUser(user);
  }

  /// E-posta veya kullanıcı adını e-postaya çevirir.
  Future<String> resolveEmail(String identifier) async {
    final String raw = identifier.trim();
    if (raw.isEmpty) {
      throw AuthException(
        lookupAppLocalizations(LocaleController.resolve(null)).emailRequired,
      );
    }
    if (raw.contains('@')) return raw.toLowerCase();

    final dynamic res = await _client.rpc(
      'resolve_login_email',
      params: <String, dynamic>{'identifier': raw},
    );
    final String? email = res is String ? res : res?.toString();
    if (email == null || email.isEmpty || email == 'null') {
      throw AuthException(
        lookupAppLocalizations(LocaleController.resolve(null)).authUserNotFound,
      );
    }
    return email;
  }

  Future<void> signIn({
    required String emailOrUsername,
    required String password,
  }) async {
    final String email = await resolveEmail(emailOrUsername);
    final res = await _auth.signInWithPassword(
      email: email,
      password: password,
    );
    syncFromUser(res.user);
  }

  Future<void> register({
    required String email,
    required String password,
    required String confirmPassword,
    required String username,
    String? displayName,
  }) async {
    final AppLocalizations l10n =
        lookupAppLocalizations(LocaleController.resolve(null));
    if (password != confirmPassword) {
      throw ArgumentError(l10n.passwordsDoNotMatch);
    }
    final String uname = username.trim().toLowerCase();
    if (!usernamePattern.hasMatch(uname)) {
      throw AuthException(l10n.usernameInvalid);
    }
    final dynamic available = await _client.rpc(
      'username_available',
      params: <String, dynamic>{'u': uname},
    );
    if (available != true) {
      throw AuthException(l10n.usernameTaken);
    }

    final String? name = displayName?.trim();
    final res = await _auth.signUp(
      email: email.trim(),
      password: password,
      data: <String, dynamic>{
        'username': uname,
        if (name != null && name.isNotEmpty) 'display_name': name,
      },
    );
    if (res.session == null && res.user != null) {
      throw AuthException(l10n.authEmailConfirmationRequired);
    }
    syncFromUser(res.user ?? _auth.currentUser);
  }

  Future<void> signOut() async {
    await _auth.signOut();
    value = null;
  }
}

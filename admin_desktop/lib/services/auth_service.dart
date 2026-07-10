import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum UserType {
  admin,
  normalUser,
  partnerUser;

  static UserType fromDb(String? raw) {
    switch (raw) {
      case 'admin':
        return UserType.admin;
      case 'partner_user':
        return UserType.partnerUser;
      default:
        return UserType.normalUser;
    }
  }

  String get dbValue {
    switch (this) {
      case UserType.admin:
        return 'admin';
      case UserType.partnerUser:
        return 'partner_user';
      case UserType.normalUser:
        return 'normal_user';
    }
  }

  String get labelTr {
    switch (this) {
      case UserType.admin:
        return 'Admin';
      case UserType.partnerUser:
        return 'Partner';
      case UserType.normalUser:
        return 'Kullanıcı';
    }
  }

  bool get canOpenAdminApp =>
      this == UserType.admin || this == UserType.partnerUser;

  bool get isAdmin => this == UserType.admin;
}

class AuthService extends ChangeNotifier {
  AuthService() {
    _client.auth.onAuthStateChange.listen((_) async {
      if (isLoggedIn) {
        await _loadProfile();
      } else {
        _username = null;
        _userType = null;
      }
      notifyListeners();
    });
  }

  SupabaseClient get _client => Supabase.instance.client;

  String? _username;
  UserType? _userType;

  bool get isLoggedIn => _client.auth.currentSession != null;

  String? get email => _client.auth.currentUser?.email;

  String? get username => _username;

  UserType? get userType => _userType;

  bool get canUseAdmin => _userType?.canOpenAdminApp ?? false;

  Future<void> restore() async {
    if (_client.auth.currentSession != null) {
      try {
        await _client.auth.refreshSession();
      } catch (_) {}
      await _loadProfile();
      if (!canUseAdmin) {
        await logout();
      }
    }
    notifyListeners();
  }

  Future<void> refreshSession() async {
    await _client.auth.refreshSession();
    await _loadProfile();
    notifyListeners();
  }

  Future<void> _loadProfile() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      _username = null;
      _userType = null;
      return;
    }
    try {
      final row = await _client
          .from('profiles')
          .select('username, user_type')
          .eq('id', uid)
          .maybeSingle();
      _username = row?['username'] as String?;
      _userType = UserType.fromDb(row?['user_type'] as String?);
    } catch (_) {
      _username = _client.auth.currentUser?.userMetadata?['username'] as String?;
      _userType = UserType.normalUser;
    }
  }

  /// E-posta veya kullanıcı adı ile giriş. Admin paneli için staff gerekir.
  Future<void> login(String emailOrUsername, String password) async {
    final String email = await _resolveEmail(emailOrUsername);
    await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    await _loadProfile();
    if (!canUseAdmin) {
      await _client.auth.signOut();
      _username = null;
      _userType = null;
      throw const AuthException(
        'Bu hesap admin paneline giremez. Admin veya partner yetkisi gerekir.',
      );
    }
    notifyListeners();
  }

  Future<String> _resolveEmail(String identifier) async {
    final String raw = identifier.trim();
    if (raw.isEmpty) {
      throw const AuthException('E-posta veya kullanıcı adı gerekli.');
    }
    if (raw.contains('@')) return raw.toLowerCase();

    final dynamic res = await _client.rpc(
      'resolve_login_email',
      params: <String, dynamic>{'identifier': raw},
    );
    final String? email = res is String ? res : res?.toString();
    if (email == null || email.isEmpty || email == 'null') {
      throw const AuthException('Kullanıcı bulunamadı.');
    }
    return email;
  }

  Future<void> logout() async {
    await _client.auth.signOut();
    _username = null;
    _userType = null;
    notifyListeners();
  }
}

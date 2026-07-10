import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';

class UsersService {
  UsersService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<ProfileUser>> listUsers() async {
    final data = await _client
        .from('profiles')
        .select('id, username, email, user_type, created_at, updated_at')
        .order('created_at', ascending: false);
    return (data as List)
        .map((e) => ProfileUser.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> updateUserType(String id, String userType) async {
    await _client.from('profiles').update({
      'user_type': userType,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id);
  }

  Future<void> updateUsername(String id, String username) async {
    final u = username.trim().toLowerCase();
    await _client.from('profiles').update({
      'username': u,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id);
  }

  Future<ProfileUser> createUser({
    required String email,
    required String password,
    required String username,
    required String userType,
  }) async {
    final data = await _invoke({
      'action': 'create',
      'email': email.trim().toLowerCase(),
      'password': password,
      'username': username.trim().toLowerCase(),
      'user_type': userType,
    });
    return ProfileUser(
      id: data['id'] as String,
      username: data['username'] as String? ?? username,
      email: data['email'] as String? ?? email,
      userType: data['user_type'] as String? ?? userType,
      createdAt: DateTime.now().toUtc().toIso8601String(),
      updatedAt: DateTime.now().toUtc().toIso8601String(),
    );
  }

  Future<void> deleteUser(String id) async {
    await _invoke({'action': 'delete', 'id': id});
  }

  Future<Map<String, dynamic>> _invoke(Map<String, dynamic> body) async {
    if (_client.auth.currentSession == null) {
      throw const AuthException('Oturum yok.');
    }

    try {
      final res = await _client.functions.invoke(
        'admin-users',
        body: body,
      );
      final data = res.data;
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
      return <String, dynamic>{};
    } on FunctionException catch (e) {
      throw AuthException(_functionError(e));
    }
  }

  String _functionError(FunctionException e) {
    final details = e.details;
    if (details is Map && details['error'] != null) {
      return details['error'].toString();
    }
    if (details is String && details.isNotEmpty) {
      try {
        final decoded = jsonDecode(details);
        if (decoded is Map && decoded['error'] != null) {
          return decoded['error'].toString();
        }
      } catch (_) {}
      return details;
    }
    if (e.status == 404) {
      return 'admin-users Edge Function bulunamadı. '
          'Deploy: npx supabase functions deploy admin-users';
    }
    return e.reasonPhrase ??
        'İşlem başarısız (HTTP ${e.status}). '
            'admin-users Edge Function deploy edilmiş mi?';
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';

/// Tek bir sohbet mesajı (kullanıcı ya da asistan).
class SupportMessage {
  const SupportMessage({
    required this.role,
    required this.content,
    required this.createdAt,
  });

  final String role; // 'user' | 'assistant'
  final String content;
  final DateTime createdAt;

  bool get isUser => role == 'user';

  factory SupportMessage.fromMap(Map<String, dynamic> map) {
    return SupportMessage(
      role: (map['role'] as String?) ?? 'assistant',
      content: (map['content'] as String?) ?? '',
      createdAt:
          DateTime.tryParse((map['created_at'] as String?) ?? '') ??
          DateTime.now(),
    );
  }
}

/// AI destek botu için Supabase köprüsü: geçmiş yükleme, mesaj gönderme,
/// destek talebi açma.
class SupportChatService {
  SupportChatService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String get _uid {
    final String? id = _client.auth.currentUser?.id;
    if (id == null) {
      throw StateError('Oturum bulunamadı');
    }
    return id;
  }

  /// Kullanıcının sohbet geçmişini eskiden yeniye sıralı getirir.
  Future<List<SupportMessage>> loadHistory() async {
    final List<dynamic> rows = await _client
        .from('support_messages')
        .select('role, content, created_at')
        .eq('user_id', _uid)
        .order('seq', ascending: true);
    return rows
        .map((dynamic r) =>
            SupportMessage.fromMap(Map<String, dynamic>.from(r as Map)))
        .toList();
  }

  /// Mesajı Edge Function'a yollar ve asistan cevabını döndürür.
  /// Geçmiş kaydı sunucu tarafında yapılır.
  Future<String> sendMessage(String message) async {
    try {
      final FunctionResponse res = await _client.functions.invoke(
        'support-chat',
        body: <String, dynamic>{'message': message},
      );
      final dynamic data = res.data;
      if (data is Map && data['reply'] is String) {
        return data['reply'] as String;
      }
      throw Exception('Beklenmeyen yanıt');
    } on FunctionException catch (e) {
      final dynamic details = e.details;
      if (details is Map && details['error'] is String) {
        throw Exception(details['error'] as String);
      }
      throw Exception('Mesaj gönderilemedi');
    }
  }

  /// Çözülemeyen durumlar için destek talebi açar.
  Future<void> openTicket(String message) async {
    await _client.from('support_tickets').insert(<String, dynamic>{
      'user_id': _uid,
      'message': message,
      'status': 'open',
    });
  }
}

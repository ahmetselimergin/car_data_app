import 'dart:io' show Platform;

import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Güncelleme türü: yok / önerilen / zorunlu.
enum UpdateType { none, optional, forced }

/// Sürüm kapısı sonucu.
class UpdateInfo {
  const UpdateInfo({required this.type, this.storeUrl, this.message});

  final UpdateType type;
  final String? storeUrl;
  final String? message;

  static const UpdateInfo none = UpdateInfo(type: UpdateType.none);
}

/// Supabase `app_config` tablosuna bakarak uygulamanın güncel olup olmadığını
/// belirler. Hata/ağ sorununda uygulamayı bloklamaz (none döner).
class UpdateService {
  UpdateService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<UpdateInfo> check() async {
    try {
      // Yalnız mobil platformlarda anlamlı.
      if (!Platform.isIOS && !Platform.isAndroid) return UpdateInfo.none;
      final String platform = Platform.isIOS ? 'ios' : 'android';

      final PackageInfo info = await PackageInfo.fromPlatform();
      final int currentBuild = int.tryParse(info.buildNumber) ?? 0;

      final Map<String, dynamic>? row = await _client
          .from('app_config')
          .select('min_build, latest_build, store_url, message')
          .eq('platform', platform)
          .maybeSingle();
      if (row == null) return UpdateInfo.none;

      final int minBuild = (row['min_build'] as num?)?.toInt() ?? 1;
      final int latestBuild = (row['latest_build'] as num?)?.toInt() ?? 1;
      final String? rawUrl = row['store_url'] as String?;
      final String? url = (rawUrl != null && rawUrl.trim().isNotEmpty)
          ? rawUrl.trim()
          : null;
      final String? message = row['message'] as String?;

      if (currentBuild < minBuild) {
        return UpdateInfo(
          type: UpdateType.forced,
          storeUrl: url,
          message: message,
        );
      }
      if (currentBuild < latestBuild) {
        return UpdateInfo(
          type: UpdateType.optional,
          storeUrl: url,
          message: message,
        );
      }
      return UpdateInfo.none;
    } catch (_) {
      // Sürüm kontrolü uygulamayı asla bloklamamalı.
      return UpdateInfo.none;
    }
  }
}

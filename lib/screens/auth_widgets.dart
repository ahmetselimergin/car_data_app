import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

bool authLooksLikeEmail(String s) {
  final String t = s.trim();
  final int at = t.indexOf('@');
  if (at <= 0 || at == t.length - 1) return false;
  return t.contains('.', at);
}

bool authLooksLikeUsername(String s) {
  final String t = s.trim().toLowerCase();
  return RegExp(r'^[a-z0-9_]{3,32}$').hasMatch(t);
}

/// Giriş alanı: e-posta veya kullanıcı adı.
String? authValidateLoginId(String? v, AppLocalizations l10n) {
  final String s = (v ?? '').trim();
  if (s.isEmpty) return l10n.loginIdRequired;
  if (s.contains('@')) {
    if (!authLooksLikeEmail(s)) return l10n.emailInvalid;
    return null;
  }
  if (!authLooksLikeUsername(s)) return l10n.usernameInvalid;
  return null;
}

/// Giriş / kayıt ekranları için ortak üst alan.
class AuthBrandingHeader extends StatelessWidget {
  const AuthBrandingHeader({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final TextTheme tt = Theme.of(context).textTheme;
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.directions_car_rounded,
              color: AppTheme.primary,
              size: 30,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: tt.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: tt.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

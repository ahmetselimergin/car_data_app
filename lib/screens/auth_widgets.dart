import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../widgets/my_garaj_logo.dart';

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

const Color kAuthSoftBg = Color(0xFFF3F4F6);
const Color kAuthInk = Color(0xFF18181B);
const Color kAuthMuted = Color(0xFF71717A);

class AuthBackButton extends StatelessWidget {
  const AuthBackButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed ?? () => Navigator.of(context).maybePop(),
        child: Ink(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.arrow_back_rounded,
            color: kAuthInk,
            size: 22,
          ),
        ),
      ),
    );
  }
}

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
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              color: kAuthInk,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              color: kAuthMuted,
              fontSize: 14.5,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class AuthSoftField extends StatelessWidget {
  const AuthSoftField({
    super.key,
    required this.label,
    required this.child,
    this.helper,
  });

  final String label;
  final Widget child;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(
              color: kAuthInk,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
        if (helper != null) ...<Widget>[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Text(
              helper!,
              style: TextStyle(
                color: kAuthMuted.withValues(alpha: 0.9),
                fontSize: 12,
                height: 1.3,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

InputDecoration authSoftDecoration({
  required String hint,
  Widget? prefixIcon,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(
      color: kAuthMuted.withValues(alpha: 0.75),
      fontWeight: FontWeight.w500,
    ),
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(28),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(28),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(28),
      borderSide: const BorderSide(color: AppTheme.primary, width: 1.4),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(28),
      borderSide: const BorderSide(color: Color(0xFFE53935), width: 1.2),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(28),
      borderSide: const BorderSide(color: Color(0xFFE53935), width: 1.4),
    ),
  );
}

/// Soft alanlarda her zaman koyu yazı (uygulama dark mode olsa bile).
const TextStyle kAuthInputStyle = TextStyle(
  color: kAuthInk,
  fontSize: 15,
  fontWeight: FontWeight.w600,
);

class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: FilledButton(
        onPressed: busy ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: kAuthInk,
          foregroundColor: Colors.white,
          disabledBackgroundColor: kAuthInk.withValues(alpha: 0.45),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        child: busy
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white,
                ),
              )
            : Text(label),
      ),
    );
  }
}

class AuthSoftScaffold extends StatelessWidget {
  const AuthSoftScaffold({
    super.key,
    required this.onBack,
    required this.child,
  });

  final VoidCallback? onBack;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData softTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppTheme.primary,
        onPrimary: Colors.white,
        surface: Colors.white,
        onSurface: kAuthInk,
        onSurfaceVariant: kAuthMuted,
      ),
      scaffoldBackgroundColor: kAuthSoftBg,
      textTheme: ThemeData.light().textTheme.apply(
        bodyColor: kAuthInk,
        displayColor: kAuthInk,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
      ),
    );

    return Theme(
      data: softTheme,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Scaffold(
          backgroundColor: kAuthSoftBg,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: SizedBox(
                    height: 44,
                    child: Stack(
                      alignment: Alignment.center,
                      children: <Widget>[
                        const IgnorePointer(
                          child: MyGarajBrandMark(
                            logoHeight: 22,
                            fontSize: 16,
                            compact: true,
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: AuthBackButton(onPressed: onBack),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

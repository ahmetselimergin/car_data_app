import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/l10n_ext.dart';
import '../services/onboarding_controller.dart';
import '../services/session_controller.dart';
import '../theme/app_theme.dart';
import 'auth_widgets.dart';
import 'register_screen.dart';

/// Soft UI giriş (MyGaraj).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _loginId = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _obscure = true;
  bool _busy = false;

  @override
  void dispose() {
    _loginId.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    try {
      await SessionController.instance.signIn(
        emailOrUsername: _loginId.text,
        password: _password.text,
      );
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authErrorMessage(e, context.l10n))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    return AuthSoftScaffold(
      onBack: _busy ? null : () => OnboardingController.instance.clearSeen(),
      child: CustomScrollView(
        slivers: <Widget>[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
            sliver: SliverToBoxAdapter(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    AuthBrandingHeader(
                      title: l10n.loginTitle,
                      subtitle: l10n.loginSubtitle,
                    )
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.08, end: 0),
                    const SizedBox(height: 28),
                    AuthSoftField(
                      label: l10n.loginIdLabel,
                      child: TextFormField(
                        style: kAuthInputStyle,
                        controller: _loginId,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const <String>[
                          AutofillHints.username,
                          AutofillHints.email,
                        ],
                        textInputAction: TextInputAction.next,
                        decoration: authSoftDecoration(
                          hint: l10n.loginIdLabel,
                          prefixIcon: const Icon(
                            Icons.mail_outline_rounded,
                            color: kAuthMuted,
                          ),
                        ),
                        validator: (String? v) => authValidateLoginId(v, l10n),
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 400.ms, delay: 80.ms)
                        .slideY(begin: 0.08, end: 0),
                    const SizedBox(height: 18),
                    AuthSoftField(
                      label: l10n.passwordLabel,
                      child: TextFormField(
                        style: kAuthInputStyle,
                        controller: _password,
                        obscureText: _obscure,
                        autofillHints: const <String>[AutofillHints.password],
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        decoration: authSoftDecoration(
                          hint: l10n.passwordLabel,
                          prefixIcon: const Icon(
                            Icons.lock_outline_rounded,
                            color: kAuthMuted,
                          ),
                          suffixIcon: IconButton(
                            tooltip: _obscure
                                ? l10n.showPassword
                                : l10n.hidePassword,
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: kAuthMuted,
                            ),
                          ),
                        ),
                        validator: (String? v) {
                          final String s = (v ?? '');
                          if (s.length < 6) return l10n.passwordMinLength;
                          return null;
                        },
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 400.ms, delay: 140.ms)
                        .slideY(begin: 0.08, end: 0),
                    const SizedBox(height: 28),
                    AuthPrimaryButton(
                      label: l10n.signInButton,
                      busy: _busy,
                      onPressed: _submit,
                    )
                        .animate()
                        .fadeIn(duration: 400.ms, delay: 200.ms)
                        .slideY(begin: 0.1, end: 0),
                    const SizedBox(height: 22),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          l10n.noAccountQuestion,
                          style: const TextStyle(
                            color: kAuthMuted,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => const RegisterScreen(),
                                    ),
                                  );
                                },
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.primary,
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          child: Text(l10n.registerLink),
                        ),
                      ],
                    ).animate().fadeIn(duration: 400.ms, delay: 260.ms),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

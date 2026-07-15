import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/l10n_ext.dart';
import '../services/session_controller.dart';
import '../theme/app_theme.dart';
import '../utils/user_facing_error.dart';
import 'auth_widgets.dart';

/// Soft UI kayıt (MyGaraj).
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _username = TextEditingController();
  final TextEditingController _displayName = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();
  bool _obscure = true;
  bool _obscure2 = true;
  bool _busy = false;

  @override
  void dispose() {
    _username.dispose();
    _displayName.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    try {
      await SessionController.instance.register(
        email: _email.text,
        password: _password.text,
        confirmPassword: _confirm.text,
        username: _username.text,
        displayName: _displayName.text.trim().isEmpty
            ? null
            : _displayName.text.trim(),
      );
      if (mounted) Navigator.of(context).pop();
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authErrorMessage(e, context.l10n))),
        );
      }
    } on ArgumentError {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.passwordsDoNotMatch)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFacingError(e, context.l10n))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _field(Widget child, int index) {
    return child
        .animate()
        .fadeIn(duration: 380.ms, delay: (60 + index * 50).ms)
        .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    return AuthSoftScaffold(
      onBack: _busy ? null : () => Navigator.of(context).pop(),
      child: CustomScrollView(
        slivers: <Widget>[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            sliver: SliverToBoxAdapter(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    AuthBrandingHeader(
                      title: l10n.registerTitle,
                      subtitle: l10n.registerSubtitle,
                    ).animate().fadeIn(duration: 400.ms),
                    const SizedBox(height: 24),
                    _field(
                      AuthSoftField(
                        label: l10n.usernameLabel,
                        helper: l10n.usernameInvalid,
                        child: TextFormField(
                        style: kAuthInputStyle,
                          controller: _username,
                          textInputAction: TextInputAction.next,
                          autofillHints: const <String>[
                            AutofillHints.username,
                          ],
                          decoration: authSoftDecoration(
                            hint: l10n.usernameLabel,
                            prefixIcon: const Icon(
                              Icons.alternate_email_rounded,
                              color: kAuthMuted,
                            ),
                          ),
                          validator: (String? v) {
                            final String s = (v ?? '').trim().toLowerCase();
                            if (s.isEmpty) return l10n.usernameRequired;
                            if (!authLooksLikeUsername(s)) {
                              return l10n.usernameInvalid;
                            }
                            return null;
                          },
                        ),
                      ),
                      0,
                    ),
                    const SizedBox(height: 16),
                    _field(
                      AuthSoftField(
                        label: l10n.displayNameLabel,
                        child: TextFormField(
                        style: kAuthInputStyle,
                          controller: _displayName,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          decoration: authSoftDecoration(
                            hint: l10n.displayNameLabel,
                            prefixIcon: const Icon(
                              Icons.person_outline_rounded,
                              color: kAuthMuted,
                            ),
                          ),
                        ),
                      ),
                      1,
                    ),
                    const SizedBox(height: 16),
                    _field(
                      AuthSoftField(
                        label: l10n.emailLabel,
                        child: TextFormField(
                        style: kAuthInputStyle,
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const <String>[AutofillHints.email],
                          textInputAction: TextInputAction.next,
                          decoration: authSoftDecoration(
                            hint: l10n.emailLabel,
                            prefixIcon: const Icon(
                              Icons.mail_outline_rounded,
                              color: kAuthMuted,
                            ),
                          ),
                          validator: (String? v) {
                            final String s = (v ?? '').trim();
                            if (s.isEmpty) return l10n.emailRequired;
                            if (!authLooksLikeEmail(s)) {
                              return l10n.emailInvalid;
                            }
                            return null;
                          },
                        ),
                      ),
                      2,
                    ),
                    const SizedBox(height: 16),
                    _field(
                      AuthSoftField(
                        label: l10n.passwordLabel,
                        child: TextFormField(
                        style: kAuthInputStyle,
                          controller: _password,
                          obscureText: _obscure,
                          textInputAction: TextInputAction.next,
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
                      ),
                      3,
                    ),
                    const SizedBox(height: 16),
                    _field(
                      AuthSoftField(
                        label: l10n.confirmPasswordLabel,
                        child: TextFormField(
                        style: kAuthInputStyle,
                          controller: _confirm,
                          obscureText: _obscure2,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                          decoration: authSoftDecoration(
                            hint: l10n.confirmPasswordLabel,
                            prefixIcon: const Icon(
                              Icons.lock_outline_rounded,
                              color: kAuthMuted,
                            ),
                            suffixIcon: IconButton(
                              tooltip: _obscure2
                                  ? l10n.showPassword
                                  : l10n.hidePassword,
                              onPressed: () =>
                                  setState(() => _obscure2 = !_obscure2),
                              icon: Icon(
                                _obscure2
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: kAuthMuted,
                              ),
                            ),
                          ),
                          validator: (String? v) {
                            if ((v ?? '') != _password.text) {
                              return l10n.passwordsDoNotMatch;
                            }
                            return null;
                          },
                        ),
                      ),
                      4,
                    ),
                    const SizedBox(height: 28),
                    _field(
                      AuthPrimaryButton(
                        label: l10n.registerButton,
                        busy: _busy,
                        onPressed: _submit,
                      ),
                      5,
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton(
                        onPressed:
                            _busy ? null : () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.primary,
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        child: Text(l10n.alreadyHaveAccountSignIn),
                      ),
                    ).animate().fadeIn(duration: 400.ms, delay: 380.ms),
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

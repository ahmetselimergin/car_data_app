import 'dart:math' as math;

import 'package:go_router/go_router.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.auth});

  final AuthService auth;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _email = TextEditingController();
  final _password = TextEditingController();
  var _busy = false;
  String? _error;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.auth.login(_email.text, _password.text);
      if (!mounted) return;
      context.go('/dashboard');
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _friendlyError(Object e) {
    final s = e.toString();
    if (s.contains('admin paneline giremez') || s.contains('partner yetkisi')) {
      return 'Bu hesap admin paneline giremez.';
    }
    if (s.contains('Invalid login credentials')) {
      return 'Kullanıcı adı / e-posta veya şifre hatalı.';
    }
    if (s.contains('Kullanıcı bulunamadı') || s.contains('User not found')) {
      return 'Kullanıcı bulunamadı.';
    }
    if (s.contains('Email not confirmed')) {
      return 'E-posta henüz doğrulanmamış.';
    }
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wide = MediaQuery.sizeOf(context).width >= 960;

    return Scaffold(
      child: Row(
        children: [
          if (wide)
            Expanded(
              flex: 5,
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _HeroPainter(
                      accent: theme.colorScheme.primary,
                      background: theme.colorScheme.background,
                      t: _pulse.value,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(48),
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Cardex').h2().semiBold(),
                              const Gap(12),
                              const Text(
                                'Katalog yönetimi,\nbir bakışta sakin ve net.',
                              ).large().muted(),
                              const Gap(24),
                              Container(
                                width: 40,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  borderRadius: BorderRadius.circular(99),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          Expanded(
            flex: 4,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 40),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Card(
                    padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!wide) ...[
                          const Text('Cardex').h3().semiBold(),
                          const Gap(16),
                        ],
                        const Text('Hoş geldin').h3().semiBold(),
                        const Gap(8),
                        const Text('Devam etmek için hesabınla giriş yap.')
                            .muted()
                            .small(),
                        const Gap(28),
                        const Text('E-posta veya kullanıcı adı').small().semiBold(),
                        const Gap(6),
                        TextField(
                          controller: _email,
                          placeholder: const Text('admin veya e-posta'),
                          features: const [
                            InputLeadingFeature(
                              Icon(LucideIcons.user, size: 16),
                            ),
                          ],
                          onSubmitted: (_) => _submit(),
                        ),
                        const Gap(16),
                        const Text('Şifre').small().semiBold(),
                        const Gap(6),
                        TextField(
                          controller: _password,
                          obscureText: true,
                          placeholder: const Text('••••••••'),
                          features: const [
                            InputLeadingFeature(
                              Icon(LucideIcons.lock, size: 16),
                            ),
                            InputPasswordToggleFeature(),
                          ],
                          onSubmitted: (_) => _submit(),
                        ),
                        if (_error != null) ...[
                          const Gap(14),
                          Alert(
                            destructive: true,
                            title: const Text('Giriş başarısız'),
                            content: Text(_error!),
                            trailing: IconButton.ghost(
                              icon: const Icon(LucideIcons.x, size: 14),
                              onPressed: () => setState(() => _error = null),
                            ),
                          ),
                        ],
                        const Gap(24),
                        PrimaryButton(
                          onPressed: _busy ? null : _submit,
                          child: _busy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(),
                                )
                              : const Text('Giriş yap'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroPainter extends CustomPainter {
  _HeroPainter({
    required this.accent,
    required this.background,
    required this.t,
  });

  final Color accent;
  final Color background;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = background);

    final g1 = Paint()
      ..shader = RadialGradient(
        center: Alignment(-0.4 + t * 0.1, -0.5),
        radius: 1.1,
        colors: [accent.withValues(alpha: 0.18), Colors.transparent],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, g1);

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final c = Offset(size.width * 0.75, size.height * 0.3);
    for (var i = 0; i < 4; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: 50.0 + i * 32 + t * 8),
        -math.pi * 0.2,
        math.pi * 0.8,
        false,
        arc..color = accent.withValues(alpha: 0.06 + i * 0.02),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HeroPainter old) =>
      old.t != t || old.accent != accent || old.background != background;
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../l10n/l10n_ext.dart';
import '../services/onboarding_controller.dart';
import '../widgets/my_garaj_logo.dart';

/// Üstte hero + logo, altta beyaz panel (yazı + düz yol swipe).
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const String _bgAsset = 'assets/images/welcome_background.jpg';

  Future<void> _getStarted() => OnboardingController.instance.markSeen();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              flex: 11,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  Image.asset(
                    _bgAsset,
                    fit: BoxFit.cover,
                    alignment: const Alignment(0, -0.35),
                    errorBuilder: (_, _, _) => const ColoredBox(
                      color: Color(0xFFE8EEF5),
                    ),
                  ),
                  const Align(
                    alignment: Alignment.bottomCenter,
                    child: SizedBox(
                      height: 56,
                      width: double.infinity,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: <Color>[
                              Color(0x00FFFFFF),
                              Color(0xFFFFFFFF),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: MyGarajLogo(height: 48)
                            .animate()
                            .fadeIn(duration: 500.ms, delay: 40.ms)
                            .slideY(
                              begin: -0.15,
                              end: 0,
                              curve: Curves.easeOutCubic,
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 9,
              child: ColoredBox(
                color: Colors.white,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Text(
                          l10n.welcomeTitle,
                          style: const TextStyle(
                            color: Color(0xFF18181B),
                            fontSize: 30,
                            height: 1.15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 500.ms, delay: 120.ms)
                            .slideY(
                              begin: 0.2,
                              end: 0,
                              curve: Curves.easeOutCubic,
                            ),
                        const SizedBox(height: 10),
                        Text(
                          l10n.welcomeSubtitle,
                          style: TextStyle(
                            color: const Color(0xFF18181B)
                                .withValues(alpha: 0.58),
                            fontSize: 15,
                            height: 1.45,
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 500.ms, delay: 200.ms)
                            .slideY(
                              begin: 0.2,
                              end: 0,
                              curve: Curves.easeOutCubic,
                            ),
                        const Spacer(),
                        _SwipeToStart(onCompleted: _getStarted)
                            .animate()
                            .fadeIn(duration: 550.ms, delay: 280.ms)
                            .slideY(
                              begin: 0.35,
                              end: 0,
                              curve: Curves.easeOutCubic,
                            ),
                        const SizedBox(height: 14),
                        Text(
                          l10n.welcomeSwipeHint,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0xFF18181B)
                                .withValues(alpha: 0.45),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        )
                            .animate(
                              onPlay: (AnimationController c) =>
                                  c.repeat(reverse: true),
                            )
                            .fade(
                              begin: 0.28,
                              end: 1,
                              duration: 900.ms,
                              curve: Curves.easeInOut,
                            ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Düz asfalt yol + 3D araba (sağa bakış, nudge).
class _SwipeToStart extends StatefulWidget {
  const _SwipeToStart({required this.onCompleted});

  final Future<void> Function() onCompleted;

  @override
  State<_SwipeToStart> createState() => _SwipeToStartState();
}

class _SwipeToStartState extends State<_SwipeToStart>
    with TickerProviderStateMixin {
  static const double _roadH = 72;
  static const double _carW = 112;
  static const double _carH = 78;
  static const double _completeAt = 0.86;
  static const double _nudgePx = 10;
  static const double _dashCycle = 26; // dash + gap

  final Flutter3DController _carCtrl = Flutter3DController();

  double _progress = 0;
  bool _dragging = false;
  bool _done = false;
  bool _carReady = false;

  late final AnimationController _nudge;
  late final AnimationController _roadScroll;
  Timer? _nudgeTimer;

  @override
  void initState() {
    super.initState();
    _nudge = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _roadScroll = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
    _carCtrl.onModelLoaded.addListener(_onCarLoaded);
  }

  void _onCarLoaded() {
    _carCtrl.setCameraOrbit(95, 78, 105);
    if (!mounted) return;
    if (!_carReady) {
      setState(() => _carReady = true);
      _startNudgeLoop();
    }
  }

  void _startNudgeLoop() {
    _nudgeTimer?.cancel();
    _nudgeTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted || _dragging || _done || _progress > 0.02) return;
      _nudge.forward(from: 0).then((_) {
        if (mounted && !_dragging) _nudge.reverse();
      });
    });
  }

  @override
  void dispose() {
    _nudgeTimer?.cancel();
    _carCtrl.onModelLoaded.removeListener(_onCarLoaded);
    _nudge.dispose();
    _roadScroll.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (_done) return;
    setState(() {
      _done = true;
      _progress = 1;
    });
    _nudgeTimer?.cancel();
    HapticFeedback.mediumImpact();
    await widget.onCompleted();
  }

  void _snapBack() {
    setState(() {
      _progress = 0;
      _dragging = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double trackW = constraints.maxWidth;
        final double maxDx = (trackW - _carW + 8).clamp(0.0, trackW);
        final double dx = _progress * maxDx;

        return SizedBox(
          height: _carH + 4,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: (_) {
              if (_done) return;
              _nudge.stop();
              _nudge.value = 0;
              setState(() => _dragging = true);
            },
            onHorizontalDragUpdate: (DragUpdateDetails d) {
              if (_done || maxDx <= 0) return;
              setState(() {
                _progress =
                    ((_progress * maxDx + d.delta.dx) / maxDx).clamp(0.0, 1.0);
              });
            },
            onHorizontalDragEnd: (_) {
              if (_done) return;
              if (_progress >= _completeAt) {
                _finish();
              } else {
                _snapBack();
              }
            },
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.centerLeft,
              children: <Widget>[
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: _roadH,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: <Color>[
                                Color(0xFF050505),
                                Color(0xFF2A2A2A),
                                Color(0xFF050505),
                              ],
                              stops: <double>[0.0, 0.5, 1.0],
                            ),
                          ),
                        ),
                        AnimatedBuilder(
                          animation: _roadScroll,
                          builder: (BuildContext context, _) {
                            // Değer arttıkça şeritler sola kayar
                            final double offset =
                                _roadScroll.value * _dashCycle;
                            return CustomPaint(
                              painter:
                                  _RoadMarkingsPainter(scrollOffset: offset),
                            );
                          },
                        ),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: <Color>[
                                Color(0xE6050505),
                                Color(0x00050505),
                                Color(0x00050505),
                                Color(0xE6050505),
                              ],
                              stops: <double>[0.0, 0.12, 0.88, 1.0],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                AnimatedBuilder(
                  animation: _nudge,
                  builder: (BuildContext context, Widget? child) {
                    final double hint = (!_dragging && _progress < 0.02)
                        ? Curves.easeInOut.transform(_nudge.value) * _nudgePx
                        : 0;
                    return Positioned(
                      left: dx - 4 + hint,
                      bottom: 2,
                      width: _carW,
                      height: _carH,
                      child: child!,
                    );
                  },
                  child: IgnorePointer(
                    child: Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.diagonal3Values(-1, 1, 1),
                          child: Flutter3DViewer(
                            src: 'assets/models/sports_car.glb',
                            controller: _carCtrl,
                            enableTouch: false,
                            activeGestureInterceptor: false,
                            progressBarColor: Colors.transparent,
                            onLoad: (_) => _onCarLoaded(),
                            onError: (String e) {
                              debugPrint('Swipe car load error: $e');
                            },
                          ),
                        ),
                        if (!_carReady)
                          const Center(
                            child: Icon(
                              Icons.directions_car_rounded,
                              color: Colors.white54,
                              size: 36,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RoadMarkingsPainter extends CustomPainter {
  const _RoadMarkingsPainter({required this.scrollOffset});

  /// Şeritlerin yatay kayması (sola akış için artan offset).
  final double scrollOffset;

  @override
  void paint(Canvas canvas, Size size) {
    final double y = size.height * 0.52;
    const double dash = 14;
    const double gap = 12;
    const double cycle = dash + gap;
    final Paint paint = Paint()
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // scrollOffset arttıkça şeritler sola akar
    double phase = -scrollOffset % cycle;
    if (phase < 0) phase += cycle;
    for (double x = -cycle + phase; x < size.width + cycle; x += cycle) {
      final double mid = size.width * 0.5;
      final double cx = x + dash / 2;
      final double dist = (cx - mid).abs() / mid;
      final double alpha = (1.0 - dist * 1.15).clamp(0.0, 1.0) * 0.55;
      if (alpha <= 0.02) continue;
      if (x + dash < 0 || x > size.width) continue;
      paint.color = Colors.white.withValues(alpha: alpha);
      final double x0 = x.clamp(0.0, size.width);
      final double x1 = (x + dash).clamp(0.0, size.width);
      if (x1 <= x0) continue;
      canvas.drawLine(Offset(x0, y), Offset(x1, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RoadMarkingsPainter oldDelegate) =>
      oldDelegate.scrollOffset != scrollOffset;
}

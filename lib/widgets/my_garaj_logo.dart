import 'dart:math' as math;

import 'package:flutter/material.dart';

/// MyGaraj marka ikonu.
/// Her kapsül ayrı: sırayla dik gelir → sonra her biri kendi altından 15° döner.
/// Z-sıra: lacivert alt · beyaz orta · yeşil en üst.
class MyGarajLogo extends StatefulWidget {
  const MyGarajLogo({
    super.key,
    this.height = 52,
    this.showShadow = true,
    this.playIntro = true,
  });

  final double height;
  final bool showShadow;

  /// `false` ise nihai (dönmüş) halde sabit gösterilir.
  /// Not: `animate` adı flutter_animate `.animate()` ile çakışır.
  final bool playIntro;

  static const Color navy = Color(0xFF14375B);
  static const Color green = Color(0xFF1CA26D);
  static const Color white = Color(0xFFFFFFFF);

  static const double _aspect = 0.50;
  static const double _stepFactor = 0.60;
  static const double _tiltDeg = 25;

  @override
  State<MyGarajLogo> createState() => _MyGarajLogoState();
}

class _MyGarajLogoState extends State<MyGarajLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  late final Animation<double> _enter0;
  late final Animation<double> _enter1;
  late final Animation<double> _enter2;
  late final Animation<double> _tilt0;
  late final Animation<double> _tilt1;
  late final Animation<double> _tilt2;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    // Sırayla dik giriş
    _enter0 = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.00, 0.20, curve: Curves.easeOutCubic),
    );
    _enter1 = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.14, 0.34, curve: Curves.easeOutCubic),
    );
    _enter2 = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.28, 0.48, curve: Curves.easeOutCubic),
    );

    // Her kapsül kendi 15° dönüşü (biraz staggered, aynı hissiyat)
    _tilt0 = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.52, 0.82, curve: Curves.easeInOutCubic),
    );
    _tilt1 = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.56, 0.86, curve: Curves.easeInOutCubic),
    );
    _tilt2 = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.60, 0.90, curve: Curves.easeInOutCubic),
    );

    if (widget.playIntro) {
      _controller.forward();
    } else {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double pillH = widget.height;
    final double pillW = pillH * MyGarajLogo._aspect;
    final double step = pillW * MyGarajLogo._stepFactor;
    final double contentW = pillW + step * 2;
    final double contentH = pillH;

    // Tek kapsül 15° alt pivotla dönerken yatay salınım için yan boşluk
    final double rad = MyGarajLogo._tiltDeg * math.pi / 180;
    final double swing = pillH * math.sin(rad);
    final double boxW = contentW + swing * 0.35;
    final double boxH = contentH;

    return SizedBox(
      width: boxW,
      height: boxH,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, _) {
          return Center(
            child: SizedBox(
              width: contentW,
              height: contentH,
              child: Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  // Her kapsül bağımsız — alt hizada, kendi Transform.rotate'i
                  _Pill(
                    left: 0,
                    width: pillW,
                    height: pillH,
                    color: MyGarajLogo.navy,
                    enter: _enter0.value,
                    tilt: _tilt0.value,
                    showShadow: widget.showShadow,
                  ),
                  _Pill(
                    left: step,
                    width: pillW,
                    height: pillH,
                    color: MyGarajLogo.white,
                    enter: _enter1.value,
                    tilt: _tilt1.value,
                    showShadow: widget.showShadow,
                    bordered: true,
                  ),
                  _Pill(
                    left: step * 2,
                    width: pillW,
                    height: pillH,
                    color: MyGarajLogo.green,
                    enter: _enter2.value,
                    tilt: _tilt2.value,
                    showShadow: widget.showShadow,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.left,
    required this.width,
    required this.height,
    required this.color,
    required this.enter,
    required this.tilt,
    this.showShadow = true,
    this.bordered = false,
  });

  final double left;
  final double width;
  final double height;
  final Color color;
  final double enter;
  final double tilt;
  final bool showShadow;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    final double t = enter.clamp(0.0, 1.0);
    final double angle =
        tilt.clamp(0.0, 1.0) * MyGarajLogo._tiltDeg * math.pi / 180;

    return Positioned(
      left: left,
      bottom: 0,
      width: width,
      height: height,
      child: Opacity(
        opacity: t,
        child: Transform.scale(
          scale: 0.55 + 0.45 * t,
          alignment: Alignment.bottomCenter,
          child: Transform.rotate(
            // Her kapsül kendi alt merkezinden döner → alt kenarlar aynı hizada kalır
            angle: angle,
            alignment: Alignment.bottomCenter,
            child: Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(width / 2),
                border: bordered
                    ? Border.all(
                        color: MyGarajLogo.navy.withValues(alpha: 0.12),
                        width: 0.8,
                      )
                    : null,
                boxShadow: showShadow
                    ? <BoxShadow>[
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.16 * t),
                          blurRadius: 5,
                          offset: const Offset(1, 2),
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Logo + MyGaraj yazısı yatay.
class MyGarajBrandMark extends StatelessWidget {
  const MyGarajBrandMark({
    super.key,
    this.logoHeight = 32,
    this.fontSize = 22,
    this.compact = false,
    this.animateLogo = true,
  });

  final double logoHeight;
  final double fontSize;
  final bool compact;
  final bool animateLogo;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        MyGarajLogo(height: logoHeight, playIntro: animateLogo),
        SizedBox(width: compact ? 8 : 12),
        Text.rich(
          TextSpan(
            children: <InlineSpan>[
              TextSpan(
                text: 'My',
                style: TextStyle(
                  color: MyGarajLogo.green,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                  height: 1,
                ),
              ),
              TextSpan(
                text: 'Garaj',
                style: TextStyle(
                  color: MyGarajLogo.navy,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

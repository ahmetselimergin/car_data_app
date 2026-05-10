part of 'package:car_data_app/screens/home_screen.dart';

// Figma (approx. 385×254): top tapered card 250px, bottom rounded card 170px,
// corner radius 46px. Top card narrows left→right on both top and bottom edges.

const double _kHeroCardDesignWidth = 385.44;
const double _kHeroTopCardHeightPx = 250;
const double _kHeroBottomCardHeightPx = 170;
const double _kHeroCardCornerRadiusPx = 46;
const double _kTaperRightHeightFactor = 1;

class _CarHeaderCard extends StatelessWidget {
  const _CarHeaderCard({
    required this.car,
    required this.logs,
    required this.onEdit,
  });

  final Car car;
  final List<Maintenance> logs;
  final VoidCallback onEdit;

  String get _totalKmText {
    final int fromCar = car.km;
    final int fromLogs = logs.isEmpty
        ? 0
        : logs.map((Maintenance e) => e.km).reduce(math.max);
    final int v = math.max(fromCar, fromLogs);
    return NumberFormat.decimalPattern('tr_TR').format(v);
  }

  String get _transmissionLabel => car.transmission?.trim().isNotEmpty == true
      ? car.transmission!.trim()
      : '—';

  String get _fuelLabel =>
      car.fuelType?.trim().isNotEmpty == true ? car.fuelType!.trim() : '—';

  String get _plakaLabel {
    final String p = car.plaka.trim();
    if (p.isEmpty) return '—';
    return TurkishPlateValidator.formatDisplay(p);
  }

  @override
  Widget build(BuildContext context) {
    final Color accent =
        CarCardPalette.resolve(argbValue: car.cardColor, seed: car.id);
    final Color bottomColor = Color.lerp(accent, Colors.white, 0.40)!;
    final Color topTaperColor = accent;
    final Color lineFg = Colors.white;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double w = constraints.maxWidth;
          final double s = (w / _kHeroCardDesignWidth).clamp(0.22, 1.0);
          final double hTop = _kHeroTopCardHeightPx * s;
          final double hBottom = _kHeroBottomCardHeightPx * s;
          final double br = math
              .min(_kHeroCardCornerRadiusPx * s, math.min(w, hTop) * 0.18)
              .clamp(16.0, _kHeroCardCornerRadiusPx);
          final double rightSpan = math.max(
            90 * s,
            hBottom * _kTaperRightHeightFactor,
          );

          return SizedBox(
            height: hTop,
            child: Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                // Alt kart 170px; hBottom altında ek renk şeridi yok (taper dışı scaffold).
                // Bottom card — 170px design height, 46 radius, same top-left.
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: hBottom,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: bottomColor,
                      borderRadius: BorderRadius.circular(br),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.22),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                  ),
                ),
                // Üst kart (daralan), açık accent.
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: hTop,
                  child: CustomPaint(
                    painter: _TaperedTopCardPainter(
                      color: topTaperColor,
                      rightInnerHeight: rightSpan,
                      cornerRadius: br,
                      shadowColor: bottomColor.withValues(alpha: 0.25),
                      shadowBlur: 12,
                    ),
                  ),
                ),
                // Üstteki açık taper alanından kaçınmak için aşağı; başlık full width, edit en sağda.
                Positioned(
                  top: 44 * s,
                  left: 14 * s,
                  right: 8 * s,
                  bottom: 12 * s,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          BrandLogoCircle(
                            marka: car.marka,
                            size: 40 * s,
                            accent: accent,
                          ),
                          SizedBox(width: 10 * s),
                          Expanded(
                            child: Row(
                              children: <Widget>[
                                Flexible(
                                  flex: 2,
                                  child: Text(
                                    car.marka,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: lineFg,
                                      fontSize: 18 * s,
                                      fontWeight: FontWeight.w800,
                                      height: 1.15,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8 * s),
                                Flexible(
                                  flex: 3,
                                  child: Text(
                                    car.model,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: lineFg,
                                      fontSize: 18 * s,
                                      fontWeight: FontWeight.w600,
                                      height: 1.15,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 8 * s),
                          Material(
                            color: lineFg.withValues(alpha: 0.16),
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: onEdit,
                              child: SizedBox(
                                width: 36 * s,
                                height: 36 * s,
                                child: Icon(
                                  Icons.edit_outlined,
                                  color: lineFg,
                                  size: 18 * s,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10 * s),
                      Expanded(
                        child: LayoutBuilder(
                          builder:
                              (BuildContext _, BoxConstraints bc) {
                            final double maxH = bc.maxHeight;
                            final double imgH = maxH * 0.96;
                            final double gap = 10 * s;
                            final double iconSz = 19 * s;
                            final double fontSz = 14.5 * s;
                            return Row(
                              children: <Widget>[
                                Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(top: 2 * s),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        _HeroSpecRow(
                                          icon: Icons.map_outlined,
                                          label: '$_totalKmText km',
                                          gap: gap,
                                          iconSize: iconSz,
                                          fontSize: fontSz,
                                          color: lineFg,
                                        ),
                                        SizedBox(height: 10 * s),
                                        _HeroSpecRow(
                                          icon: Icons.settings_suggest_outlined,
                                          label: _transmissionLabel,
                                          gap: gap,
                                          iconSize: iconSz,
                                          fontSize: fontSz,
                                          color: lineFg,
                                        ),
                                        SizedBox(height: 10 * s),
                                        _HeroSpecRow(
                                          icon:
                                              Icons.local_gas_station_outlined,
                                          label: _fuelLabel,
                                          gap: gap,
                                          iconSize: iconSz,
                                          fontSize: fontSz,
                                          color: lineFg,
                                        ),
                                        SizedBox(height: 10 * s),
                                        _HeroSpecRow(
                                          icon: Icons.confirmation_number_outlined,
                                          label: _plakaLabel,
                                          gap: gap,
                                          iconSize: iconSz,
                                          fontSize: fontSz,
                                          color: lineFg,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Align(
                                    // Sağ kolon aracı plaka satırının hizasına yaklaştır.
                                    alignment: const Alignment(0, 1),
                                    child: SizedBox(
                                      width: double.infinity,
                                      height: imgH,
                                      child: IgnorePointer(
                                        child: _CarImage(
                                          imagePath: car.imagePath,
                                          slotHeight: imgH,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HeroSpecRow extends StatelessWidget {
  const _HeroSpecRow({
    required this.icon,
    required this.label,
    required this.gap,
    required this.iconSize,
    required this.fontSize,
    required this.color,
  });

  final IconData icon;
  final String label;
  final double gap;
  final double iconSize;
  final double fontSize;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        SizedBox(
          width: iconSize + 4,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Icon(
              icon,
              size: iconSize,
              color: color.withValues(alpha: 0.92),
            ),
          ),
        ),
        SizedBox(width: gap),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color.withValues(alpha: 0.95),
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}

class _CarHeroImageCache {
  static final Map<String, Uint8List> _bytes = <String, Uint8List>{};

  static Future<Uint8List> normalizedForPath(String path) async {
    final Uint8List? hit = _bytes[path];
    if (hit != null) return hit;
    final Uint8List raw = await File(path).readAsBytes();
    final Uint8List out =
        await Isolate.run(() => normalizeCarImageBytes(raw));
    if (_bytes.length > 24) {
      _bytes.clear();
    }
    _bytes[path] = out;
    return out;
  }
}

class _CarImage extends StatefulWidget {
  const _CarImage({
    required this.imagePath,
    this.slotHeight,
  });

  final String? imagePath;
  /// Verilirse görsel bu yükseklikte [BoxFit.contain] ile ölçeklenir.
  final double? slotHeight;

  @override
  State<_CarImage> createState() => _CarImageState();
}

class _CarImageState extends State<_CarImage> {
  Uint8List? _normalized;
  bool _useFileFallback = false;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _CarImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imagePath != widget.imagePath) {
      _normalized = null;
      _useFileFallback = false;
      _load();
    }
  }

  Future<void> _load() async {
    final String? path = widget.imagePath;
    if (path == null || path.isEmpty) return;
    final File f = File(path);
    if (!await f.exists()) return;
    final int gen = ++_loadGeneration;
    try {
      final Uint8List bytes = await _CarHeroImageCache.normalizedForPath(path);
      if (!mounted || gen != _loadGeneration) return;
      setState(() {
        _normalized = bytes;
        _useFileFallback = false;
      });
    } catch (_) {
      if (!mounted || gen != _loadGeneration) return;
      setState(() => _useFileFallback = true);
    }
  }

  double get _placeholderIconSize {
    final double? h = widget.slotHeight;
    if (h != null) {
      return h * 0.38;
    }
    return 110;
  }

  @override
  Widget build(BuildContext context) {
    final String? path = widget.imagePath;
    final double? sh = widget.slotHeight;

    if (path == null ||
        path.isEmpty ||
        !File(path).existsSync()) {
      return Icon(
        Icons.directions_car,
        size: _placeholderIconSize,
        color: Colors.white.withValues(alpha: 0.5),
      );
    }

    if (_useFileFallback) {
      return Image.file(
        File(path),
        height: sh,
        fit: BoxFit.contain,
        alignment: Alignment.center,
      );
    }

    if (_normalized != null) {
      return Image.memory(
        _normalized!,
        height: sh,
        fit: BoxFit.contain,
        alignment: Alignment.center,
        gaplessPlayback: true,
      );
    }

    return Icon(
      Icons.directions_car,
      size: (_placeholderIconSize * 0.55).clamp(48.0, 88.0),
      color: Colors.white.withValues(alpha: 0.35),
    );
  }
}

/// Tapered top card (Figma): left height = [size.height], right vertical span
/// = [rightInnerHeight]. Top edge slopes down L→R; bottom slopes up L→R.
/// All corners use circular fillets ([arcToPoint]).
class _TaperedTopCardPainter extends CustomPainter {
  const _TaperedTopCardPainter({
    required this.color,
    required this.rightInnerHeight,
    this.cornerRadius = 46,
    this.shadowColor,
    this.shadowBlur = 0,
  });

  final Color color;
  /// Height of the right side (matches bottom dark card design height).
  final double rightInnerHeight;
  final double cornerRadius;
  final Color? shadowColor;
  final double shadowBlur;

  static Offset _norm(Offset v) {
    final double d = v.distance;
    if (d < 1e-9) {
      return Offset.zero;
    }
    return Offset(v.dx / d, v.dy / d);
  }

  Path _path(Size size) {
    final double w = size.width;
    final double h = size.height;
    final double rCap = math.min(
      cornerRadius,
      math.min(w * 0.16, h * 0.18),
    );

    final double yTr = (h - rightInnerHeight) / 2;
    final double yBr = yTr + rightInnerHeight;

    // Clockwise: TL → TR → BR → BL — both top and bottom narrow to the right.
    final List<Offset> pts = <Offset>[
      Offset.zero,
      Offset(w, yTr),
      Offset(w, yBr),
      Offset(0, h),
    ];

    final Path path = Path();
    for (int i = 0; i < 4; i++) {
      final Offset prev = pts[(i + 3) % 4];
      final Offset curr = pts[i];
      final Offset next = pts[(i + 1) % 4];

      final Offset v1 = _norm(curr - prev);
      final Offset v2 = _norm(next - curr);
      final double cosInterior =
          (-v1.dx * v2.dx - v1.dy * v2.dy).clamp(-1.0, 1.0);
      final double angle = math.acos(cosInterior);

      if (angle < 1e-3 || (math.pi - angle).abs() < 1e-3) {
        if (i == 0) {
          path.moveTo(curr.dx, curr.dy);
        } else {
          path.lineTo(curr.dx, curr.dy);
        }
        continue;
      }

      final double tanHalf = math.tan(angle / 2);
      double dist = rCap / tanHalf;
      final double lenIn = (curr - prev).distance;
      final double lenOut = (next - curr).distance;
      final double maxD = math.min(lenIn, lenOut) / 2 - 0.5;
      dist = math.min(dist, maxD);
      if (dist < 1.0) {
        if (i == 0) {
          path.moveTo(curr.dx, curr.dy);
        } else {
          path.lineTo(curr.dx, curr.dy);
        }
        continue;
      }

      final Offset pStart = Offset(
        curr.dx - v1.dx * dist,
        curr.dy - v1.dy * dist,
      );
      final Offset pEnd = Offset(
        curr.dx + v2.dx * dist,
        curr.dy + v2.dy * dist,
      );

      if (i == 0) {
        path.moveTo(pStart.dx, pStart.dy);
      } else {
        path.lineTo(pStart.dx, pStart.dy);
      }
      path.arcToPoint(
        pEnd,
        radius: Radius.circular(rCap),
        rotation: 0,
        largeArc: false,
        clockwise: true,
      );
    }
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final Path path = _path(size);
    if (shadowColor != null && shadowBlur > 0) {
      canvas.drawShadow(path, shadowColor!, shadowBlur, false);
    }
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TaperedTopCardPainter old) =>
      old.color != color ||
      old.rightInnerHeight != rightInnerHeight ||
      old.cornerRadius != cornerRadius ||
      old.shadowColor != shadowColor ||
      old.shadowBlur != shadowBlur;
}

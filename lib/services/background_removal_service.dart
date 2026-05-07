import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:image_background_remover/image_background_remover.dart';

/// Cihaz üstü (ONNX) bir model ile fotoğrafın arka planını siler ve
/// saydam PNG byte'ları döndürür. Tamamen offline; harici servis yok.
///
/// `BackgroundRemover` singleton'ı app boyunca tek sefer init edilmeli.
/// Bunu `main.dart` içinde yapıyoruz.
class BackgroundRemovalService {
  BackgroundRemovalService._();
  static final BackgroundRemovalService instance = BackgroundRemovalService._();

  bool _initialized = false;

  /// Gradyan tabanlı maske iyileştirmesi taşlı zemin, su vb. yoğun dokuda
  /// maskeyi bozup araç altında koyu leke bırakabiliyor — kapalı.
  static const double _maskThreshold = 0.51;

  /// Çok düşük alfa “kirli” pikseller açık zeminde batık görünür; tamamen sıfırlanır.
  static const int _minAlphaKeep = 22;

  /// `runApp`'dan önce bir kez çağrılır. Asıl model dosyası ilk
  /// `removeBg` çağrısında belleğe alınır; init işlemi hızlıdır.
  Future<void> init() async {
    if (_initialized) return;
    try {
      await BackgroundRemover.instance.initializeOrt();
      _initialized = true;
    } catch (e) {
      debugPrint('BackgroundRemover init hatası: $e');
    }
  }

  /// Maske sonrası zayıf kenar piksellerini temizler (RGB ve alfa sıfırlanır).
  static void _cleanupWeakAlpha(Uint8List rgba) {
    for (int i = 0; i < rgba.length; i += 4) {
      final int a = rgba[i + 3];
      if (a < _minAlphaKeep) {
        rgba[i] = 0;
        rgba[i + 1] = 0;
        rgba[i + 2] = 0;
        rgba[i + 3] = 0;
      } else if (a > 246) {
        rgba[i + 3] = 255;
      }
    }
  }

  static Future<ui.Image> _imageFromRgba(Uint8List rgba, int w, int h) {
    final Completer<ui.Image> done = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      rgba,
      w,
      h,
      ui.PixelFormat.rgba8888,
      (ui.Image img) => done.complete(img),
    );
    return done.future;
  }

  /// [imageBytes] verilen fotoğrafı modele besler ve arka planı silinmiş
  /// PNG byte'larını döndürür. Hata olursa `null` döner; çağıran tarafta
  /// orijinal fotoğrafa fallback yapılabilir.
  Future<Uint8List?> removeBackground(Uint8List imageBytes) async {
    try {
      if (!_initialized) {
        await init();
      }
      final ui.Image result =
          await BackgroundRemover.instance.removeBg(
        imageBytes,
        threshold: _maskThreshold,
        smoothMask: true,
        enhanceEdges: false,
      );
      final int w = result.width;
      final int h = result.height;
      final ByteData? raw =
          await result.toByteData(format: ui.ImageByteFormat.rawRgba);
      result.dispose();
      if (raw == null) return null;

      final Uint8List rgba = Uint8List.fromList(raw.buffer.asUint8List());
      _cleanupWeakAlpha(rgba);

      final ui.Image cleaned = await _imageFromRgba(rgba, w, h);
      final ByteData? png =
          await cleaned.toByteData(format: ui.ImageByteFormat.png);
      cleaned.dispose();
      return png?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Arka plan silme hatası: $e');
      return null;
    }
  }
}

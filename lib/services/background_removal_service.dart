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

  /// [imageBytes] verilen fotoğrafı modele besler ve arka planı silinmiş
  /// PNG byte'larını döndürür. Hata olursa `null` döner; çağıran tarafta
  /// orijinal fotoğrafa fallback yapılabilir.
  Future<Uint8List?> removeBackground(Uint8List imageBytes) async {
    try {
      if (!_initialized) {
        await init();
      }
      final ui.Image result =
          await BackgroundRemover.instance.removeBg(imageBytes);
      final ByteData? data =
          await result.toByteData(format: ui.ImageByteFormat.png);
      result.dispose();
      return data?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Arka plan silme hatası: $e');
      return null;
    }
  }
}

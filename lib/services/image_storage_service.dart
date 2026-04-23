import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Araç fotoğraflarını uygulama kalıcı dizinine (`<docs>/car_images/`)
/// kopyalayan ve silen küçük yardımcı.
///
/// `image_picker` geçici bir dosya döndürür; cihaz/uygulama yeniden
/// başladığında bu dosya silinebilir, bu yüzden seçilen fotoğraf
/// her zaman önce kalıcı bir konuma kopyalanmalı.
class ImageStorageService {
  ImageStorageService._();
  static final ImageStorageService instance = ImageStorageService._();

  static const String _subDir = 'car_images';

  Future<Directory> _ensureDir() async {
    final Directory docs = await getApplicationDocumentsDirectory();
    final Directory dir = Directory(p.join(docs.path, _subDir));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// [sourcePath]'teki dosyayı kalıcı dizine kopyalar ve yeni yolu döndürür.
  /// Aynı isimli eski dosya varsa üzerine yazılır.
  Future<String> saveCarImage(String sourcePath) async {
    final Directory dir = await _ensureDir();
    final String ext = p.extension(sourcePath).isEmpty
        ? '.jpg'
        : p.extension(sourcePath);
    final String fileName =
        'car_${DateTime.now().millisecondsSinceEpoch}$ext';
    final String destPath = p.join(dir.path, fileName);
    await File(sourcePath).copy(destPath);
    return destPath;
  }

  /// Hazır byte buffer'ı (örn. arka planı silinmiş PNG) belirtilen [extension]
  /// uzantısıyla kalıcı dizine yazar ve yolu döndürür.
  Future<String> saveCarImageBytes(
    Uint8List bytes, {
    String extension = '.png',
  }) async {
    final Directory dir = await _ensureDir();
    final String fileName =
        'car_${DateTime.now().millisecondsSinceEpoch}$extension';
    final String destPath = p.join(dir.path, fileName);
    await File(destPath).writeAsBytes(bytes, flush: true);
    return destPath;
  }

  /// Verilen yoldaki fotoğrafı diskten siler. Hata durumunda sessizce geçer.
  Future<void> deleteIfExists(String? path) async {
    if (path == null || path.isEmpty) return;
    try {
      final File f = File(path);
      if (await f.exists()) {
        await f.delete();
      }
    } catch (_) {
      // Sessizce yut: dosya zaten yoksa veya silinemiyorsa kullanıcıya gösterme.
    }
  }
}

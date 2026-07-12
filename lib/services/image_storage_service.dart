import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../utils/car_image_normalize.dart';

/// Araç fotoğraflarını uygulama kalıcı dizinine (`<docs>/car_images/`) yazar.
///
/// DB’de **göreli** yol tutulur (`car_images/car_….jpg`). iOS container UUID’si
/// değişince mutlak yollar kırılır; göreli yol + [resolvePath] bunu önler.
class ImageStorageService {
  ImageStorageService._();
  static final ImageStorageService instance = ImageStorageService._();

  static const String _subDir = 'car_images';

  static bool isRemoteUrl(String? value) {
    if (value == null || value.isEmpty) return false;
    final String v = value.trim().toLowerCase();
    return v.startsWith('http://') || v.startsWith('https://');
  }

  Future<Directory> _docsDir() => getApplicationDocumentsDirectory();

  Future<Directory> _ensureDir() async {
    final Directory docs = await _docsDir();
    final Directory dir = Directory(p.join(docs.path, _subDir));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// DB’ye yazılacak göreli yol (`car_images/…`).
  String toRelative(String absoluteOrRelative) {
    final String name = p.basename(absoluteOrRelative);
    return p.join(_subDir, name);
  }

  /// Saklanan değeri mevcut Documents altına çözer.
  /// Eski mutlak yollarda dosya yoksa aynı dosya adıyla `car_images/` içinde arar.
  Future<String?> resolvePath(String? stored) async {
    if (stored == null || stored.trim().isEmpty) return null;
    final String raw = stored.trim();

    // Supabase Storage public URL — yerel dosya değil.
    if (isRemoteUrl(raw)) return raw;

    if (!p.isAbsolute(raw)) {
      final Directory docs = await _docsDir();
      final String joined = p.join(docs.path, raw);
      if (await File(joined).exists()) return joined;
      // Sadece dosya adı verilmiş olabilir.
      final String inSub = p.join(docs.path, _subDir, p.basename(raw));
      if (await File(inSub).exists()) return inSub;
      return null;
    }

    if (await File(raw).exists()) return raw;

    // Container UUID değişmiş: basename ile kurtar.
    final Directory dir = await _ensureDir();
    final String recovered = p.join(dir.path, p.basename(raw));
    if (await File(recovered).exists()) return recovered;
    return null;
  }

  /// [sourcePath]'teki dosyayı kalıcı dizine kopyalar; **göreli** yol döner.
  Future<String> saveCarImage(String sourcePath) async {
    final Directory dir = await _ensureDir();
    final String extRaw = p.extension(sourcePath).isEmpty
        ? '.jpg'
        : p.extension(sourcePath);
    final String fileName =
        'car_${DateTime.now().millisecondsSinceEpoch}$extRaw';
    final String destPath = p.join(dir.path, fileName);
    if (extRaw.toLowerCase() == '.png') {
      final Uint8List raw = await File(sourcePath).readAsBytes();
      final Uint8List out =
          await Isolate.run(() => normalizeCarImageBytes(raw));
      await File(destPath).writeAsBytes(out, flush: true);
    } else {
      await File(sourcePath).copy(destPath);
    }
    return toRelative(destPath);
  }

  /// Byte buffer’ı kalıcı dizine yazar; **göreli** yol döner.
  Future<String> saveCarImageBytes(
    Uint8List bytes, {
    String extension = '.png',
  }) async {
    final Directory dir = await _ensureDir();
    final String fileName =
        'car_${DateTime.now().millisecondsSinceEpoch}$extension';
    final String destPath = p.join(dir.path, fileName);
    Uint8List out = bytes;
    if (extension.toLowerCase() == '.png') {
      out = await Isolate.run(() => normalizeCarImageBytes(bytes));
    }
    await File(destPath).writeAsBytes(out, flush: true);
    return toRelative(destPath);
  }

  Future<void> deleteIfExists(String? stored) async {
    if (isRemoteUrl(stored)) return;
    final String? path = await resolvePath(stored);
    if (path == null || path.isEmpty) return;
    try {
      final File f = File(path);
      if (await f.exists()) {
        await f.delete();
      }
    } catch (_) {}
  }
}

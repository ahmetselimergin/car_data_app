import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// PNG imzası (kabaca).
bool isPngMagic(Uint8List bytes) =>
    bytes.length >= 8 &&
    bytes[0] == 0x89 &&
    bytes[1] == 0x50 &&
    bytes[2] == 0x4E &&
    bytes[3] == 0x47;

/// Kesilmiş araç PNG’lerindeki gereksiz şeffaf çerçeveyi kırpar.
/// JPG vb. için giriş aynen döner ([Isolate] içinde güvenle çağrılabilir).
Uint8List normalizeCarImageBytes(Uint8List bytes) {
  if (!isPngMagic(bytes)) return bytes;
  final img.Image? src = img.decodePng(bytes);
  if (src == null) return bytes;

  const int alphaThreshold = 18;
  int minX = src.width;
  int minY = src.height;
  int maxX = 0;
  int maxY = 0;
  bool found = false;

  for (int y = 0; y < src.height; y++) {
    for (int x = 0; x < src.width; x++) {
      final num a = src.getPixel(x, y).a;
      if (a > alphaThreshold) {
        found = true;
        if (x < minX) minX = x;
        if (y < minY) minY = y;
        if (x > maxX) maxX = x;
        if (y > maxY) maxY = y;
      }
    }
  }

  if (!found) return bytes;

  if (minX == 0 &&
      minY == 0 &&
      maxX == src.width - 1 &&
      maxY == src.height - 1) {
    return bytes;
  }

  final int cw = maxX - minX + 1;
  final int ch = maxY - minY + 1;
  if (cw < 1 || ch < 1) return bytes;

  final img.Image cropped = img.copyCrop(
    src,
    x: minX,
    y: minY,
    width: cw,
    height: ch,
  );
  return Uint8List.fromList(img.encodePng(cropped));
}

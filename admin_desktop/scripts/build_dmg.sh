#!/usr/bin/env bash
# Cardex Admin macOS .dmg paketleyici
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

VERSION="${1:-$(grep '^version:' pubspec.yaml | awk '{print $2}' | cut -d'+' -f1)}"
APP_DISPLAY_NAME="Cardex Admin"
DMG_NAME="CardexAdmin-${VERSION}.dmg"
DIST="$ROOT/dist"
STAGE="$DIST/dmg_stage"

echo "==> flutter pub get"
flutter pub get

if [[ ! -f "$ROOT/.env" ]]; then
  echo "Hata: .env yok. cp .env.example .env ve değerleri doldurun." >&2
  exit 1
fi

echo "==> flutter build macos --release"
flutter build macos --release

# PRODUCT_NAME değişince bundle adı da değişebilir
APP_PATH=""
for candidate in \
  "$ROOT/build/macos/Build/Products/Release/Cardex Admin.app" \
  "$ROOT/build/macos/Build/Products/Release/admin_desktop.app"
do
  if [[ -d "$candidate" ]]; then
    APP_PATH="$candidate"
    break
  fi
done

if [[ -z "$APP_PATH" ]]; then
  echo "Hata: Release .app bulunamadı." >&2
  exit 1
fi

rm -rf "$STAGE"
mkdir -p "$STAGE" "$DIST"
cp -R "$APP_PATH" "$STAGE/$APP_DISPLAY_NAME.app"
ln -s /Applications "$STAGE/Applications"

VOL_NAME="Cardex Admin"
DMG_OUT="$DIST/$DMG_NAME"
rm -f "$DMG_OUT"

echo "==> hdiutil create $DMG_OUT"
hdiutil create \
  -volname "$VOL_NAME" \
  -srcfolder "$STAGE" \
  -ov \
  -format UDZO \
  "$DMG_OUT"

rm -rf "$STAGE"
echo "Hazır: $DMG_OUT"
echo "Not: İmzasız DMG Gatekeeper uyarısı verebilir — Sistem Ayarları → Gizlilik ve Güvenlik → Yine de Aç."

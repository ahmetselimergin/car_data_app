# car_data_app (Garaj / CarDEX)

Türkiye odaklı araç garajı yönetimi. Monorepo yapısı:

| Klasör | Ne işe yarar |
| --- | --- |
| `lib/` | Flutter mobil uygulama (Garaj) — iOS / Android |
| `admin_desktop/` | Flutter macOS admin paneli (`.dmg`) — Supabase |
| `supabase/` | Admin katalog şeması + seed |

---

## Gereksinimler

| Bileşen | Gereksinim |
| --- | --- |
| Mobil | [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart `^3.11.5`) |
| Android | Android SDK + emülatör veya fiziksel cihaz |
| iOS (geliştirme macOS) | Xcode + CocoaPods |
| Admin masaüstü | Flutter + Xcode (macOS) + Supabase projesi |

Kurulumu doğrulamak için (repo kökünde):

```bash
flutter doctor -v
```

---

## Mobil uygulama (Flutter)

Tüm komutlar **repo kökünde** (`car_data_app/`) çalıştırılır.

### Kurulum ve çalıştırma

| Ne yapmak istiyorsun? | Komut |
| --- | --- |
| Paketleri yükle | `flutter pub get` |
| Paketleri güncelle | `flutter pub upgrade` |
| Bağlı cihazları listele | `flutter devices` |
| Uygulamayı çalıştır (varsayılan cihaz) | `flutter run` |
| Belirli cihazda çalıştır | `flutter run -d <cihaz_kimliği>` |
| Android emülatörde çalıştır | `flutter run -d <android_id>` |
| iOS simülatörde çalıştır | `flutter run -d <ios_id>` |
| Release modunda çalıştır | `flutter run --release` |

### Geliştirme ve kalite

| Ne yapmak istiyorsun? | Komut |
| --- | --- |
| Statik analiz | `flutter analyze` |
| Testleri çalıştır | `flutter test` |
| Derleme önbelleğini temizle | `flutter clean` |
| Temiz kurulum (clean + paketler) | `flutter clean && flutter pub get` |

### Yayın derlemesi

| Ne yapmak istiyorsun? | Komut |
| --- | --- |
| Android APK üret | `flutter build apk` |
| Google Play AAB üret | `flutter build appbundle` |
| iOS derlemesi (macOS + Xcode) | `flutter build ios` |

---

## Admin masaüstü (macOS)

Komutlar `admin_desktop/` klasöründe. Giriş ve katalog: **Supabase Auth + Postgres**.

| Ne yapmak istiyorsun? | Komut |
| --- | --- |
| Ortam dosyasını oluştur | `cp .env.example .env` |
| Paketleri yükle | `flutter pub get` |
| macOS’ta çalıştır | `flutter run -d macos` |
| `.dmg` üret | `./scripts/build_dmg.sh` |

Ayrıntı: [`admin_desktop/README.md`](admin_desktop/README.md) · şema: [`supabase/README.md`](supabase/README.md).

---

## Hızlı başlangıç

```bash
# 1) Mobil
cp .env.example .env   # SUPABASE_URL + ANON_KEY
flutter pub get
flutter run

# 2) Admin (ayrı terminal)
cd admin_desktop && cp .env.example .env
flutter pub get && flutter run -d macos
```

---

## Sorun giderme

| Sorun | Çözüm |
| --- | --- |
| Cihaz görünmüyor | Emülatörü açın; Android için `adb devices` ile kontrol edin |
| iOS pod hatası | `cd ios && pod install && cd ..` sonra tekrar `flutter run` |
| Paket uyumsuzluğu | `flutter clean && flutter pub get` |
| Admin giriş başarısız | Supabase Auth’ta kullanıcı var mı / e-posta onaylı mı kontrol edin |
| Mobil kayıt sonrası giriş yok | Auth → Email → Confirm email kapalı mı (dev) veya e-postayı onaylayın |

---

## İlgili dokümanlar

- [Flutter dokümantasyonu](https://docs.flutter.dev/)
- `supabase/README.md` — migration ve seed
- `admin_desktop/README.md` — masaüstü admin
- `CLAUDE.md` — proje özeti

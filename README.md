# car_data_app

Flutter ile geliştirilmiş araç verisi uygulaması.

## Gereksinimler

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart SDK `^3.11.5` ile uyumlu sürüm)
- **Android:** Android Studio veya en azından Android SDK + emülatör / fiziksel cihaz (USB hata ayıklama açık)
- **iOS (yalnızca macOS):** Xcode ve CocoaPods (`sudo gem install cocoapods` gerekirse)
- **Web / masaüstü:** İlgili platform için Flutter kurulumunda belirtilen ek araçlar

Kurulumun tamam olduğunu kontrol etmek için:

```bash
flutter doctor -v
```

## Projeyi çalıştırma

Proje kök dizinine geçin (`car_data_app`).

### 1. Bağımlılıkları yükle

```bash
flutter pub get
```

### 2. Bağlı cihazları listele

```bash
flutter devices
```

Görünen bir cihaz/emülatör seçerek çalıştırabilir veya tek cihaz varsa doğrudan `flutter run` yeterlidir.

### 3. Uygulamayı çalıştır

```bash
flutter run
```

Belirli bir cihazda çalıştırmak için (cihaz kimliği `flutter devices` çıktısındaki gibi):

```bash
flutter run -d <cihaz_kimliği>
```

Örnekler:

```bash
flutter run -d chrome          # Web (Chrome)
flutter run -d macos             # macOS masaüstü
```

### Yayın (release) modunda çalıştırma

```bash
flutter run --release
```

## Diğer yararlı komutlar

| Komut | Açıklama |
| --- | --- |
| `flutter analyze` | Statik analiz |
| `flutter test` | Testleri çalıştırır |
| `flutter build apk` | Android APK üretir |
| `flutter build appbundle` | Google Play için AAB üretir |
| `flutter build ios` | iOS derlemesi (macOS + Xcode) |

## Sorun giderme

- **Cihaz görünmüyor:** Emülatörü açın veya USB kablosunu / geliştirici seçeneklerini kontrol edin; `adb devices` (Android) ile doğrulayın.
- **iOS pod hataları:** `cd ios && pod install && cd ..` ardından tekrar `flutter run`.
- **Bağımlılık uyumsuzluğu:** `flutter clean` sonra `flutter pub get`.

Daha fazla bilgi: [Flutter dokümantasyonu](https://docs.flutter.dev/).

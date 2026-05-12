# Cardex B2C Özellikleri — Tasarım Belgesi

**Tarih:** 2026-05-12  
**Durum:** Onaylandı  
**Kapsam:** Backend API genişletmesi, Flutter API entegrasyonu, Workshop harita ekranı

---

## 1. Genel Bakış

Cardex, B2C kullanıcıların araçlarını kaydedeceği, hatırlatma alacağı ve en yakın ustayı bulacağı bir mobil sistemdir. Admin paneli bu verilerin yönetim merkezidir.

### Kapsam Dışı (Sonraya Bırakıldı)
- Sigorta teklifi karşılaştırma

---

## 2. Mimari Genel

```
Flutter App
  ├── ApiService (Firebase token → HTTP)
  ├── CarRepository (API)
  ├── ReminderRepository (API)
  └── WorkshopScreen (GPS + Harita)

Backend (Node/Express + PostgreSQL)
  ├── /api/v1/user/*  (Firebase Auth middleware)
  ├── /api/v1/workshops/nearby
  └── Cron Job (FCM push, her gece 08:00)

Admin Panel (Next.js)
  └── Workshop formu → lat/lng alanları eklenir
```

---

## 3. Alt Proje 1 — Backend API Genişletmesi

### 3.1 Veritabanı Değişiklikleri

#### `workshops` tablosu — ek kolonlar
```sql
ALTER TABLE workshops ADD COLUMN latitude  FLOAT;
ALTER TABLE workshops ADD COLUMN longitude FLOAT;
```

#### Yeni `reminders` tablosu
```sql
CREATE TABLE reminders (
  id                   SERIAL PRIMARY KEY,
  car_id               INTEGER NOT NULL REFERENCES cars(id) ON DELETE CASCADE,
  user_uid             TEXT NOT NULL,           -- Firebase UID
  tur                  TEXT NOT NULL,           -- sigorta | kasko | muayene | egzoz
  bitis_tarihi         DATE NOT NULL,
  hatirlatma_gun_oncesi INTEGER NOT NULL DEFAULT 7,
  fcm_sent_at          TIMESTAMP WITH TIME ZONE,
  created_at           TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at           TIMESTAMP WITH TIME ZONE DEFAULT now()
);
CREATE INDEX idx_reminders_user   ON reminders(user_uid);
CREATE INDEX idx_reminders_car    ON reminders(car_id);
CREATE INDEX idx_reminders_bitis  ON reminders(bitis_tarihi);
```

#### Yeni `fcm_tokens` tablosu
```sql
CREATE TABLE fcm_tokens (
  user_uid   TEXT PRIMARY KEY,
  token      TEXT NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);
```

### 3.2 Firebase Auth Middleware

`src/middleware/requireUser.ts` — tüm `/api/v1/user/*` rotaları için:

```
1. Authorization: Bearer <token> header'ını al
2. Firebase Admin SDK ile token'ı doğrula
3. uid'yi req.user.uid olarak ekle
4. Hata → 401
```

### 3.3 Yeni API Uçları

| Method | Path | Açıklama |
|--------|------|----------|
| GET  | `/api/v1/user/cars` | Kullanıcının araçları (uid'ye göre filtreli) |
| POST | `/api/v1/user/cars` | Araç ekle |
| PATCH | `/api/v1/user/cars/:id` | Araç güncelle |
| DELETE | `/api/v1/user/cars/:id` | Araç sil |
| GET  | `/api/v1/user/reminders` | Kullanıcının hatırlatmaları |
| POST | `/api/v1/user/reminders` | Hatırlatma ekle |
| PATCH | `/api/v1/user/reminders/:id` | Hatırlatma güncelle |
| DELETE | `/api/v1/user/reminders/:id` | Hatırlatma sil |
| POST | `/api/v1/user/fcm-token` | FCM cihaz token'ı kaydet/güncelle |
| GET  | `/api/v1/workshops/nearby` | `?lat=&lng=&radius=50` yakın ustalar |

**Nearby endpoint algoritması:**  
Haversine formülü ile her workshop'ın kullanıcıya mesafesi hesaplanır, radius (km) içindekiler mesafeye göre sıralı döner. lat/lng olmayan workshoplar sonuçtan çıkarılır.

### 3.4 FCM Cron Job

`src/jobs/fcmReminders.ts` — her gece 08:00 (Türkiye saati) çalışır:

```
1. bitis_tarihi = BUGÜN + hatirlatma_gun_oncesi olan tüm remindersları bul
   (fcm_sent_at IS NULL olanlar)
2. Her reminder için:
   a. fcm_tokens tablosundan user_uid → token al
   b. Firebase Admin SDK ile push gönder
   c. fcm_sent_at = now() işaretle
```

**Push mesaj formatı:**
- Başlık: `"[tur] Hatırlatması"`
- Body: `"[Araç plakası] için [tur] [N] gün sonra bitiyor."`

Cron kütüphanesi: `node-cron`

---

## 4. Alt Proje 2 — Flutter API Katmanı

### 4.1 ApiService

`lib/services/api_service.dart` — singleton:

```dart
class ApiService {
  static const String baseUrl = String.fromEnvironment('API_URL', defaultValue: 'https://cardex.script-app.cloud');

  Future<Map<String, String>> _headers() async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> get(String path) async { ... }
  Future<dynamic> post(String path, Map body) async { ... }
  Future<dynamic> patch(String path, Map body) async { ... }
  Future<dynamic> delete(String path) async { ... }
}
```

### 4.2 Repository Değişiklikleri

- `CarRepository` → SQLite çağrıları kaldırılır, `ApiService` kullanılır
- `ReminderRepository` → SQLite çağrıları kaldırılır, `ApiService` kullanılır
- `DatabaseHelper` → `cars` ve `reminders` tabloları kaldırılır (maintenance korunur)
- Giriş sonrası: FCM token backend'e POST edilir

### 4.3 Veri Geçişi

İlk açılışta lokal SQLite'daki araçlar ve hatırlatmalar backend'e gönderilir, ardından lokal tablo silinir. Migration tek sefer çalışır (flag: `prefs.getBool('migrated_to_api')`).

---

## 5. Alt Proje 3 — Workshop Harita Ekranı

### 5.1 Yeni Ekran: `WorkshopMapScreen`

- Kullanıcıdan GPS izni istenir (`geolocator` paketi)
- `/api/v1/workshops/nearby?lat=X&lng=Y&radius=50` çağrısı
- `google_maps_flutter` ile harita + her workshop için pin
- Alt panel: liste görünümü (isim, mesafe, telefon)
- Pin veya liste öğesine tıklayınca: bottom sheet (tel, adres, "Yol Tarifi" butonu)
- "Yol Tarifi" → `url_launcher` ile Google Maps yönlendirmesi

### 5.2 Yeni Paketler

```yaml
dependencies:
  google_maps_flutter: ^2.x
  geolocator: ^11.x
  url_launcher: ^6.x
  # node-cron backend için (backend package.json)
```

### 5.3 Google Maps API Anahtarı

- Android: `AndroidManifest.xml` içinde meta-data
- iOS: `AppDelegate.swift` içinde GMSServices.provideAPIKey

---

## 6. Admin Panel Değişiklikleri

Workshop formu (`admin/src/app/workshops/`) güncellenir:
- `Enlem (latitude)` ve `Boylam (longitude)` alanları eklenir
- Mevcut workshoplar için konum girişi yapılabilir

---

## 7. Güvenlik

- Kullanıcı yalnızca kendi `uid`'siyle eşleşen araçları ve hatırlatmaları görebilir/değiştirebilir. Backend her istekte `req.user.uid === car.firebaseUid` doğrular.
- Admin uçları (`/api/v1/cars`, `/api/v1/workshops` vb.) mevcut haliyle korunmaya devam eder (admin paneli kendi auth'una sahip).

---

## 8. Yapım Sırası

1. **Backend** — DB migration → middleware → API uçları → cron job
2. **Flutter servis katmanı** — ApiService → Repository → migration
3. **Flutter UI** — Workshop harita ekranı → FCM token kaydı
4. **Admin panel** — Workshop formu lat/lng alanları

---

## 9. Başarı Kriterleri

- [ ] Kullanıcı araç ekler → backend'de görünür, admin panelinde listelenir
- [ ] Hatırlatma eklenir → gece cron çalışır → telefona push bildirim gelir
- [ ] Workshop harita ekranı GPS konumunu alır → en yakın 3 usta gösterilir
- [ ] Kullanıcı yalnızca kendi araçlarına erişebilir

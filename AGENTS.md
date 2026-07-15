# car_data_app — Codex için proje özeti

Monorepo: **Flutter** (mobil iOS/Android — Supabase Auth), **Flutter macOS admin** (`admin_desktop`), **Supabase** (katalog + Auth).

## Dizin yapısı

| Yol | Rol |
| --- | --- |
| `lib/` | Flutter mobil uygulama kodu |
| `admin_desktop/` | Flutter macOS admin; Supabase Auth + katalog CRUD; `.dmg` |
| `supabase/` | Postgres migration'ları + katalog seed |
| `DEPLOY.md` | Dağıtım notları |

## Hızlı komutlar

**Flutter mobil (repo kökü)**

```bash
cp .env.example .env           # SUPABASE_URL + ANON_KEY
flutter pub get
flutter analyze
flutter test
flutter run                    # Android veya iOS
```

**Admin macOS (`admin_desktop/`)**

```bash
cd admin_desktop
cp .env.example .env           # SUPABASE_URL + ANON_KEY
flutter pub get
flutter run -d macos
./scripts/build_dmg.sh
```

## Ortam değişkenleri

- **mobil + admin_desktop:** `SUPABASE_URL`, `SUPABASE_ANON_KEY` (`.env`)
- **supabase seed:** `SUPABASE_URL` + `SUPABASE_SERVICE_ROLE_KEY`

## Veri

- Mobil Auth: Supabase Auth (e-posta/şifre)
- Mobil araç verisi: yerel SQLite
- Admin katalog: Supabase Postgres; giriş Supabase Auth (`authenticated` RLS)
- Marka logoları: Storage `brand-logos`

## Gotcha’lar

- iOS: pod sorununda `cd ios && pod install`.
- Flutter SDK: `pubspec.yaml` içinde `sdk: ^3.11.5`.
- Kayıt sonrası oturum yoksa Supabase’de e-posta onayı açıktır — Dashboard → Auth → Providers → Email → “Confirm email” kapatılabilir (dev).
- Admin DMG imzasız olabilir (Gatekeeper).
- **Sonra:** Google Sign-In — `docs/plans/google-sign-in.md`

## İlgili dokümanlar

- `README.md` — kurulum
- `supabase/README.md` — migration
- `admin_desktop/README.md` — masaüstü admin

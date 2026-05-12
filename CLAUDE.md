# car_data_app — Claude için proje özeti

Monorepo: **Flutter** (mobil istemci), **Node/Express** (`backend` — Cardex API), **Next.js** (`admin` — yönetim arayüzü). Flutter tarafı çoğunlukla yerel SQLite/servisler; admin API üzerinden marka, araç, servis, sigorta ve Firebase kullanıcıları yönetir.

## Dizin yapısı

| Yol | Rol |
| --- | --- |
| `lib/` | Flutter uygulama kodu (ekranlar, repo’lar, servisler) |
| `backend/` | Express 5 + TypeScript + Drizzle + PostgreSQL |
| `admin/` | Next.js 16 admin; `admin/CLAUDE.md` ve `admin/AGENTS.md` Next kuralları |
| `DEPLOY.md` | VPS / Nginx / PM2 dağıtım notları |

## Hızlı komutlar

**Flutter (repo kökü)**

```bash
flutter pub get
flutter analyze
flutter test
flutter run                    # veya: flutter run -d chrome
```

**Backend (`backend/`)**

```bash
cd backend
npm install
cp .env.example .env           # DATABASE_URL zorunlu
npm run db:push                # şemayı DB’ye uygular
npm run dev                    # http://localhost:4000 (tsx watch)
```

Sağlık: `GET http://localhost:4000/health` · API özeti: `GET http://localhost:4000/api/v1`

**Admin (`admin/`)**

```bash
cd admin
npm install
npm run dev                    # Next, varsayılan 3000
```

Admin API tabanı: `NEXT_PUBLIC_API_URL` (sonunda `/` olmadan); yoksa `http://localhost:4000`. İstekler `API_BASE` + `/api/v1/...` üzerinden gider (`admin/src/lib/api.ts`).

## Ortam değişkenleri

- **backend:** `DATABASE_URL`, `PORT` (varsayılan 4000), `CORS_ORIGIN` (ör. `http://localhost:3000`, virgülle çoklu), `FIREBASE_SERVICE_ACCOUNT_PATH` — boşsa `/api/v1/firebase-users` 503 döner. Ayrıntı: `backend/.env.example`.
- **admin:** `NEXT_PUBLIC_API_URL` — production’da API’nin public URL’i.

## API uçları (özet)

`/api/v1` altında: `cars`, `brands`, `models`, `workshops`, `insurance`, `firebase-users`. Statik yüklemeler: `/uploads`.

## Gotcha’lar

- Backend **ESM** (`"type": "module"`); import yollarında `.js` uzantısı derleme çıktısıyla uyumlu.
- iOS: pod sorununda `cd ios && pod install`.
- Flutter SDK: `pubspec.yaml` içinde `sdk: ^3.11.5`.
- Admin için Next 16 kırımları: `admin/AGENTS.md` ve yerel `node_modules/next/dist/docs/` rehberine bak.

## İlgili dokümanlar

- `README.md` — Flutter kurulum ve çalıştırma
- `backend/README.md` — DB kurulumu ve API
- `DEPLOY.md` — sunucu mimarisi ve Nginx örneği

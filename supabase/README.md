# Supabase (admin katalog + Auth)

Admin paneli (`admin_desktop`) marka, model, araç, tamirhane, sigorta ve **giriş** işlemlerini Supabase üzerinden yapar.

## Kurulum

1. [Supabase](https://supabase.com) projesi oluştur.
2. SQL Editor'de sırayla:

   - `supabase/migrations/20260710000000_initial_schema.sql`
   - `supabase/migrations/20260710000001_brand_logos_storage.sql`
   - `supabase/migrations/20260710000002_auth_rls_and_owner_uid.sql`
   - `supabase/migrations/20260710000003_profiles_username.sql`
   - `supabase/migrations/20260710000004_user_types.sql`
   - `supabase/migrations/20260710000005_garage_cars_owner_rls.sql`
   - `supabase/migrations/20260710000006_car_images_storage.sql`
   - `supabase/migrations/20260710000007_card_color_bigint.sql`
   - `supabase/migrations/20260710000008_garage_reminders_maintenance.sql`
   - `supabase/migrations/20260710000009_km_reminders_and_docs.sql`
   - `supabase/migrations/20260714000000_workshops_public_read.sql`
   - `supabase/migrations/20260714000001_workshops_geo.sql`
   - `supabase/migrations/20260714000002_workshops_city.sql`

   Ardından Euro Repar servis noktaları için (opsiyonel):

   ```bash
   python3 supabase/scripts/scrape_euro_repar.py   # workshops_euro_repar.sql üretir
   ```

   Üretilen `workshops_euro_repar.sql`'i SQL Editor'de çalıştır (idempotent).

3. Authentication → Users: **kendi e-postan** ile kullanıcı oluştur (şifreyi sen belirle).
4. SQL ile admin yap:

```sql
update public.profiles
set user_type = 'admin', username = 'admin', updated_at = now()
where lower(email) = 'SENIN_MAILIN@ornek.com';
```

Tipler: `admin` (tam katalog), `partner_user` (tamirhane/sigorta), `normal_user` (mobil).

5. `admin_desktop/.env`:

```env
SUPABASE_URL=https://xxxx.supabase.co
SUPABASE_ANON_KEY=eyJ...
```

6. (İsteğe bağlı) Katalog seed:

```bash
cd admin_desktop
NODE_PATH=./node_modules \
SUPABASE_URL=... \
SUPABASE_SERVICE_ROLE_KEY=... \
npx tsx ../supabase/scripts/seed-catalog.ts
```

Seed dosyası: `supabase/data/catalog-seed.json`

## Mimari

| Katman | Kaynak |
|--------|--------|
| Mobil + admin giriş | Supabase Auth |
| Marka / model / araç / tamirhane / sigorta | Supabase Postgres |
| Kullanıcı listesi / tip | `profiles` (RLS: admin) |
| Kullanıcı ekle / sil | Edge Function `admin-users` (service role) |
| Marka logoları | `brands.logo_url` (seed: car-logos-dataset PNG) + Storage `brand-logos` (manuel yükleme) |
| Mobil logolar | `assets/brand_logos/` (aynı set, offline) |

RLS: katalog yazma `admin`; tamirhane/sigorta `admin` + `partner_user`. Mobil kayıtlar `normal_user`.

Mobil uygulama `.env` ile aynı `SUPABASE_URL` / `SUPABASE_ANON_KEY` kullanır.

## Kullanıcı yönetimi (Edge Function)

Ekleme/silme Auth Admin API ister; service role **asla** Flutter `.env`’e konmaz.

```bash
# bir kez
npx supabase login
npx supabase link --project-ref <PROJECT_REF>

# deploy
npx supabase functions deploy admin-users
```

Dashboard → Edge Functions → `admin-users` da kullanılabilir. Kaynak: `supabase/functions/admin-users/`.

## Not

`cars.owner_uid` — mobil/Supabase Auth kullanıcı id’si.

Giriş: **e-posta veya kullanıcı adı** + şifre. Profiller: `public.profiles` (`user_type` dahil).

Geliştirmede kayıt sonrası hemen giriş için: Dashboard → Authentication → Providers → Email → **Confirm email** kapalı olabilir.

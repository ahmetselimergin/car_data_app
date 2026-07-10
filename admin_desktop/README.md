# Cardex Admin (macOS)

Flutter masaüstü yönetim paneli. Katalog + giriş: **Supabase**.

## Kurulum

1. Migration’ları uygula (`supabase/README.md`) — özellikle `0004_user_types.sql`.
2. Kendi e-postanla Auth kullanıcısı oluştur; SQL ile `user_type = 'admin'` ata.
3. Ortam:

```bash
cd admin_desktop
cp .env.example .env
# SUPABASE_URL + SUPABASE_ANON_KEY
flutter pub get
flutter run -d macos
```

## Kullanıcı tipleri

| Tip | Admin paneli | Yetki |
|-----|--------------|--------|
| `admin` | Evet | Tam katalog |
| `partner_user` | Evet | Tamirhane / sigorta |
| `normal_user` | Hayır | Mobil uygulama |

## .dmg

```bash
./scripts/build_dmg.sh
# dist/CardexAdmin-*.dmg
```

## Ortam değişkenleri

| Değişken | Açıklama |
|----------|----------|
| `SUPABASE_URL` | Proje URL |
| `SUPABASE_ANON_KEY` | Anon / publishable key |

Giriş: e-posta veya kullanıcı adı + şifre. RLS tip bazlı (`is_admin` / `is_staff`).

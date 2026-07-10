# Dağıtım notları

> Express (`backend`) ve Next.js (`admin`) kaldırıldı. Admin artık `admin_desktop` (macOS `.dmg`) + Supabase.

## Güncel mimari

| Bileşen | Dağıtım |
| --- | --- |
| Mobil (iOS/Android) | App Store / Play Store — Flutter build |
| Admin masaüstü | `admin_desktop/scripts/build_dmg.sh` → `.dmg` |
| Veri / Auth (admin) | Supabase (hosted) |

## Admin DMG

```bash
cd admin_desktop
cp .env.example .env   # SUPABASE_URL, SUPABASE_ANON_KEY
./scripts/build_dmg.sh
# dist/CardexAdmin-*.dmg
```

İmzasız paket Gatekeeper uyarısı verebilir.

## Supabase

Migration’lar: `supabase/migrations/`. Prod’da Auth kullanıcılarını Dashboard’dan yönetin; service role key’i client’a koymayın.

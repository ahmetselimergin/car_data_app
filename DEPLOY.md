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

## AI Destek Botu (support-chat)

1. Migration’ı uygula: `supabase db push` (`support_messages`, `support_tickets`).
2. Gemini anahtarını secret olarak ayarla (yalnız sunucuda; aistudio.google.com'dan ücretsiz):
   `supabase secrets set GEMINI_API_KEY=...`
3. Edge Function’ı dağıt: `supabase functions deploy support-chat`
4. Model: `gemini-2.0-flash` (ücretsiz kat). `SUPABASE_URL`/`SUPABASE_ANON_KEY` otomatik enjekte edilir.

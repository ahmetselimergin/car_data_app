# support-chat Edge Function

AI destek botu. Flutter sohbet ekranından çağrılır; Claude API'yi (`claude-haiku-4-5`)
uygulama bağlamını bilen bir system prompt ile çağırır ve yanıtı döndürür.
Sohbet geçmişini `support_messages` tablosuna kaydeder.

## İstek

`POST /functions/v1/support-chat`
Header: `Authorization: Bearer <supabase_jwt>`
Body: `{ "message": "..." }`
Yanıt: `{ "reply": "..." }`

## Secret / dağıtım

```bash
supabase secrets set ANTHROPIC_API_KEY=sk-ant-...
supabase functions deploy support-chat
```

`SUPABASE_URL` ve `SUPABASE_ANON_KEY` fonksiyon ortamına otomatik enjekte edilir.

# support-chat Edge Function

AI destek botu. Flutter sohbet ekranından çağrılır; Google Gemini API'yi (`gemini-2.0-flash`,
ücretsiz kat) uygulama bağlamını bilen bir system prompt ile çağırır ve yanıtı döndürür.
Sohbet geçmişini `support_messages` tablosuna kaydeder.

## İstek

`POST /functions/v1/support-chat`
Header: `Authorization: Bearer <supabase_jwt>`
Body: `{ "message": "..." }`
Yanıt: `{ "reply": "..." }`

## Secret / dağıtım

```bash
supabase secrets set GEMINI_API_KEY=...   # aistudio.google.com üzerinden ücretsiz alınır
supabase functions deploy support-chat
```

`SUPABASE_URL` ve `SUPABASE_ANON_KEY` fonksiyon ortamına otomatik enjekte edilir.

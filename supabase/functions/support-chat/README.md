# support-chat Edge Function

AI destek botu. Flutter sohbet ekranından çağrılır; Groq API'yi (`llama-3.3-70b-versatile`,
ücretsiz, OpenAI uyumlu) uygulama bağlamını bilen bir system prompt ile çağırır ve yanıtı döndürür.
Sohbet geçmişini `support_messages` tablosuna kaydeder.

## İstek

`POST /functions/v1/support-chat`
Header: `Authorization: Bearer <supabase_jwt>`
Body: `{ "message": "..." }`
Yanıt: `{ "reply": "..." }`

## Secret / dağıtım

```bash
supabase secrets set GROQ_API_KEY=gsk_...   # console.groq.com üzerinden ücretsiz alınır
supabase functions deploy support-chat
```

`SUPABASE_URL` ve `SUPABASE_ANON_KEY` fonksiyon ortamına otomatik enjekte edilir.

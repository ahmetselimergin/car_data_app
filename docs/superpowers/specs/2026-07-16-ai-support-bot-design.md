# AI Destek Botu — Tasarım Dokümanı

**Tarih:** 2026-07-16
**Durum:** Onaylandı (uygulamaya hazır)

## Amaç

Kullanıcıya iki alanda yardım eden bir AI destek botu:

1. **Uygulama kullanım yardımı** — garaj, bakım/km hatırlatmaları, en yakın tamirci gibi özelliklerin nasıl kullanılacağı.
2. **Araç arıza triyajı** — kullanıcının anlattığı belirtilerden olası arızayı değerlendirme; gerekirse en yakın tamirciye yönlendirme.

Bot çözemezse kullanıcı bir **destek talebi (ticket)** açabilir. Sohbet geçmişi kullanıcı başına saklanır.

## Mimari

```
Flutter SupportChatScreen
   │  supabase.functions.invoke('support-chat', { message })   ← JWT otomatik eklenir
   ▼
Supabase Edge Function  support-chat  (Deno)
   │  1. auth.getUser() — caller client (RLS)
   │  2. support_messages'tan son ~20 mesajı yükle (geçmiş)
   │  3. Claude API çağır (claude-haiku-4-5, ANTHROPIC_API_KEY secret)
   │  4. kullanıcı mesajını + asistan cevabını support_messages'a yaz
   ▼  { reply } döner
Claude → yalnız metin döner. Ticket açma ve "en yakın tamirci" kullanıcı butonlarıyla yürür.
```

### Anahtar kararlar

- **API anahtarı yalnızca Edge Function secret'ında** (`ANTHROPIC_API_KEY`) tutulur; asla client'ta değil.
- Bot **yalnız metin** döner. Ticket açma ve tamirciye yönlendirme, sohbet ekranındaki **sabit UI butonlarıyla** kullanıcı tarafından tetiklenir (Claude tool-use veya yapısal sinyal yok — bilinçli sadelik).
- Araç bağlamı (marka/model/yıl) **gönderilmez**; Claude gerekirse sohbette sorar (araç verisi mobilde yerel SQLite'ta, ekstra köprü kurmaya değmez).
- **Non-streaming** — tek seferde tam cevap. Buton odaklı sade akışa uygun.
- Tüm yazma işlemleri kullanıcının kendi satırları olduğu için Edge Function **service-role değil, caller client** (RLS uygulanan) kullanır.

## 1. Veritabanı

Yeni migration: `supabase/migrations/20260716000000_support_chat.sql`

### support_messages

| Kolon | Tip | Not |
| --- | --- | --- |
| `id` | `uuid` PK | `default gen_random_uuid()` |
| `user_id` | `uuid` | `references auth.users(id) on delete cascade`, `not null` |
| `role` | `text` | `check (role in ('user','assistant'))`, `not null` |
| `content` | `text` | `not null` |
| `created_at` | `timestamptz` | `default now()` |

- İndeks: `(user_id, created_at)` — geçmiş sorgusu için.
- RLS açık. Politikalar:
  - `select`: `user_id = auth.uid()`
  - `insert`: `user_id = auth.uid()` (with check)

### support_tickets

| Kolon | Tip | Not |
| --- | --- | --- |
| `id` | `uuid` PK | `default gen_random_uuid()` |
| `user_id` | `uuid` | `references auth.users(id) on delete cascade`, `not null` |
| `message` | `text` | `not null` |
| `status` | `text` | `default 'open'`, `check (status in ('open','closed'))` |
| `created_at` | `timestamptz` | `default now()` |

- RLS açık. Politikalar:
  - `select`: kendi satırı (`user_id = auth.uid()`) **veya** çağıran admin (`profiles.user_type = 'admin'` — mevcut admin desenini izler, ileride ticket triyajı için).
  - `insert`: `user_id = auth.uid()` (with check).

## 2. Edge Function: `supabase/functions/support-chat/index.ts`

`admin-users/index.ts` yapısını birebir izler: `corsHeaders`, `json()` yardımcıları, `OPTIONS`/`POST` kontrolü, `Authorization` başlığı, caller client + `auth.getUser()`.

Akış:

1. Ortam: `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `ANTHROPIC_API_KEY` — biri yoksa 500 "Server misconfigured".
2. `Authorization` yoksa 401; `getUser()` başarısızsa 401.
3. Body: `{ message: string }`. Boş/uzun (örn. > 4000 karakter) doğrulaması.
4. Caller client ile `support_messages`'tan bu kullanıcının son ~20 mesajını (`created_at asc`) yükle.
5. Claude Messages API çağrısı:
   - Model: `claude-haiku-4-5`
   - `system`: uygulama bağlamını bilen sistem promptu (aşağıda).
   - `messages`: geçmiş (role/content) + yeni kullanıcı mesajı.
   - `max_tokens`: makul sınır (örn. 1024).
6. Cevap metnini al. Caller client ile iki satır ekle: kullanıcı mesajı (`role='user'`) ve asistan cevabı (`role='assistant'`).
7. `{ reply }` döndür. Claude hatasında 502 + kullanıcı dostu mesaj.

### Sistem promptu (özet içerik)

- Rol: car_data_app araç bakım uygulamasının Türkçe destek asistanı.
- Uygulama özellikleri bağlamı: garaj (araç ekleme/görüntüleme), bakım ve km bazlı hatırlatmalar, evrak takibi, en yakın tamirci listesi.
- İki görev: (a) uygulama kullanım yardımı, (b) araç arıza triyajı.
- Triyajda: belirtileri sor, olası nedenleri sadece bilgilendirme amaçlı açıkla, aciliyet/güvenlik uyarısı ver, gerektiğinde en yakın tamirciye gitmesini öner.
- Çözemediğinde: kullanıcıya sohbet ekranındaki **"Destek Talebi Aç"** veya **"En Yakın Tamirci"** butonlarını kullanabileceğini söyle.
- Sınırlar: kesin teşhis/onarım garantisi verme; teşhisin bir uzmanla doğrulanması gerektiğini belirt.

## 3. Flutter

### `lib/services/support_chat_service.dart`

- `Future<String> sendMessage(String message)` — `Supabase.instance.client.functions.invoke('support-chat', body: {'message': message})`; dönen `reply`'i verir.
- `Future<List<SupportMessage>> loadHistory()` — `support_messages`'tan kullanıcının mesajlarını `created_at asc` okur.
- `Future<void> openTicket(String message)` — `support_tickets`'a satır ekler (`user_id` = current user, `status='open'`).
- Basit `SupportMessage` modeli (`role`, `content`, `createdAt`).

### `lib/screens/support_chat_screen.dart`

- `StatefulWidget`. `initState`'te `loadHistory()`.
- Mesaj listesi (kullanıcı/asistan baloncukları), altta metin girişi + gönder.
- Gönderirken: kullanıcı mesajını iyimser (optimistic) ekle, `sendMessage()` çağır, cevabı ekle; hata durumunda uyarı.
- İki sabit buton (üst app bar aksiyonu veya giriş alanı üstü):
  - **"En Yakın Tamirci"** → `NearestMechanicScreen`'e `Navigator.push`.
  - **"Destek Talebi Aç"** → son kullanıcı mesajını (veya kısa özet) `openTicket()` ile kaydet, onay `SnackBar`'ı göster.
- Türkçe arayüz, mevcut ekran stiline uyum.

### Giriş noktası

- `lib/screens/home/dashboard_tab.dart` içine bir kart/buton eklenir → `SupportChatScreen`'i açar. Mevcut dashboard kart/aksiyon desenine uyumlu.

## 4. Secret / kurulum notları

`supabase/functions/support-chat/README.md` (yeni) ve `DEPLOY.md`'ye eklenir:

```bash
# Anthropic API anahtarını secret olarak ayarla (yalnız sunucuda)
supabase secrets set ANTHROPIC_API_KEY=sk-ant-...

# Fonksiyonu dağıt
supabase functions deploy support-chat
```

- `SUPABASE_URL` ve `SUPABASE_ANON_KEY` Edge Function ortamına otomatik enjekte edilir; ayrıca ayarlamaya gerek yok.
- Client `.env` değişmez (yeni değişken gerekmez).
- Migration'ı uygula: `supabase db push` (veya proje akışına göre).

## Kapsam dışı (YAGNI)

- Streaming cevaplar.
- Claude tool-use / fonksiyon çağırma.
- Araç bağlamının otomatik gönderimi.
- Admin ticket yönetim arayüzü (yalnız RLS ile admin okuma hazır bırakılır).
- Push bildirimi / e-posta ile ticket bildirimi.

## Test / doğrulama

- `flutter analyze` temiz.
- Edge Function: `supabase functions serve support-chat` ile yerelde deneme (geçerli JWT ile).
- Elde: mesaj gönder → cevap gelir; sohbet geçmişi yeniden yüklenince korunur; ticket açılınca `support_tickets`'ta satır oluşur; RLS başka kullanıcının satırlarını göstermez.

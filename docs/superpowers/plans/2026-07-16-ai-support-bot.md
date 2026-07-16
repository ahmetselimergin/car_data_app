# AI Destek Botu Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Kullanıcıya uygulama kullanım yardımı ve araç arıza triyajı sağlayan, çözülemeyen durumlarda destek talebi açan bir AI sohbet botu ekle.

**Architecture:** Flutter sohbet ekranı → Supabase Edge Function (`support-chat`, Deno) → Claude API (`claude-haiku-4-5`). API anahtarı yalnız Edge Function secret'ında. Bot yalnız metin döner; ticket açma ve "en yakın tamirci" sohbet ekranındaki sabit UI butonlarıyla kullanıcı tarafından tetiklenir. Sohbet geçmişi `support_messages`, talepler `support_tickets` tablolarında RLS ile kullanıcı başına saklanır.

**Tech Stack:** Flutter (`supabase_flutter ^2.9.1`), Supabase Postgres + RLS, Supabase Edge Functions (Deno, `jsr:@supabase/supabase-js@2`), Claude Messages API.

## Global Constraints

- Claude modeli: `claude-haiku-4-5` (verbatim).
- Anthropic API anahtarı yalnız Edge Function secret'ı `ANTHROPIC_API_KEY` — asla client'ta, asla repoda.
- Edge Function yazma işlemleri **caller client** (RLS uygulanan, `Authorization` başlıklı) ile yapılır; service-role kullanılmaz.
- Arayüz dili Türkçe.
- Migration adı 14 haneli `YYYYMMDDNNNNNN` deseni: `20260716000000_support_chat.sql`.
- SQL stili mevcut migration'lardaki gibi küçük harf, `to authenticated`, `using`/`with check`.
- Flutter tarafı `flutter analyze` temiz kalmalı.

---

### Task 1: Veritabanı migration'ı (support_messages + support_tickets + RLS)

**Files:**
- Create: `supabase/migrations/20260716000000_support_chat.sql`

**Interfaces:**
- Produces: `public.support_messages(id, user_id, role, content, created_at)` ve `public.support_tickets(id, user_id, message, status, created_at)` tabloları; her ikisinde RLS açık, kullanıcı yalnız kendi satırlarını `select`/`insert` eder; `support_tickets` için admin `select` politikası.

- [ ] **Step 1: Migration dosyasını yaz**

`supabase/migrations/20260716000000_support_chat.sql`:

```sql
-- AI destek botu: sohbet geçmişi (support_messages) ve destek talepleri (support_tickets)

-- 1) support_messages: kullanıcı başına sohbet geçmişi
create table if not exists public.support_messages (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check (role in ('user', 'assistant')),
  content text not null,
  created_at timestamptz not null default now()
);

create index if not exists idx_support_messages_user_created
  on public.support_messages (user_id, created_at);

alter table public.support_messages enable row level security;

drop policy if exists "support_messages_select_own" on public.support_messages;
create policy "support_messages_select_own"
  on public.support_messages for select
  to authenticated
  using (user_id = auth.uid());

drop policy if exists "support_messages_insert_own" on public.support_messages;
create policy "support_messages_insert_own"
  on public.support_messages for insert
  to authenticated
  with check (user_id = auth.uid());

-- 2) support_tickets: çözülemeyen durumlarda açılan talepler
create table if not exists public.support_tickets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  message text not null,
  status text not null default 'open' check (status in ('open', 'closed')),
  created_at timestamptz not null default now()
);

create index if not exists idx_support_tickets_user_created
  on public.support_tickets (user_id, created_at);

alter table public.support_tickets enable row level security;

-- Kullanıcı kendi taleplerini görür; admin (profiles.user_type='admin') tümünü görür
drop policy if exists "support_tickets_select_own_or_admin" on public.support_tickets;
create policy "support_tickets_select_own_or_admin"
  on public.support_tickets for select
  to authenticated
  using (
    user_id = auth.uid()
    or exists (
      select 1 from public.profiles p
      where p.id = auth.uid() and p.user_type = 'admin'
    )
  );

drop policy if exists "support_tickets_insert_own" on public.support_tickets;
create policy "support_tickets_insert_own"
  on public.support_tickets for insert
  to authenticated
  with check (user_id = auth.uid());
```

- [ ] **Step 2: SQL sözdizimini doğrula**

Yerel Supabase varsa uygula, yoksa en azından sözdizimini gözden geçir:

Run: `supabase db reset` (yerel stack açıksa) **veya** `supabase db push` (bağlı projeye).
Expected: hata yok; `support_messages` ve `support_tickets` tabloları oluşur. (Yerel stack yoksa bu adımı uygulama sırasında yaparsın; SQL'i satır satır kontrol et.)

- [ ] **Step 3: Commit**

```bash
git add supabase/migrations/20260716000000_support_chat.sql
git commit -m "feat: add support_messages and support_tickets tables with RLS"
```

---

### Task 2: Edge Function `support-chat`

**Files:**
- Create: `supabase/functions/support-chat/index.ts`
- Create: `supabase/functions/support-chat/README.md`
- Modify: `supabase/config.toml` (yeni `[functions.support-chat]` bölümü)

**Interfaces:**
- Consumes: `public.support_messages` tablosu (Task 1).
- Produces: `POST /functions/v1/support-chat` — body `{ "message": string }`, `Authorization: Bearer <jwt>` zorunlu. Başarılı yanıt `{ "reply": string }` (200). Hatalar `{ "error": string }` uygun status ile.

- [ ] **Step 1: Edge Function'ı yaz**

`supabase/functions/support-chat/index.ts` (mevcut `admin-users/index.ts` desenini izler):

```ts
import { createClient } from 'jsr:@supabase/supabase-js@2'

const corsHeaders: Record<string, string> = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
}

const MODEL = 'claude-haiku-4-5'
const HISTORY_LIMIT = 20
const MAX_MESSAGE_LEN = 4000

const SYSTEM_PROMPT = `Sen "car_data_app" adlı araç bakım mobil uygulamasının Türkçe destek asistanısın.

Uygulama özellikleri:
- Garaj: kullanıcılar araçlarını ekler ve görüntüler.
- Bakım ve kilometre bazlı hatırlatmalar.
- Evrak/belge takibi.
- "En Yakın Tamirci": kullanıcının konumuna göre servisleri listeler.

İki görevin var:
1) Uygulama kullanım yardımı: özelliklerin nasıl kullanılacağını açıkla.
2) Araç arıza triyajı: kullanıcının anlattığı belirtileri dinle, gerekli detayları sor (örn. araç marka/model/yıl, ne zaman oluyor), olası nedenleri YALNIZCA bilgilendirme amaçlı açıkla, güvenlik/aciliyet uyarısı ver.

Kurallar:
- Kesin teşhis veya onarım garantisi verme; teşhisin bir uzman tarafından doğrulanması gerektiğini belirt.
- Bir arızada tamirciye gitmesi gerekiyorsa, sohbet ekranındaki "En Yakın Tamirci" butonunu kullanabileceğini söyle.
- Sorunu çözemezsen veya kullanıcı bir yetkiliyle görüşmek isterse, sohbet ekranındaki "Destek Talebi Aç" butonunu kullanabileceğini söyle.
- Kısa, net ve nazik ol. Türkçe yanıt ver.`

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }
  if (req.method !== 'POST') {
    return json({ error: 'Method not allowed' }, 405)
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL')
  const anonKey = Deno.env.get('SUPABASE_ANON_KEY')
  const anthropicKey = Deno.env.get('ANTHROPIC_API_KEY')
  if (!supabaseUrl || !anonKey || !anthropicKey) {
    return json({ error: 'Server misconfigured' }, 500)
  }

  const authHeader = req.headers.get('Authorization')
  if (!authHeader) {
    return json({ error: 'Missing Authorization' }, 401)
  }

  const caller = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authHeader } },
  })
  const {
    data: { user },
    error: userError,
  } = await caller.auth.getUser()
  if (userError || !user) {
    return json({ error: 'Unauthorized' }, 401)
  }

  let body: Record<string, unknown>
  try {
    body = await req.json()
  } catch {
    return json({ error: 'Invalid JSON' }, 400)
  }

  const message = String(body.message ?? '').trim()
  if (!message) {
    return json({ error: 'Mesaj boş olamaz' }, 400)
  }
  if (message.length > MAX_MESSAGE_LEN) {
    return json({ error: 'Mesaj çok uzun' }, 400)
  }

  // Geçmişi yükle (caller client, RLS => yalnız kendi satırları)
  const { data: history, error: historyError } = await caller
    .from('support_messages')
    .select('role, content')
    .eq('user_id', user.id)
    .order('created_at', { ascending: true })
    .limit(HISTORY_LIMIT)
  if (historyError) {
    return json({ error: 'Geçmiş yüklenemedi' }, 500)
  }

  const claudeMessages = [
    ...(history ?? []).map((m) => ({
      role: m.role as 'user' | 'assistant',
      content: m.content as string,
    })),
    { role: 'user' as const, content: message },
  ]

  // Claude çağrısı
  let reply: string
  try {
    const resp = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        'x-api-key': anthropicKey,
        'anthropic-version': '2023-06-01',
      },
      body: JSON.stringify({
        model: MODEL,
        max_tokens: 1024,
        system: SYSTEM_PROMPT,
        messages: claudeMessages,
      }),
    })
    if (!resp.ok) {
      return json({ error: 'AI servisine ulaşılamadı' }, 502)
    }
    const data = await resp.json()
    reply = (data?.content?.[0]?.text ?? '').trim()
    if (!reply) {
      return json({ error: 'AI boş yanıt döndü' }, 502)
    }
  } catch {
    return json({ error: 'AI servisine ulaşılamadı' }, 502)
  }

  // Kullanıcı mesajı + asistan cevabını kaydet (caller client, RLS)
  const { error: insertError } = await caller.from('support_messages').insert([
    { user_id: user.id, role: 'user', content: message },
    { user_id: user.id, role: 'assistant', content: reply },
  ])
  if (insertError) {
    // Mesaj kaydedilemese de cevabı döndür; kayıt en iyi çabadır.
    console.error('support_messages insert failed:', insertError.message)
  }

  return json({ reply })
})
```

- [ ] **Step 2: `config.toml`'a fonksiyon kaydı ekle**

`supabase/config.toml` içinde mevcut `[functions.admin-users]` bloğunun hemen ardına ekle:

```toml
[functions.support-chat]
verify_jwt = true
```

- [ ] **Step 3: README yaz**

`supabase/functions/support-chat/README.md`:

````markdown
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
````

- [ ] **Step 4: TypeScript sözdizimini doğrula**

Run: `deno check supabase/functions/support-chat/index.ts`
Expected: hata yok. (Deno yüklü değilse, deploy anında `supabase functions deploy support-chat` bu kontrolü yapar; en azından dosyayı gözden geçir.)

- [ ] **Step 5: Commit**

```bash
git add supabase/functions/support-chat/ supabase/config.toml
git commit -m "feat: add support-chat edge function calling Claude"
```

---

### Task 3: Flutter modeli + servis

**Files:**
- Create: `lib/services/support_chat_service.dart`

**Interfaces:**
- Consumes: `support-chat` Edge Function (Task 2), `support_messages` + `support_tickets` tabloları (Task 1).
- Produces:
  - `class SupportMessage { final String role; final String content; final DateTime createdAt; ... }`
  - `class SupportChatService`:
    - `Future<List<SupportMessage>> loadHistory()`
    - `Future<String> sendMessage(String message)` — Edge Function'ı çağırır, `reply` döner.
    - `Future<void> openTicket(String message)` — `support_tickets`'a satır ekler.
  - Test edilebilirlik için `SupportChatScreen` bu servisi enjekte alacak (Task 4).

- [ ] **Step 1: Servisi ve modeli yaz**

`lib/services/support_chat_service.dart`:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

/// Tek bir sohbet mesajı (kullanıcı ya da asistan).
class SupportMessage {
  const SupportMessage({
    required this.role,
    required this.content,
    required this.createdAt,
  });

  final String role; // 'user' | 'assistant'
  final String content;
  final DateTime createdAt;

  bool get isUser => role == 'user';

  factory SupportMessage.fromMap(Map<String, dynamic> map) {
    return SupportMessage(
      role: (map['role'] as String?) ?? 'assistant',
      content: (map['content'] as String?) ?? '',
      createdAt:
          DateTime.tryParse((map['created_at'] as String?) ?? '') ??
          DateTime.now(),
    );
  }
}

/// AI destek botu için Supabase köprüsü: geçmiş yükleme, mesaj gönderme,
/// destek talebi açma.
class SupportChatService {
  SupportChatService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String get _uid {
    final String? id = _client.auth.currentUser?.id;
    if (id == null) {
      throw StateError('Oturum bulunamadı');
    }
    return id;
  }

  /// Kullanıcının sohbet geçmişini eskiden yeniye sıralı getirir.
  Future<List<SupportMessage>> loadHistory() async {
    final List<dynamic> rows = await _client
        .from('support_messages')
        .select('role, content, created_at')
        .eq('user_id', _uid)
        .order('created_at', ascending: true);
    return rows
        .map((dynamic r) =>
            SupportMessage.fromMap(Map<String, dynamic>.from(r as Map)))
        .toList();
  }

  /// Mesajı Edge Function'a yollar ve asistan cevabını döndürür.
  /// Geçmiş kaydı sunucu tarafında yapılır.
  Future<String> sendMessage(String message) async {
    final FunctionResponse res = await _client.functions.invoke(
      'support-chat',
      body: <String, dynamic>{'message': message},
    );
    final dynamic data = res.data;
    if (data is Map && data['reply'] is String) {
      return data['reply'] as String;
    }
    if (data is Map && data['error'] is String) {
      throw Exception(data['error'] as String);
    }
    throw Exception('Beklenmeyen yanıt');
  }

  /// Çözülemeyen durumlar için destek talebi açar.
  Future<void> openTicket(String message) async {
    await _client.from('support_tickets').insert(<String, dynamic>{
      'user_id': _uid,
      'message': message,
      'status': 'open',
    });
  }
}
```

- [ ] **Step 2: Analiz et**

Run: `flutter analyze lib/services/support_chat_service.dart`
Expected: "No issues found!"

- [ ] **Step 3: Commit**

```bash
git add lib/services/support_chat_service.dart
git commit -m "feat: add SupportChatService for AI support bot"
```

---

### Task 4: Flutter sohbet ekranı

**Files:**
- Create: `lib/screens/support_chat_screen.dart`
- Create: `test/support_chat_screen_test.dart`

**Interfaces:**
- Consumes: `SupportChatService`, `SupportMessage` (Task 3); `NearestMechanicScreen` (mevcut).
- Produces: `class SupportChatScreen extends StatefulWidget` — opsiyonel `SupportChatService? service` parametresiyle (test için enjekte edilebilir). Const constructor.

- [ ] **Step 1: Ekranı yaz**

`lib/screens/support_chat_screen.dart`:

```dart
import 'package:flutter/material.dart';

import '../services/support_chat_service.dart';
import 'nearest_mechanic_screen.dart';

/// AI destek botu sohbet ekranı: uygulama yardımı + araç arıza triyajı.
class SupportChatScreen extends StatefulWidget {
  const SupportChatScreen({super.key, this.service});

  /// Test için enjekte edilebilir; null ise varsayılan servis kullanılır.
  final SupportChatService? service;

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  late final SupportChatService _service =
      widget.service ?? SupportChatService();
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final List<SupportMessage> _messages = <SupportMessage>[];
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    try {
      final List<SupportMessage> history = await _service.loadHistory();
      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(history);
        _loading = false;
      });
      _scrollToBottom();
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  Future<void> _send() async {
    final String text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    _input.clear();
    setState(() {
      _messages.add(SupportMessage(
        role: 'user',
        content: text,
        createdAt: DateTime.now(),
      ));
      _sending = true;
    });
    _scrollToBottom();
    try {
      final String reply = await _service.sendMessage(text);
      if (!mounted) return;
      setState(() {
        _messages.add(SupportMessage(
          role: 'assistant',
          content: reply,
          createdAt: DateTime.now(),
        ));
        _sending = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mesaj gönderilemedi: $e')),
      );
    }
  }

  Future<void> _openTicket() async {
    final String last = _messages
        .where((SupportMessage m) => m.isUser)
        .map((SupportMessage m) => m.content)
        .fold<String>('', (String _, String c) => c);
    if (last.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Önce sorununu yazmalısın.')),
      );
      return;
    }
    try {
      await _service.openTicket(last);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Destek talebin oluşturuldu.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Talep oluşturulamadı: $e')),
      );
    }
  }

  void _openNearestMechanic() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const NearestMechanicScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Destek Asistanı')),
      body: Column(
        children: <Widget>[
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (BuildContext context, int i) {
                      final SupportMessage m = _messages[i];
                      return Align(
                        alignment: m.isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          constraints: BoxConstraints(
                            maxWidth:
                                MediaQuery.of(context).size.width * 0.78,
                          ),
                          decoration: BoxDecoration(
                            color: m.isUser
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            m.content,
                            style: TextStyle(
                              color: m.isUser
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          // Sabit aksiyon butonları
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _openNearestMechanic,
                    icon: const Icon(Icons.location_on_outlined, size: 18),
                    label: const Text('En Yakın Tamirci'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _openTicket,
                    icon: const Icon(Icons.support_agent_outlined, size: 18),
                    label: const Text('Destek Talebi Aç'),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _input,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Sorunu yaz...',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Widget testini yaz**

`test/support_chat_screen_test.dart`:

```dart
import 'package:car_data_app/screens/support_chat_screen.dart';
import 'package:car_data_app/services/support_chat_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Supabase'e dokunmadan ekranı sürebilmek için sahte servis.
class _FakeService implements SupportChatService {
  final List<String> sent = <String>[];
  final List<String> tickets = <String>[];

  @override
  Future<List<SupportMessage>> loadHistory() async => <SupportMessage>[];

  @override
  Future<String> sendMessage(String message) async {
    sent.add(message);
    return 'Cevap: $message';
  }

  @override
  Future<void> openTicket(String message) async {
    tickets.add(message);
  }
}

void main() {
  testWidgets('mesaj gönderilince kullanıcı ve asistan baloncuğu görünür',
      (WidgetTester tester) async {
    final _FakeService fake = _FakeService();
    await tester.pumpWidget(
      MaterialApp(home: SupportChatScreen(service: fake)),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'fren sesi geliyor');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(fake.sent, <String>['fren sesi geliyor']);
    expect(find.text('fren sesi geliyor'), findsOneWidget);
    expect(find.text('Cevap: fren sesi geliyor'), findsOneWidget);
  });

  testWidgets('Destek Talebi Aç son kullanıcı mesajıyla ticket açar',
      (WidgetTester tester) async {
    final _FakeService fake = _FakeService();
    await tester.pumpWidget(
      MaterialApp(home: SupportChatScreen(service: fake)),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'motor çekmiyor');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Destek Talebi Aç'));
    await tester.pumpAndSettle();

    expect(fake.tickets, <String>['motor çekmiyor']);
    expect(find.text('Destek talebin oluşturuldu.'), findsOneWidget);
  });
}
```

> Not: Test `_FakeService` `SupportChatService`'i `implements` eder. `SupportChatService`'in üç public metodu (`loadHistory`, `sendMessage`, `openTicket`) dışında implement edilmesi gereken üye yoktur; ctor'daki `client` alanı private olduğundan `implements` sorunsuz çalışır.

- [ ] **Step 3: Testi çalıştır**

Run: `flutter test test/support_chat_screen_test.dart`
Expected: İki test de PASS. Geçmezse hata mesajını oku ve düzelt.

- [ ] **Step 4: Analiz et**

Run: `flutter analyze lib/screens/support_chat_screen.dart test/support_chat_screen_test.dart`
Expected: "No issues found!"

- [ ] **Step 5: Commit**

```bash
git add lib/screens/support_chat_screen.dart test/support_chat_screen_test.dart
git commit -m "feat: add SupportChatScreen with widget tests"
```

---

### Task 5: Dashboard giriş noktası

**Files:**
- Modify: `lib/screens/home_screen.dart:41` (import ekle)
- Modify: `lib/screens/home/dashboard_tab.dart` (233. satır civarı: kart ekle; dosya sonuna `_SupportChatCard` widget'ı)

**Interfaces:**
- Consumes: `SupportChatScreen` (Task 4).

- [ ] **Step 1: `home_screen.dart`'a import ekle**

`lib/screens/home_screen.dart` içinde mevcut `import 'nearest_mechanic_screen.dart';` (satır 41) hemen ardına ekle:

```dart
import 'support_chat_screen.dart';
```

- [ ] **Step 2: Dashboard'a kart yerleştir**

`lib/screens/home/dashboard_tab.dart` içinde `_NearestMechanicCard()` kullanan bloğun (satır 230-233) hemen ardına, mevcut `const SizedBox(height: 18)` (satır 235) öncesine ekle:

```dart
              const SizedBox(height: 14),

              // AI Destek Asistanı — sohbet ekranını açan kart-buton
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: _SupportChatCard(),
              ),
```

- [ ] **Step 3: `_SupportChatCard` widget'ını ekle**

`lib/screens/home/dashboard_tab.dart` dosyasının sonuna (`_NearestMechanicCard` stilini izleyen sade sürüm):

```dart
/// Ana ekranda AI destek sohbetini açan kart-buton.
class _SupportChatCard extends StatelessWidget {
  const _SupportChatCard();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const SupportChatScreen(),
            ),
          );
        },
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[Color(0xFF2563EB), Color(0xFF1E3A8A)],
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: const Color(0xFF1E3A8A).withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 18, 18),
            child: Row(
              children: const <Widget>[
                Icon(
                  Icons.support_agent,
                  color: Colors.white,
                  size: 34,
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        'AI Destek Asistanı',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Uygulama yardımı ve araç arıza triyajı',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.white70,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Analiz et**

Run: `flutter analyze lib/screens/home_screen.dart lib/screens/home/dashboard_tab.dart`
Expected: "No issues found!"

- [ ] **Step 5: Commit**

```bash
git add lib/screens/home_screen.dart lib/screens/home/dashboard_tab.dart
git commit -m "feat: add AI support assistant entry card on dashboard"
```

---

### Task 6: Deploy notları (DEPLOY.md)

**Files:**
- Modify: `DEPLOY.md`

- [ ] **Step 1: DEPLOY.md'ye bölüm ekle**

`DEPLOY.md` sonuna ekle:

```markdown
## AI Destek Botu (support-chat)

1. Migration'ı uygula: `supabase db push` (`support_messages`, `support_tickets`).
2. Anthropic anahtarını secret olarak ayarla (yalnız sunucuda):
   `supabase secrets set ANTHROPIC_API_KEY=sk-ant-...`
3. Edge Function'ı dağıt: `supabase functions deploy support-chat`
4. Model: `claude-haiku-4-5`. `SUPABASE_URL`/`SUPABASE_ANON_KEY` otomatik enjekte edilir.
```

- [ ] **Step 2: Commit**

```bash
git add DEPLOY.md
git commit -m "docs: add support-chat deploy notes"
```

---

## Son doğrulama (tüm task'lar bitince)

- [ ] `flutter analyze` — tüm proje temiz.
- [ ] `flutter test` — widget testleri geçer.
- [ ] Elde (yerel/deploy sonrası): Dashboard'da "AI Destek Asistanı" kartına dokun → sohbet ekranı açılır → mesaj gönder → cevap gelir → ekrandan çıkıp geri gel → geçmiş korunur → "Destek Talebi Aç" → `support_tickets`'ta satır oluşur.
- [ ] RLS kontrolü: başka bir kullanıcının mesaj/talep satırları görünmez.

## Self-Review (yazar notu)

- **Spec coverage:** (1) migration'lar → Task 1 ✓; (2) Edge Function support-chat → Task 2 ✓; (3) Flutter sohbet ekranı → Task 4, dashboard giriş → Task 5 ✓; (4) .env/secret notları → Task 2 README + Task 6 DEPLOY.md ✓. Servis katmanı (Task 3) spec'in Flutter bölümünü destekler.
- **Type consistency:** `SupportChatService.loadHistory/sendMessage/openTicket` imzaları Task 3'te tanımlandı, Task 4 ekranı ve testi aynı imzaları kullanır. `SupportMessage(role, content, createdAt)` her yerde tutarlı.
- **Placeholder scan:** Placeholder yok; tüm adımlar tam kod içerir.

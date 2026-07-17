import { createClient } from 'jsr:@supabase/supabase-js@2'

const corsHeaders: Record<string, string> = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
}

const MODEL = 'llama-3.3-70b-versatile'
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
  const groqKey = Deno.env.get('GROQ_API_KEY')
  if (!supabaseUrl || !anonKey || !groqKey) {
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

  // Geçmişi yükle (caller client, RLS => yalnız kendi satırları).
  // seq'e göre en yeni HISTORY_LIMIT mesajı al, sonra kronolojik sıraya çevir.
  const { data: history, error: historyError } = await caller
    .from('support_messages')
    .select('role, content')
    .eq('user_id', user.id)
    .order('seq', { ascending: false })
    .limit(HISTORY_LIMIT)
  if (historyError) {
    return json({ error: 'Geçmiş yüklenemedi' }, 500)
  }

  // Groq OpenAI uyumlu format: system + geçmiş + yeni kullanıcı mesajı.
  // DB rolleri 'user'/'assistant' Groq ile birebir uyumlu.
  const orderedHistory = (history ?? []).slice().reverse()
  const groqMessages = [
    { role: 'system' as const, content: SYSTEM_PROMPT },
    ...orderedHistory.map((m) => ({
      role: m.role as 'user' | 'assistant',
      content: m.content as string,
    })),
    { role: 'user' as const, content: message },
  ]

  // Groq çağrısı (OpenAI uyumlu Chat Completions)
  let reply: string
  try {
    const resp = await fetch('https://api.groq.com/openai/v1/chat/completions', {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        Authorization: `Bearer ${groqKey}`,
      },
      body: JSON.stringify({
        model: MODEL,
        max_tokens: 1024,
        messages: groqMessages,
      }),
    })
    if (!resp.ok) {
      return json({ error: 'AI servisine ulaşılamadı' }, 502)
    }
    const data = await resp.json()
    reply = (data?.choices?.[0]?.message?.content ?? '').trim()
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

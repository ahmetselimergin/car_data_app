import { createClient } from 'jsr:@supabase/supabase-js@2'

const corsHeaders: Record<string, string> = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
}

type UserType = 'admin' | 'normal_user' | 'partner_user'

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

function isUserType(v: unknown): v is UserType {
  return v === 'admin' || v === 'normal_user' || v === 'partner_user'
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
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
  if (!supabaseUrl || !anonKey || !serviceKey) {
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

  const { data: profile, error: profileError } = await caller
    .from('profiles')
    .select('user_type')
    .eq('id', user.id)
    .maybeSingle()
  if (profileError || profile?.user_type !== 'admin') {
    return json({ error: 'Admin yetkisi gerekli' }, 403)
  }

  let body: Record<string, unknown>
  try {
    body = await req.json()
  } catch {
    return json({ error: 'Invalid JSON' }, 400)
  }

  const action = body.action
  const admin = createClient(supabaseUrl, serviceKey)

  if (action === 'create') {
    const email = String(body.email ?? '').trim().toLowerCase()
    const password = String(body.password ?? '')
    const username = String(body.username ?? '')
      .trim()
      .toLowerCase()
    const userType = body.user_type

    if (!email || !email.includes('@')) {
      return json({ error: 'Geçerli e-posta gerekli' }, 400)
    }
    if (password.length < 6) {
      return json({ error: 'Şifre en az 6 karakter olmalı' }, 400)
    }
    if (!/^[a-z0-9_]{3,32}$/.test(username)) {
      return json(
        {
          error:
            'Kullanıcı adı 3–32 karakter; yalnızca a-z, 0-9 ve _ olmalı',
        },
        400,
      )
    }
    if (!isUserType(userType)) {
      return json({ error: 'Geçersiz kullanıcı tipi' }, 400)
    }

    const { data: available } = await admin.rpc('username_available', {
      u: username,
    })
    if (available === false) {
      return json({ error: 'Bu kullanıcı adı alınmış' }, 409)
    }

    const { data: created, error: createError } =
      await admin.auth.admin.createUser({
        email,
        password,
        email_confirm: true,
        user_metadata: { username },
      })
    if (createError || !created.user) {
      return json(
        { error: createError?.message ?? 'Kullanıcı oluşturulamadı' },
        400,
      )
    }

    const { error: updateError } = await admin
      .from('profiles')
      .update({
        username,
        email,
        user_type: userType,
        updated_at: new Date().toISOString(),
      })
      .eq('id', created.user.id)

    if (updateError) {
      await admin.auth.admin.deleteUser(created.user.id)
      return json({ error: updateError.message }, 400)
    }

    return json({
      id: created.user.id,
      email,
      username,
      user_type: userType,
    })
  }

  if (action === 'delete') {
    const id = String(body.id ?? '').trim()
    if (!id) {
      return json({ error: 'id gerekli' }, 400)
    }
    if (id === user.id) {
      return json({ error: 'Kendi hesabını silemezsin' }, 400)
    }

    const { error: deleteError } = await admin.auth.admin.deleteUser(id)
    if (deleteError) {
      return json({ error: deleteError.message }, 400)
    }
    return json({ ok: true })
  }

  return json({ error: 'Unknown action' }, 400)
})

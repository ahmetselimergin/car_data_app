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

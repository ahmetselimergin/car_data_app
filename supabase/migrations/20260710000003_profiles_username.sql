-- Kullanıcı adı ile giriş (e-posta veya username)

create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  username text not null,
  email text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint profiles_username_format check (
    username ~ '^[a-z0-9_]{3,32}$'
  )
);

create unique index if not exists profiles_username_uidx
  on public.profiles (username);

create index if not exists profiles_email_idx on public.profiles (email);

alter table public.profiles enable row level security;

drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own"
  on public.profiles for select
  to authenticated
  using (auth.uid() = id);

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own"
  on public.profiles for update
  to authenticated
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- Giriş: e-posta veya kullanıcı adını e-postaya çevir (anon çağırabilir)
create or replace function public.resolve_login_email(identifier text)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v text := lower(trim(coalesce(identifier, '')));
  found_email text;
begin
  if v = '' then
    return null;
  end if;
  if position('@' in v) > 0 then
    return v;
  end if;
  select p.email into found_email
  from public.profiles p
  where p.username = v
  limit 1;
  return found_email;
end;
$$;

revoke all on function public.resolve_login_email(text) from public;
grant execute on function public.resolve_login_email(text) to anon, authenticated;

create or replace function public.username_available(u text)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select not exists (
    select 1
    from public.profiles p
    where p.username = lower(trim(u))
  );
$$;

revoke all on function public.username_available(text) from public;
grant execute on function public.username_available(text) to anon, authenticated;

-- Kayıt sonrası profil (metadata.username zorunlu)
create or replace function public.handle_new_user_profile()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  uname text := lower(trim(coalesce(new.raw_user_meta_data ->> 'username', '')));
begin
  if uname = '' then
    -- Kullanıcı adı yoksa e-posta local-part'tan üret (çakışmada id kısalt)
    uname := lower(split_part(coalesce(new.email, ''), '@', 1));
    uname := regexp_replace(uname, '[^a-z0-9_]', '_', 'g');
    if length(uname) < 3 then
      uname := 'user_' || substr(replace(new.id::text, '-', ''), 1, 8);
    end if;
    if exists (select 1 from public.profiles where username = uname) then
      uname := uname || '_' || substr(replace(new.id::text, '-', ''), 1, 4);
    end if;
  end if;

  insert into public.profiles (id, username, email)
  values (new.id, uname, lower(coalesce(new.email, '')))
  on conflict (id) do update
    set email = excluded.email,
        updated_at = now();

  return new;
end;
$$;

drop trigger if exists on_auth_user_created_profile on auth.users;
create trigger on_auth_user_created_profile
  after insert on auth.users
  for each row execute function public.handle_new_user_profile();

-- Mevcut kullanıcılar için profil (e-posta local-part → username)
insert into public.profiles (id, username, email)
select
  u.id,
  case
    when lower(split_part(u.email, '@', 1)) ~ '^[a-z0-9_]{3,32}$'
      then lower(split_part(u.email, '@', 1))
    else 'user_' || substr(replace(u.id::text, '-', ''), 1, 8)
  end,
  lower(u.email)
from auth.users u
where u.email is not null
on conflict (id) do nothing;

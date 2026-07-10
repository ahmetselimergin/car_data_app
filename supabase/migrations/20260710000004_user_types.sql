-- Kullanıcı tipleri: admin | normal_user | partner_user

do $$ begin
  create type public.user_type as enum ('admin', 'normal_user', 'partner_user');
exception
  when duplicate_object then null;
end $$;

alter table public.profiles
  add column if not exists user_type public.user_type not null default 'normal_user';

create index if not exists profiles_user_type_idx on public.profiles (user_type);

-- Mevcut satırlarda default zaten normal_user; tip yoksa doldur
update public.profiles
set user_type = 'normal_user'
where user_type is null;

-- Güvenli yardımcılar
create or replace function public.current_user_type()
returns public.user_type
language sql
stable
security definer
set search_path = public
as $$
  select p.user_type
  from public.profiles p
  where p.id = auth.uid();
$$;

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.user_type = 'admin'
  );
$$;

create or replace function public.is_partner()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.user_type = 'partner_user'
  );
$$;

create or replace function public.is_staff()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles p
    where p.id = auth.uid()
      and p.user_type in ('admin', 'partner_user')
  );
$$;

revoke all on function public.current_user_type() from public;
revoke all on function public.is_admin() from public;
revoke all on function public.is_partner() from public;
revoke all on function public.is_staff() from public;
grant execute on function public.current_user_type() to authenticated;
grant execute on function public.is_admin() to authenticated;
grant execute on function public.is_partner() to authenticated;
grant execute on function public.is_staff() to authenticated;

-- Kayıt trigger: her zaman normal_user (metadata ile admin olunamaz)
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
    uname := lower(split_part(coalesce(new.email, ''), '@', 1));
    uname := regexp_replace(uname, '[^a-z0-9_]', '_', 'g');
    if length(uname) < 3 then
      uname := 'user_' || substr(replace(new.id::text, '-', ''), 1, 8);
    end if;
    if exists (select 1 from public.profiles where username = uname) then
      uname := uname || '_' || substr(replace(new.id::text, '-', ''), 1, 4);
    end if;
  end if;

  insert into public.profiles (id, username, email, user_type)
  values (new.id, uname, lower(coalesce(new.email, '')), 'normal_user')
  on conflict (id) do update
    set email = excluded.email,
        updated_at = now();
  -- user_type conflict'te güncellenmez (admin düşmesin)

  return new;
end;
$$;

-- Kullanıcı kendi tipini değiştiremesin
drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own"
  on public.profiles for update
  to authenticated
  using (auth.uid() = id)
  with check (
    auth.uid() = id
    and user_type = (select p.user_type from public.profiles p where p.id = auth.uid())
  );

-- Admin tüm profilleri okuyabilir (kullanıcı yönetimi için)
drop policy if exists "profiles_select_admin" on public.profiles;
create policy "profiles_select_admin"
  on public.profiles for select
  to authenticated
  using (public.is_admin() or auth.uid() = id);

-- Admin tip atayabilir
drop policy if exists "profiles_update_admin" on public.profiles;
create policy "profiles_update_admin"
  on public.profiles for update
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- Katalog RLS: yalnızca admin tam CRUD
drop policy if exists "cardex_brands_auth" on public.brands;
drop policy if exists "cardex_models_auth" on public.models;
drop policy if exists "cardex_cars_auth" on public.cars;
drop policy if exists "cardex_workshops_auth" on public.workshops;
drop policy if exists "cardex_insurance_auth" on public.insurance_companies;

create policy "cardex_brands_admin"
  on public.brands for all
  to authenticated
  using (public.is_admin()) with check (public.is_admin());

create policy "cardex_models_admin"
  on public.models for all
  to authenticated
  using (public.is_admin()) with check (public.is_admin());

create policy "cardex_cars_admin"
  on public.cars for all
  to authenticated
  using (public.is_admin()) with check (public.is_admin());

-- Partner: tamirhane / sigorta okuma+yazma; admin her şey
create policy "cardex_workshops_staff"
  on public.workshops for all
  to authenticated
  using (public.is_staff()) with check (public.is_staff());

create policy "cardex_insurance_staff"
  on public.insurance_companies for all
  to authenticated
  using (public.is_staff()) with check (public.is_staff());

-- Partner marka/model sadece okusun
create policy "cardex_brands_partner_read"
  on public.brands for select
  to authenticated
  using (public.is_partner());

create policy "cardex_models_partner_read"
  on public.models for select
  to authenticated
  using (public.is_partner());

-- Storage yazma: admin
drop policy if exists "cardex_brand_logos_insert" on storage.objects;
drop policy if exists "cardex_brand_logos_update" on storage.objects;
drop policy if exists "cardex_brand_logos_delete" on storage.objects;

create policy "cardex_brand_logos_insert"
  on storage.objects for insert
  to authenticated
  with check (bucket_id = 'brand-logos' and public.is_admin());

create policy "cardex_brand_logos_update"
  on storage.objects for update
  to authenticated
  using (bucket_id = 'brand-logos' and public.is_admin());

create policy "cardex_brand_logos_delete"
  on storage.objects for delete
  to authenticated
  using (bucket_id = 'brand-logos' and public.is_admin());

-- İlk admin'i kendi e-postanla ata (aşağıdaki satırı düzenleyip çalıştır):
-- update public.profiles
-- set user_type = 'admin', username = 'admin', updated_at = now()
-- where lower(email) = 'SENIN_MAILIN@ornek.com';

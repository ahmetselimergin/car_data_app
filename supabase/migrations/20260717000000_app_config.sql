-- Uygulama sürüm kapısı: zorunlu/önerilen güncelleme kontrolü.
-- Platform başına bir satır (ios / android). Uygulama açılışta okur ve
-- mevcut build numarasını min_build/latest_build ile karşılaştırır.

create table if not exists public.app_config (
  platform text primary key check (platform in ('ios', 'android')),
  min_build int not null default 1,       -- bunun altı: zorunlu güncelleme
  latest_build int not null default 1,    -- bunun altı (>=min): önerilen güncelleme
  store_url text not null default '',
  message text,
  updated_at timestamptz not null default now()
);

alter table public.app_config enable row level security;

-- Herkes (giriş öncesi anon dahil) okuyabilir; yazma yok (Dashboard/service role).
drop policy if exists "app_config_public_read" on public.app_config;
create policy "app_config_public_read"
  on public.app_config for select
  to anon, authenticated
  using (true);

-- Başlangıç satırları. store_url'ler mağaza yayınından sonra Dashboard'dan
-- doldurulur; latest_build/min_build her yeni sürümde güncellenir.
insert into public.app_config (platform, min_build, latest_build, store_url, message)
values
  ('ios', 1, 1, '', null),
  ('android', 1, 1, '', null)
on conflict (platform) do nothing;

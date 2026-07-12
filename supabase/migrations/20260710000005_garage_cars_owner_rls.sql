-- Mobile garage: users own their cars; catalog (owner_uid null) stays admin-only.
-- Fix global plaka unique so multiple users can share a plate text.

alter table public.cars
  add column if not exists card_color bigint;

-- Drop legacy global unique on plaka (name varies by how it was created)
alter table public.cars drop constraint if exists cars_plaka_key;
drop index if exists cars_plaka_key;
drop index if exists idx_cars_plaka;

-- Catalog rows (no owner): plaka still unique among themselves
create unique index if not exists cars_catalog_plaka_uidx
  on public.cars (plaka)
  where owner_uid is null;

-- Garage rows: unique per owner
create unique index if not exists cars_owner_plaka_uidx
  on public.cars (owner_uid, plaka)
  where owner_uid is not null;

create index if not exists idx_cars_plaka on public.cars (plaka);

-- Owners can CRUD their own garage cars (admin policy already covers staff)
drop policy if exists "garage_cars_owner_select" on public.cars;
drop policy if exists "garage_cars_owner_insert" on public.cars;
drop policy if exists "garage_cars_owner_update" on public.cars;
drop policy if exists "garage_cars_owner_delete" on public.cars;

create policy "garage_cars_owner_select"
  on public.cars for select
  to authenticated
  using (owner_uid = auth.uid()::text);

create policy "garage_cars_owner_insert"
  on public.cars for insert
  to authenticated
  with check (owner_uid = auth.uid()::text);

create policy "garage_cars_owner_update"
  on public.cars for update
  to authenticated
  using (owner_uid = auth.uid()::text)
  with check (owner_uid = auth.uid()::text);

create policy "garage_cars_owner_delete"
  on public.cars for delete
  to authenticated
  using (owner_uid = auth.uid()::text);

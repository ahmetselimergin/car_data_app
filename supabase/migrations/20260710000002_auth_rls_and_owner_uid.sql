-- Rename cars.firebase_uid → owner_uid (Supabase Auth user id)
alter table public.cars rename column firebase_uid to owner_uid;

drop index if exists idx_cars_firebase;
create index if not exists idx_cars_owner on public.cars (owner_uid);

-- Require authenticated session for catalog CRUD (admin_desktop Supabase Auth)
drop policy if exists "cardex_brands_all" on public.brands;
drop policy if exists "cardex_models_all" on public.models;
drop policy if exists "cardex_cars_all" on public.cars;
drop policy if exists "cardex_workshops_all" on public.workshops;
drop policy if exists "cardex_insurance_all" on public.insurance_companies;

create policy "cardex_brands_auth"
  on public.brands for all
  to authenticated
  using (true) with check (true);

create policy "cardex_models_auth"
  on public.models for all
  to authenticated
  using (true) with check (true);

create policy "cardex_cars_auth"
  on public.cars for all
  to authenticated
  using (true) with check (true);

create policy "cardex_workshops_auth"
  on public.workshops for all
  to authenticated
  using (true) with check (true);

create policy "cardex_insurance_auth"
  on public.insurance_companies for all
  to authenticated
  using (true) with check (true);

-- Storage: authenticated write, public read
drop policy if exists "cardex_brand_logos_insert" on storage.objects;
drop policy if exists "cardex_brand_logos_update" on storage.objects;
drop policy if exists "cardex_brand_logos_delete" on storage.objects;

create policy "cardex_brand_logos_insert"
  on storage.objects for insert
  to authenticated
  with check (bucket_id = 'brand-logos');

create policy "cardex_brand_logos_update"
  on storage.objects for update
  to authenticated
  using (bucket_id = 'brand-logos');

create policy "cardex_brand_logos_delete"
  on storage.objects for delete
  to authenticated
  using (bucket_id = 'brand-logos');

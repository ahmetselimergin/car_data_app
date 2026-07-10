-- Marka logoları için public storage bucket

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'brand-logos',
  'brand-logos',
  true,
  5242880,
  array['image/png', 'image/jpeg', 'image/webp', 'image/svg+xml']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

-- Şimdilik anon key ile yükleme/silme (admin paneli); sonra auth.role() ile sıkılaştır
create policy "cardex_brand_logos_select"
  on storage.objects for select
  using (bucket_id = 'brand-logos');

create policy "cardex_brand_logos_insert"
  on storage.objects for insert
  with check (bucket_id = 'brand-logos');

create policy "cardex_brand_logos_update"
  on storage.objects for update
  using (bucket_id = 'brand-logos');

create policy "cardex_brand_logos_delete"
  on storage.objects for delete
  using (bucket_id = 'brand-logos');

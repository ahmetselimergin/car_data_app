-- Kullanıcı araç fotoğrafları (mobil garaj)

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'car-images',
  'car-images',
  true,
  10485760,
  array['image/png', 'image/jpeg', 'image/webp', 'image/heic']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

-- Yol: {auth.uid()}/car_….ext
drop policy if exists "car_images_select" on storage.objects;
drop policy if exists "car_images_insert" on storage.objects;
drop policy if exists "car_images_update" on storage.objects;
drop policy if exists "car_images_delete" on storage.objects;

create policy "car_images_select"
  on storage.objects for select
  using (bucket_id = 'car-images');

create policy "car_images_insert"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'car-images'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "car_images_update"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'car-images'
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id = 'car-images'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "car_images_delete"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'car-images'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

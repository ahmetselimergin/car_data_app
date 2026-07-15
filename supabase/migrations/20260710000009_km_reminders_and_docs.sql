-- Km-based reminders + maintenance document attachments

-- Reminders: optional date, optional target_km
alter table public.reminders
  alter column bitis_tarihi drop not null;

alter table public.reminders
  add column if not exists target_km integer;

alter table public.reminders
  drop constraint if exists reminders_bitis_or_km_chk;

alter table public.reminders
  add constraint reminders_bitis_or_km_chk
  check (bitis_tarihi is not null or target_km is not null);

create index if not exists idx_reminders_target_km
  on public.reminders (target_km)
  where target_km is not null;

-- Maintenance attachments
alter table public.maintenance
  add column if not exists attachment_url text;

-- Storage bucket for receipts / invoices / PDFs
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'maintenance-docs',
  'maintenance-docs',
  true,
  15728640,
  array[
    'image/png',
    'image/jpeg',
    'image/webp',
    'image/heic',
    'application/pdf'
  ]
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "maintenance_docs_select" on storage.objects;
drop policy if exists "maintenance_docs_insert" on storage.objects;
drop policy if exists "maintenance_docs_update" on storage.objects;
drop policy if exists "maintenance_docs_delete" on storage.objects;

create policy "maintenance_docs_select"
  on storage.objects for select
  using (bucket_id = 'maintenance-docs');

create policy "maintenance_docs_insert"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'maintenance-docs'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "maintenance_docs_update"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'maintenance-docs'
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id = 'maintenance-docs'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "maintenance_docs_delete"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'maintenance-docs'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

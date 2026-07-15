-- User garage reminders + maintenance logs (synced from Flutter mobile).

create table if not exists public.reminders (
  id bigserial primary key,
  car_id integer not null references public.cars (id) on delete cascade,
  owner_uid text not null,
  tur text not null,
  bitis_tarihi date not null,
  hatirlatma_yapildi boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (car_id, tur)
);

create index if not exists idx_reminders_owner on public.reminders (owner_uid);
create index if not exists idx_reminders_car on public.reminders (car_id);
create index if not exists idx_reminders_bitis on public.reminders (bitis_tarihi);

create table if not exists public.maintenance (
  id bigserial primary key,
  car_id integer not null references public.cars (id) on delete cascade,
  owner_uid text not null,
  islem text not null,
  tarih date not null,
  km integer not null default 0,
  maliyet numeric(12, 2) not null default 0,
  servis_adi text,
  notlar text,
  bakim_kalemleri jsonb not null default '[]'::jsonb,
  resmi_servis boolean not null default false,
  garanti_kapsaminda boolean not null default false,
  fatura_alindi boolean not null default false,
  sigorta_karsiladi boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_maintenance_owner on public.maintenance (owner_uid);
create index if not exists idx_maintenance_car on public.maintenance (car_id);
create index if not exists idx_maintenance_tarih on public.maintenance (tarih desc);

drop trigger if exists reminders_updated_at on public.reminders;
create trigger reminders_updated_at
  before update on public.reminders
  for each row execute function public.set_updated_at();

drop trigger if exists maintenance_updated_at on public.maintenance;
create trigger maintenance_updated_at
  before update on public.maintenance
  for each row execute function public.set_updated_at();

alter table public.reminders enable row level security;
alter table public.maintenance enable row level security;

drop policy if exists "garage_reminders_owner_select" on public.reminders;
drop policy if exists "garage_reminders_owner_insert" on public.reminders;
drop policy if exists "garage_reminders_owner_update" on public.reminders;
drop policy if exists "garage_reminders_owner_delete" on public.reminders;

create policy "garage_reminders_owner_select"
  on public.reminders for select
  to authenticated
  using (owner_uid = auth.uid()::text);

create policy "garage_reminders_owner_insert"
  on public.reminders for insert
  to authenticated
  with check (
    owner_uid = auth.uid()::text
    and exists (
      select 1 from public.cars c
      where c.id = car_id and c.owner_uid = auth.uid()::text
    )
  );

create policy "garage_reminders_owner_update"
  on public.reminders for update
  to authenticated
  using (owner_uid = auth.uid()::text)
  with check (owner_uid = auth.uid()::text);

create policy "garage_reminders_owner_delete"
  on public.reminders for delete
  to authenticated
  using (owner_uid = auth.uid()::text);

drop policy if exists "garage_maintenance_owner_select" on public.maintenance;
drop policy if exists "garage_maintenance_owner_insert" on public.maintenance;
drop policy if exists "garage_maintenance_owner_update" on public.maintenance;
drop policy if exists "garage_maintenance_owner_delete" on public.maintenance;

create policy "garage_maintenance_owner_select"
  on public.maintenance for select
  to authenticated
  using (owner_uid = auth.uid()::text);

create policy "garage_maintenance_owner_insert"
  on public.maintenance for insert
  to authenticated
  with check (
    owner_uid = auth.uid()::text
    and exists (
      select 1 from public.cars c
      where c.id = car_id and c.owner_uid = auth.uid()::text
    )
  );

create policy "garage_maintenance_owner_update"
  on public.maintenance for update
  to authenticated
  using (owner_uid = auth.uid()::text)
  with check (owner_uid = auth.uid()::text);

create policy "garage_maintenance_owner_delete"
  on public.maintenance for delete
  to authenticated
  using (owner_uid = auth.uid()::text);

grant select, insert, update, delete on public.reminders to authenticated;
grant select, insert, update, delete on public.maintenance to authenticated;
grant usage, select on sequence public.reminders_id_seq to authenticated;
grant usage, select on sequence public.maintenance_id_seq to authenticated;

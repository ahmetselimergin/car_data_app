-- Cardex admin catalog schema (Supabase Postgres)

create table if not exists public.brands (
  id serial primary key,
  slug text not null unique,
  name text not null,
  logo_url text,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_brands_sort on public.brands (sort_order, name);

create table if not exists public.models (
  id serial primary key,
  brand_id integer not null references public.brands (id) on delete cascade,
  name text not null,
  body_type text,
  year_start integer,
  year_end integer,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (brand_id, name)
);

create index if not exists idx_models_brand on public.models (brand_id, name);

create table if not exists public.cars (
  id serial primary key,
  plaka text not null unique,
  marka text not null,
  model text not null,
  yil integer not null,
  km integer not null default 0,
  transmission text,
  fuel_type text,
  color text,
  image_url text,
  notes text,
  brand_id integer references public.brands (id) on delete set null,
  owner_uid text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_cars_plaka on public.cars (plaka);
create index if not exists idx_cars_brand on public.cars (brand_id);
create index if not exists idx_cars_owner on public.cars (owner_uid);

create table if not exists public.workshops (
  id serial primary key,
  name text not null,
  phone text,
  email text,
  address text,
  notes text,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_workshops_active on public.workshops (active, name);

create table if not exists public.insurance_companies (
  id serial primary key,
  name text not null,
  type text not null default 'both',
  phone text,
  email text,
  website text,
  address text,
  notes text,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_insurance_active on public.insurance_companies (active, name);

-- updated_at trigger
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists brands_updated_at on public.brands;
create trigger brands_updated_at
  before update on public.brands
  for each row execute function public.set_updated_at();

drop trigger if exists models_updated_at on public.models;
create trigger models_updated_at
  before update on public.models
  for each row execute function public.set_updated_at();

drop trigger if exists cars_updated_at on public.cars;
create trigger cars_updated_at
  before update on public.cars
  for each row execute function public.set_updated_at();

drop trigger if exists workshops_updated_at on public.workshops;
create trigger workshops_updated_at
  before update on public.workshops
  for each row execute function public.set_updated_at();

drop trigger if exists insurance_companies_updated_at on public.insurance_companies;
create trigger insurance_companies_updated_at
  before update on public.insurance_companies
  for each row execute function public.set_updated_at();

-- RLS: şimdilik admin paneli (anon key) için açık; Supabase Auth + rol politikaları sonra sıkılaştırılacak
alter table public.brands enable row level security;
alter table public.models enable row level security;
alter table public.cars enable row level security;
alter table public.workshops enable row level security;
alter table public.insurance_companies enable row level security;

create policy "cardex_brands_all" on public.brands for all using (true) with check (true);
create policy "cardex_models_all" on public.models for all using (true) with check (true);
create policy "cardex_cars_all" on public.cars for all using (true) with check (true);
create policy "cardex_workshops_all" on public.workshops for all using (true) with check (true);
create policy "cardex_insurance_all" on public.insurance_companies for all using (true) with check (true);

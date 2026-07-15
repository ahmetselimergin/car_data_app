-- workshops tablosuna "il" (şehir) kolonu.
-- "En Yakın Tamirci" ekranında ile göre filtreleme için. Değer, servis posta
-- kodunun ilk iki hanesinden (plaka kodu) türetilir; scrape_euro_repar.py yazar.
alter table public.workshops
  add column if not exists city text;

-- İl bazlı filtre sorgularını hızlandır (yalnızca dolu şehirler).
create index if not exists idx_workshops_city
  on public.workshops (city)
  where city is not null;

-- workshops tablosuna coğrafi konum (enlem/boylam) kolonları.
-- "En Yakın Tamirci" ekranı, kullanıcı konumuna göre mesafe hesaplayabilsin
-- diye Euro Repar servis noktalarının lat/lng bilgisini saklıyoruz.
alter table public.workshops
  add column if not exists lat double precision,
  add column if not exists lng double precision;

-- Sadece konumu olan aktif servisleri hızlı çekmek için kısmi index.
create index if not exists idx_workshops_geo
  on public.workshops (lat, lng)
  where lat is not null and lng is not null;

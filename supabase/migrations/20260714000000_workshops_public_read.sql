-- "En Yakın Tamirci" (mobil): normal (staff olmayan) kullanıcılar aktif
-- servisleri yalnızca OKUYABİLSİN. Yazma hâlâ staff politikasına bağlı.
-- Aynı komut için birden fazla policy OR'lanır: staff hepsini, diğerleri
-- yalnızca active=true satırları görür.
drop policy if exists "cardex_workshops_public_read" on public.workshops;
create policy "cardex_workshops_public_read"
  on public.workshops for select
  to authenticated
  using (active = true);

-- Test için örnek servisler (adresler geocode edilebilsin diye gerçekçi).
-- Gerçek veri (Euro Repar) eklenince bunları silebilirsin.
insert into public.workshops (name, phone, address, active)
values
  ('Usta Oto Servis', '+902121234567',
   'Bağdat Caddesi No:120, Kadıköy, İstanbul', true),
  ('Merkez Oto Tamir', '+902123334455',
   'Barbaros Bulvarı No:45, Beşiktaş, İstanbul', true),
  ('Güven Garaj', '+902129998877',
   'İstiklal Caddesi No:200, Beyoğlu, İstanbul', true)
on conflict do nothing;

-- ARGB renk değerleri (örn. 4293212469) Postgres integer max'ını aşar.
alter table public.cars
  alter column card_color type bigint using card_color::bigint;

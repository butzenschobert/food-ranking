-- Proteinregal — Supabase-Schema
-- Im Supabase SQL Editor ausführen.

create extension if not exists pgcrypto;

create table if not exists people (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  created_at timestamptz not null default now()
);

create table if not exists products (
  id uuid primary key,
  ean text not null unique,
  name text not null default '',
  brand text not null default '',
  quantity text not null default '',
  net_weight_g numeric,
  kcal_100g numeric,
  protein_100g numeric,
  fat_100g numeric,
  carbs_100g numeric,
  nova_group smallint check (nova_group between 1 and 4),
  eco_grade char(1) check (eco_grade in ('a','b','c','d','e')),
  co2_g_100g numeric,
  categories text not null default '',
  image_url text,
  price_eur numeric,
  versatility smallint check (versatility between 1 and 5),
  notes text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists ratings (
  product_id uuid not null references products(id) on delete cascade,
  person_id uuid not null references people(id) on delete cascade,
  taste smallint not null check (taste between 1 and 5),
  updated_at timestamptz not null default now(),
  primary key (product_id, person_id)
);

-- Abgeleitete Werte als View (optional, für Abfragen außerhalb der App)
create or replace view products_ranked as
select p.*,
  case when p.kcal_100g > 0 then p.protein_100g / p.kcal_100g * 100 end as protein_per_100kcal,
  case when p.price_eur > 0 and p.net_weight_g > 0 then p.protein_100g * p.net_weight_g / 100 / p.price_eur end as protein_g_per_eur,
  case when p.price_eur > 0 and p.net_weight_g > 0 then p.price_eur / (p.net_weight_g / 1000) end as price_per_kg
from products p;

-- Schreibschutz: Lesen offen, Schreiben nur mit App-Passwort.
-- Die App schickt das Passwort als Header x-app-key; Policies vergleichen gegen app_secrets.
-- app_secrets hat RLS ohne Policies → für anon unlesbar. Nur app_key_ok() (security definer) liest sie.
create table if not exists app_secrets (key text primary key, value text not null);
alter table app_secrets enable row level security;
revoke all on app_secrets from anon, authenticated;

create or replace function app_key_ok() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from app_secrets
    where key = 'write_password'
      and value = coalesce(current_setting('request.headers', true)::json ->> 'x-app-key', '')
  );
$$;
revoke all on function app_key_ok() from public;
grant execute on function app_key_ok() to anon, authenticated;

-- >>> HIER DEIN PASSWORT EINTRAGEN (vor dem Ausführen) <<<
insert into app_secrets (key, value) values ('write_password', 'BITTE-AENDERN')
on conflict (key) do update set value = excluded.value;

alter table people   enable row level security;
alter table products enable row level security;
alter table ratings  enable row level security;

create policy "read people"   on people   for select to anon using (true);
create policy "read products" on products for select to anon using (true);
create policy "read ratings"  on ratings  for select to anon using (true);

create policy "write people"   on people   for all to anon using (app_key_ok()) with check (app_key_ok());
create policy "write products" on products for all to anon using (app_key_ok()) with check (app_key_ok());
create policy "write ratings"  on ratings  for all to anon using (app_key_ok()) with check (app_key_ok());

insert into people (name) values ('Nikolas') on conflict do nothing;

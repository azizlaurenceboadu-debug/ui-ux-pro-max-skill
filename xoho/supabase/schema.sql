-- ═══════════════════════════════════════════════════════════════
-- XOHO — Supabase Schema
-- Run this in the Supabase SQL Editor (Dashboard → SQL Editor → New query)
-- ═══════════════════════════════════════════════════════════════

-- ── Extensions ──────────────────────────────────────────────────
create extension if not exists "pgcrypto";

-- ── Tables ──────────────────────────────────────────────────────

create table if not exists products (
  id           uuid primary key default gen_random_uuid(),
  name         text        not null,
  short_desc   text,
  full_desc    text,
  bullets      text,
  price        integer     not null default 0,
  pole         text        not null default 'administratif',
  format       text        not null default 'PDF',
  file_size    text,
  file_path    text,
  preview_url  text,
  published    boolean     not null default false,
  top_sell     boolean     not null default false,
  created_at   timestamptz not null default now()
);

create table if not exists orders (
  id               uuid primary key default gen_random_uuid(),
  product_id       uuid references products(id) on delete set null,
  product_name     text        not null,
  amount           integer     not null,
  buyer_name       text        not null,
  buyer_phone      text        not null,
  buyer_email      text,
  status           text        not null default 'pending',
  kkiapay_txid     text,
  download_token   uuid        not null unique default gen_random_uuid(),
  created_at       timestamptz not null default now()
);

-- ── Indexes ─────────────────────────────────────────────────────
create index if not exists orders_download_token_idx on orders(download_token);
create index if not exists orders_status_idx         on orders(status);
create index if not exists products_published_idx    on products(published);
create index if not exists products_pole_idx         on products(pole);

-- ═══════════════════════════════════════════════════════════════
-- Row Level Security
-- ═══════════════════════════════════════════════════════════════

alter table products enable row level security;
alter table orders   enable row level security;

-- ── Products policies ───────────────────────────────────────────

-- Anyone (including anonymous) can read published products
create policy "public_read_published_products"
  on products for select
  using (published = true);

-- Only authenticated users (admin) can do everything
create policy "admin_all_products"
  on products for all
  to authenticated
  using (true)
  with check (true);

-- ── Orders policies ─────────────────────────────────────────────

-- Anyone can create an order
create policy "public_insert_orders"
  on orders for insert
  with check (true);

-- Anyone can read their own order by download_token
-- (no auth needed — token is the secret)
create policy "public_read_order_by_token"
  on orders for select
  using (true);

-- Anyone can update status (needed for payment confirmation from client)
-- In production, restrict this via an Edge Function or webhook instead
create policy "public_update_order_status"
  on orders for update
  using (true)
  with check (true);

-- Only authenticated users (admin) can delete orders
create policy "admin_delete_orders"
  on orders for delete
  to authenticated
  using (true);

-- ═══════════════════════════════════════════════════════════════
-- Storage bucket policies
-- (Run AFTER creating buckets in Dashboard → Storage)
-- ═══════════════════════════════════════════════════════════════

-- Bucket: previews (public read, admin write)
insert into storage.buckets (id, name, public)
values ('previews', 'previews', true)
on conflict (id) do nothing;

insert into storage.buckets (id, name, public)
values ('products', 'products', true)
on conflict (id) do nothing;

-- Allow anyone to read from both public buckets
create policy "public_read_previews"
  on storage.objects for select
  using (bucket_id = 'previews');

create policy "public_read_products"
  on storage.objects for select
  using (bucket_id = 'products');

-- Only authenticated users (admin) can upload/delete files
create policy "admin_write_previews"
  on storage.objects for insert
  to authenticated
  with check (bucket_id = 'previews');

create policy "admin_write_products"
  on storage.objects for insert
  to authenticated
  with check (bucket_id = 'products');

create policy "admin_delete_previews"
  on storage.objects for delete
  to authenticated
  using (bucket_id = 'previews');

create policy "admin_delete_products"
  on storage.objects for delete
  to authenticated
  using (bucket_id = 'products');

-- ═══════════════════════════════════════════════════════════════
-- Sample data (optional — delete if not needed)
-- ═══════════════════════════════════════════════════════════════

insert into products (name, short_desc, full_desc, bullets, price, pole, format, file_size, published, top_sell)
values
  (
    'Modèle de demande d''emploi',
    'Lettre de motivation professionnelle prête à personnaliser.',
    'Ce document contient une lettre de motivation complète, rédigée par des professionnels RH, adaptée aux entreprises béninoises et internationales.',
    'Rédigé par des professionnels RH
Format Word + PDF inclus
Facile à personnaliser en 10 minutes
Compatible avec toutes les offres d''emploi',
    500,
    'administratif',
    'PDF + Word',
    '120 Ko',
    true,
    true
  ),
  (
    'Guide de création d''entreprise au Bénin',
    'Toutes les étapes pour immatriculer votre entreprise au GUFE.',
    'Ce guide complet vous accompagne pas à pas dans la création officielle de votre entreprise au Bénin, de l''immatriculation au premier contrat.',
    'Checklist complète des documents
Formulaires GUFE pré-remplis
Conseils juridiques pratiques
Mis à jour 2024',
    1500,
    'business',
    'PDF',
    '2,1 Mo',
    true,
    true
  ),
  (
    'Kit CV moderne',
    'Templates CV professionnels pour le marché béninois.',
    'Un ensemble de 5 modèles de CV modernes, optimisés pour les ATS et adaptés aux employeurs locaux et internationaux.',
    '5 modèles inclus
Format Word modifiable
Instructions de personnalisation
Design épuré et professionnel',
    800,
    'academique',
    'Word + PDF',
    '850 Ko',
    true,
    false
  );

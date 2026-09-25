-- Supabase schema for the connected store
-- Project: jwltoaotyiktspqgzsjv
-- Run this entire file in Supabase SQL Editor.

create extension if not exists pgcrypto;

create table if not exists public.admins (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create or replace function public.is_admin()
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1 from public.admins a where a.user_id = auth.uid()
  );
$$;

revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to anon, authenticated;

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  price numeric(12,2) not null default 0 check (price >= 0),
  old_price numeric(12,2) check (old_price is null or old_price >= 0),
  description text not null default '',
  emoji text not null default '🛍️',
  image_url text not null default '',
  colors jsonb not null default '[]'::jsonb,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.store_settings (
  id integer primary key default 1 check (id = 1),
  store_name text not null default 'متجري',
  welcome_message text not null default 'أهلاً بك في متجرنا',
  shipping numeric(12,2) not null default 50 check (shipping >= 0),
  order_email text not null default '',
  whatsapp text not null default '',
  vodafone text not null default '',
  etisalat text not null default '',
  orange text not null default '',
  updated_at timestamptz not null default now()
);

insert into public.store_settings (id) values (1)
on conflict (id) do nothing;

create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  order_number text not null unique,
  customer_name text not null,
  phone text not null,
  whatsapp text not null default '',
  email text not null default '',
  governorate text not null default '',
  city text not null default '',
  area text not null default '',
  street text not null default '',
  landmark text not null default '',
  notes text not null default '',
  items jsonb not null default '[]'::jsonb,
  subtotal numeric(12,2) not null default 0,
  shipping numeric(12,2) not null default 0,
  total numeric(12,2) not null default 0,
  payment_method text not null default '',
  wallet_number text not null default '',
  status text not null default 'pending',
  created_at timestamptz not null default now()
);

create index if not exists products_active_idx on public.products(active);
create index if not exists orders_created_at_idx on public.orders(created_at desc);
create index if not exists orders_status_idx on public.orders(status);

alter table public.admins enable row level security;
alter table public.products enable row level security;
alter table public.store_settings enable row level security;
alter table public.orders enable row level security;

-- Admin table: an admin can see/manage admin rows. No public access.
drop policy if exists "admins_select_admin" on public.admins;
create policy "admins_select_admin"
on public.admins for select to authenticated
using (public.is_admin());

drop policy if exists "admins_insert_admin" on public.admins;
create policy "admins_insert_admin"
on public.admins for insert to authenticated
with check (public.is_admin());

drop policy if exists "admins_delete_admin" on public.admins;
create policy "admins_delete_admin"
on public.admins for delete to authenticated
using (public.is_admin());

-- Products: public can only read active products. Admin has full CRUD.
drop policy if exists "products_public_read" on public.products;
create policy "products_public_read"
on public.products for select to anon, authenticated
using (active = true or public.is_admin());

drop policy if exists "products_admin_insert" on public.products;
create policy "products_admin_insert"
on public.products for insert to authenticated
with check (public.is_admin());

drop policy if exists "products_admin_update" on public.products;
create policy "products_admin_update"
on public.products for update to authenticated
using (public.is_admin()) with check (public.is_admin());

drop policy if exists "products_admin_delete" on public.products;
create policy "products_admin_delete"
on public.products for delete to authenticated
using (public.is_admin());

-- Store settings: public can read settings; only admin can change them.
drop policy if exists "settings_public_read" on public.store_settings;
create policy "settings_public_read"
on public.store_settings for select to anon, authenticated
using (true);

drop policy if exists "settings_admin_insert" on public.store_settings;
create policy "settings_admin_insert"
on public.store_settings for insert to authenticated
with check (public.is_admin());

drop policy if exists "settings_admin_update" on public.store_settings;
create policy "settings_admin_update"
on public.store_settings for update to authenticated
using (public.is_admin()) with check (public.is_admin());

-- Orders: anyone can submit an order; only admin can view/change orders.
drop policy if exists "orders_public_insert" on public.orders;
create policy "orders_public_insert"
on public.orders for insert to anon, authenticated
with check (true);

drop policy if exists "orders_admin_read" on public.orders;
create policy "orders_admin_read"
on public.orders for select to authenticated
using (public.is_admin());

drop policy if exists "orders_admin_update" on public.orders;
create policy "orders_admin_update"
on public.orders for update to authenticated
using (public.is_admin()) with check (public.is_admin());

drop policy if exists "orders_admin_delete" on public.orders;
create policy "orders_admin_delete"
on public.orders for delete to authenticated
using (public.is_admin());

-- Required Data API grants. RLS still controls which rows/actions are allowed.
grant select on public.products to anon, authenticated;
grant insert, update, delete on public.products to authenticated;
grant select on public.store_settings to anon, authenticated;
grant insert, update on public.store_settings to authenticated;
grant insert on public.orders to anon, authenticated;
grant select, update, delete on public.orders to authenticated;
grant select, insert, delete on public.admins to authenticated;

-- Storage bucket for product images.
insert into storage.buckets (id, name, public)
values ('product-images', 'product-images', true)
on conflict (id) do update set public = true;

-- Public can read product images; only admins can upload/change/delete them.
drop policy if exists "product_images_public_read" on storage.objects;
create policy "product_images_public_read"
on storage.objects for select to public
using (bucket_id = 'product-images');

drop policy if exists "product_images_admin_insert" on storage.objects;
create policy "product_images_admin_insert"
on storage.objects for insert to authenticated
with check (bucket_id = 'product-images' and public.is_admin());

drop policy if exists "product_images_admin_update" on storage.objects;
create policy "product_images_admin_update"
on storage.objects for update to authenticated
using (bucket_id = 'product-images' and public.is_admin())
with check (bucket_id = 'product-images' and public.is_admin());

drop policy if exists "product_images_admin_delete" on storage.objects;
create policy "product_images_admin_delete"
on storage.objects for delete to authenticated
using (bucket_id = 'product-images' and public.is_admin());

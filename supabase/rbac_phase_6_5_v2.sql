-- =====================================================================
-- Zipani Admin — Phase 6.5 RBAC  (post-6.1)
-- Run in the Supabase SQL Editor. Review before executing.
--
-- Model:
--   roles: 'super_admin' (everything), 'restaurant_owner' (own data only)
--   Ownership is derived from restaurants.owner_user_id = auth.uid(),
--   NOT from a column on profiles. This keeps a single source of truth
--   and supports an owner owning more than one restaurant.
--
-- ORDER OF OPERATIONS (do not reorder):
--   1. profiles table + trigger
--   2. Backfill profiles + set your super_admin (EDIT THE EMAIL)
--   3. Helper functions
--   4. Enable RLS + policies
-- Create your super_admin BEFORE enabling RLS or you can lock yourself out.
-- =====================================================================


-- ---------------------------------------------------------------------
-- 1. PROFILES
-- ---------------------------------------------------------------------
create table if not exists public.profiles (
  id         uuid primary key references auth.users (id) on delete cascade,
  email      text,
  role       text not null default 'restaurant_owner'
               check (role in ('super_admin', 'restaurant_owner')),
  created_at timestamptz not null default now()
);

comment on table public.profiles is
  'Per-user role. Ownership of restaurants lives on restaurants.owner_user_id.';

-- Auto-create a profile for every new auth user (defaults to owner).
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, role)
  values (new.id, new.email, 'restaurant_owner')
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();


-- ---------------------------------------------------------------------
-- 2. BACKFILL  (EDIT THE EMAIL, then run)
-- ---------------------------------------------------------------------
insert into public.profiles (id, email, role)
select u.id, u.email, 'restaurant_owner'
from auth.users u
where not exists (select 1 from public.profiles p where p.id = u.id);

-- >>> CHANGE THIS EMAIL to your own login before running. <<<
update public.profiles
set role = 'super_admin'
where email = 'CHANGE_ME@example.com';


-- ---------------------------------------------------------------------
-- 3. HELPER FUNCTIONS  (SECURITY DEFINER to avoid RLS recursion)
-- ---------------------------------------------------------------------
create or replace function public.current_role()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select role from public.profiles where id = auth.uid();
$$;

create or replace function public.is_super_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(public.current_role() = 'super_admin', false);
$$;

-- True if the current user owns the given restaurant id.
create or replace function public.owns_restaurant(rid bigint)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.restaurants r
    where r.id = rid and r.owner_user_id = auth.uid()
  );
$$;


-- ---------------------------------------------------------------------
-- 4. RLS + POLICIES
-- ---------------------------------------------------------------------

-- 4a. profiles -------------------------------------------------------
alter table public.profiles enable row level security;

drop policy if exists profiles_select on public.profiles;
create policy profiles_select on public.profiles
  for select to authenticated
  using (id = auth.uid() or public.is_super_admin());

-- Only super_admin manages roles. Users cannot change their own role.
drop policy if exists profiles_admin_write on public.profiles;
create policy profiles_admin_write on public.profiles
  for all to authenticated
  using (public.is_super_admin())
  with check (public.is_super_admin());


-- 4b. restaurants ----------------------------------------------------
alter table public.restaurants enable row level security;

drop policy if exists restaurants_select on public.restaurants;
create policy restaurants_select on public.restaurants
  for select to authenticated
  using (public.is_super_admin() or owner_user_id = auth.uid());

-- Insert: super_admin only. (Owners do not create restaurants; also an
-- owner could otherwise insert a row owned by someone else.)
drop policy if exists restaurants_insert on public.restaurants;
create policy restaurants_insert on public.restaurants
  for insert to authenticated
  with check (public.is_super_admin());

-- Update: super_admin any; owner only their own, and may not reassign
-- ownership away from themselves (with check keeps owner_user_id = self).
drop policy if exists restaurants_update on public.restaurants;
create policy restaurants_update on public.restaurants
  for update to authenticated
  using (public.is_super_admin() or owner_user_id = auth.uid())
  with check (public.is_super_admin() or owner_user_id = auth.uid());

drop policy if exists restaurants_delete on public.restaurants;
create policy restaurants_delete on public.restaurants
  for delete to authenticated
  using (public.is_super_admin());


-- 4c. menu_items  (scoped via the parent restaurant's owner) ---------
alter table public.menu_items enable row level security;

drop policy if exists menu_items_select on public.menu_items;
create policy menu_items_select on public.menu_items
  for select to authenticated
  using (public.is_super_admin() or public.owns_restaurant(restaurant_id));

drop policy if exists menu_items_write on public.menu_items;
create policy menu_items_write on public.menu_items
  for all to authenticated
  using (public.is_super_admin() or public.owns_restaurant(restaurant_id))
  with check (public.is_super_admin() or public.owns_restaurant(restaurant_id));


-- 4d. orders  (now has restaurant_id from Phase 6.1) -----------------
alter table public.orders enable row level security;

-- Read: super_admin all; owner only orders for restaurants they own.
-- Legacy orders with restaurant_id = NULL are visible to super_admin only.
drop policy if exists orders_select on public.orders;
create policy orders_select on public.orders
  for select to authenticated
  using (
    public.is_super_admin()
    or (restaurant_id is not null and public.owns_restaurant(restaurant_id))
  );

-- Update (e.g. status changes): same scoping.
drop policy if exists orders_update on public.orders;
create policy orders_update on public.orders
  for update to authenticated
  using (
    public.is_super_admin()
    or (restaurant_id is not null and public.owns_restaurant(restaurant_id))
  )
  with check (
    public.is_super_admin()
    or (restaurant_id is not null and public.owns_restaurant(restaurant_id))
  );

-- Insert/Delete of orders: super_admin only in the admin panel. (The
-- customer app inserts orders via its own service role / policies; this
-- policy governs the authenticated admin-panel context.)
drop policy if exists orders_admin_insert on public.orders;
create policy orders_admin_insert on public.orders
  for insert to authenticated
  with check (public.is_super_admin());

drop policy if exists orders_admin_delete on public.orders;
create policy orders_admin_delete on public.orders
  for delete to authenticated
  using (public.is_super_admin());


-- 4e. order_items  (scoped via the parent order's restaurant) --------
alter table public.order_items enable row level security;

drop policy if exists order_items_select on public.order_items;
create policy order_items_select on public.order_items
  for select to authenticated
  using (
    public.is_super_admin()
    or exists (
      select 1 from public.orders o
      where o.id = order_items.order_id
        and o.restaurant_id is not null
        and public.owns_restaurant(o.restaurant_id)
    )
  );

drop policy if exists order_items_write on public.order_items;
create policy order_items_write on public.order_items
  for all to authenticated
  using (
    public.is_super_admin()
    or exists (
      select 1 from public.orders o
      where o.id = order_items.order_id
        and o.restaurant_id is not null
        and public.owns_restaurant(o.restaurant_id)
    )
  )
  with check (
    public.is_super_admin()
    or exists (
      select 1 from public.orders o
      where o.id = order_items.order_id
        and o.restaurant_id is not null
        and public.owns_restaurant(o.restaurant_id)
    )
  );


-- 4f. banners  (platform-wide: all signed-in read, super_admin write) -
alter table public.banners enable row level security;

drop policy if exists banners_select on public.banners;
create policy banners_select on public.banners
  for select to authenticated
  using (true);

drop policy if exists banners_admin_write on public.banners;
create policy banners_admin_write on public.banners
  for all to authenticated
  using (public.is_super_admin())
  with check (public.is_super_admin());


-- =====================================================================
-- VERIFY:
--   select id, email, role from public.profiles order by role;
--   select tablename, policyname, cmd from pg_policies
--     where schemaname = 'public' order by tablename, policyname;
-- =====================================================================

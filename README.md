# Zipani Admin Panel — Version 1 (Phase 1)

Admin panel for the Zipani food-delivery platform, sharing the existing
Supabase backend with the customer app.

## What Phase 1 includes
- **Login screen** — Supabase email/password auth. In V1, any authenticated
  user is the admin (no profiles/roles table yet, by design).
- **Sidebar shell** — responsive navigation (rail on wide screens, drawer on
  mobile) wrapping all authenticated routes via a GoRouter `ShellRoute`.
- **Dashboard shell** — placeholder metric cards and chart area; no data wiring.
- Route guards redirect signed-out users to `/login` and signed-in users away
  from it.

## Architecture
- State: **Riverpod**
- Routing: **GoRouter** (auth-aware redirects)
- Backend: **supabase_flutter**

## Built around your existing tables (unchanged)
restaurants · menu_items · orders · order_items · banners
No new tables are created in V1.

## Setup
1. `flutter pub get`
2. Put real values in `.env` (`SUPABASE_URL`, `SUPABASE_ANON_KEY`).
3. Create an admin user in the Supabase dashboard (Authentication → Users).
4. Run: `flutter run -d chrome` (web is the intended target for an admin panel).

## Not included yet (later phases)
CRUD logic, queries, image uploads, realtime orders, profiles/roles,
audit logs, menu categories.

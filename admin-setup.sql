-- ============================================================
-- CB Research — Step 1: Set yourself as admin + admin RLS policies
-- Run this whole file in Supabase → SQL Editor → New query → Run
-- ============================================================

-- Safety: make sure the is_admin column exists (it should already, from schema.sql)
alter table members add column if not exists is_admin boolean default false;

-- ------------------------------------------------------------
-- 1) Make yourself admin
--    Replace the email below with the EXACT email you used to
--    log in at login-test.html, then run this file.
-- ------------------------------------------------------------
update members
set is_admin = true
where id = (select id from auth.users where email = 'admin@kaveripower.com');

-- Sanity check — should return one row with is_admin = true
select id, phone, is_admin, subscription_status
from members
where id = (select id from auth.users where email = 'admin@kaveripower.com');

-- ------------------------------------------------------------
-- 2) Admin RLS policies
--    Lets an admin's session read/update ALL member rows
--    (a normal member can still only see their own row).
--    Uses a SECURITY DEFINER helper to avoid infinite-recursion
--    issues that come from a policy on `members` querying `members`.
-- ------------------------------------------------------------
create or replace function public.is_admin()
returns boolean
language sql
security definer
set search_path = public
as $$
  select coalesce(
    (select is_admin from members where id = auth.uid()),
    false
  );
$$;

drop policy if exists "admins can view all members" on members;
create policy "admins can view all members"
on members for select
using ( public.is_admin() );

drop policy if exists "admins can update all members" on members;
create policy "admins can update all members"
on members for update
using ( public.is_admin() );

-- ------------------------------------------------------------
-- Done. In the portal, the 🔧 Admin Panel button will now appear
-- automatically for your account after you sign in again.
-- ------------------------------------------------------------

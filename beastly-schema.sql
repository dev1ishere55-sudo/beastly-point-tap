-- Beastly Point Tap — Upgraded schema + RLS
-- Run this in the Supabase SQL Editor (or as a migration).
-- Never put service-role keys in client code.

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default 'Barnyard Rookie',
  wallet text unique,
  points numeric not null default 0,
  total_mined numeric not null default 0,
  tap_power integer not null default 1,
  passive_rate integer not null default 75,
  stamina_capacity integer not null default 1000,
  regen_seconds integer not null default 1800,
  stamina numeric not null default 1000,
  last_action timestamptz not null default now(),
  last_claim timestamptz not null default now(),
  boost_until timestamptz,
  frenzy_until timestamptz,
  cooldown_until timestamptz,
  tap_times timestamptz[] not null default '{}',
  pump_count integer not null default 0,
  leaderboard_opt_in boolean not null default true,
  profile_visible boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.wallet_nonces (
  nonce text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  wallet text not null,
  message text not null,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default (now() + interval '5 minutes'),
  used_at timestamptz
);

create index if not exists wallet_nonces_user_idx on public.wallet_nonces (user_id);
create index if not exists profiles_leaderboard_idx on public.profiles (total_mined desc) where leaderboard_opt_in = true;

alter table public.profiles enable row level security;
alter table public.wallet_nonces enable row level security;

drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own" on public.profiles
  for select using (auth.uid() = id);

-- Public leaderboard: only opted-in profiles, limited columns via view or direct select
drop policy if exists "profiles_leaderboard_public" on public.profiles;
create policy "profiles_leaderboard_public" on public.profiles
  for select using (leaderboard_opt_in = true);

drop policy if exists "profiles_insert_own" on public.profiles;
create policy "profiles_insert_own" on public.profiles
  for insert with check (auth.uid() = id);

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own" on public.profiles
  for update using (auth.uid() = id);

drop policy if exists "nonces_no_client_access" on public.wallet_nonces;
create policy "nonces_no_client_access" on public.wallet_nonces
  for all using (false);

create or replace function public.link_verified_wallet(uid uuid, n text, w text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.wallet_nonces
  set used_at = now()
  where nonce = n and user_id = uid and wallet = w and used_at is null;

  if not found then
    raise exception 'Invalid or already used nonce';
  end if;

  update public.profiles
  set wallet = w
  where id = uid;
end;
$$;

create or replace function public.ensure_profile()
returns public.profiles
language plpgsql
security definer
set search_path = public
as $$
declare
  result public.profiles;
begin
  insert into public.profiles (id)
  values (auth.uid())
  on conflict (id) do nothing;

  select * into result from public.profiles where id = auth.uid();
  return result;
end;
$$;

grant execute on function public.ensure_profile() to authenticated;
grant execute on function public.link_verified_wallet(uuid, text, text) to service_role;

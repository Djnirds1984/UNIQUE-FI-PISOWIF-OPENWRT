create extension if not exists pgcrypto;

create table public.machines (
  id uuid primary key default gen_random_uuid(),
  mac_address text unique not null,
  machine_name text not null,
  status text not null default 'online' check (status in ('online','offline','maintenance')),
  location text,
  created_at timestamptz not null default now()
);

create table public.sessions (
  id uuid primary key default gen_random_uuid(),
  client_mac text not null,
  machine_id uuid references public.machines(id) on delete set null,
  expiration_time timestamptz not null,
  data_left bigint,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create index on public.sessions (client_mac);
create index on public.sessions (machine_id);
create index on public.sessions (is_active);

create table public.vouchers (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  duration integer not null,
  price numeric(10,2) not null,
  is_used boolean not null default false,
  used_at timestamptz,
  created_at timestamptz not null default now()
);

create table public.sales (
  id bigserial primary key,
  machine_id uuid not null references public.machines(id) on delete cascade,
  amount integer not null,
  client_mac text,
  inserted_at timestamptz not null default now()
);

alter table public.machines enable row level security;
alter table public.sessions enable row level security;
alter table public.vouchers enable row level security;
alter table public.sales enable row level security;

create policy "read_machines_public" on public.machines for select to anon using (true);
create policy "read_sales_public" on public.sales for select to anon using (true);

create or replace function public.check_active_session(client_mac text)
returns table (is_active boolean, expiration_time timestamptz, seconds_left integer)
language plpgsql
security definer
set search_path = public
as $$
begin
  return query
  select s.is_active and s.expiration_time > now() as is_active,
         s.expiration_time,
         greatest(floor(extract(epoch from (s.expiration_time - now())))::int, 0) as seconds_left
  from public.sessions s
  where s.client_mac = check_active_session.client_mac
  order by s.expiration_time desc
  limit 1;
end;
$$;

grant execute on function public.check_active_session(text) to anon;

create or replace function public.redeem_voucher(code text, client_mac text, machine_id uuid)
returns table (expiration_time timestamptz, seconds_left integer)
language plpgsql
security definer
set search_path = public
as $$
declare v_duration integer;
declare v_now timestamptz := now();
declare v_exp timestamptz;
begin
  select duration into v_duration
  from public.vouchers
  where public.vouchers.code = redeem_voucher.code and is_used = false
  for update;
  if not found then
    raise exception 'invalid_or_used_voucher';
  end if;

  update public.vouchers
    set is_used = true, used_at = v_now
    where code = redeem_voucher.code;

  select expiration_time into v_exp
  from public.sessions
  where client_mac = redeem_voucher.client_mac
  order by expiration_time desc
  limit 1;

  if v_exp is null or v_exp <= v_now then
    v_exp := v_now + make_interval(secs => v_duration);
  else
    v_exp := v_exp + make_interval(secs => v_duration);
  end if;

  insert into public.sessions (client_mac, machine_id, expiration_time, is_active)
  values (redeem_voucher.client_mac, redeem_voucher.machine_id, v_exp, true);

  return query
  select v_exp as expiration_time,
         greatest(floor(extract(epoch from (v_exp - now())))::int, 0) as seconds_left;
end;
$$;

grant execute on function public.redeem_voucher(text, text, uuid) to anon;

alter publication supabase_realtime add table public.sales;

create table if not exists public.buyers (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  created_at timestamptz not null default now()
);

alter table public.buyers enable row level security;

create table if not exists public.buyer_users (
  id uuid primary key default gen_random_uuid(),
  buyer_id uuid not null references public.buyers(id) on delete cascade,
  user_id uuid not null,
  role text not null default 'buyer'
);

alter table public.buyer_users enable row level security;

alter table public.machines
  add column if not exists buyer_id uuid references public.buyers(id);

create table if not exists public.licenses (
  id uuid primary key default gen_random_uuid(),
  key text not null unique,
  buyer_id uuid not null references public.buyers(id) on delete cascade,
  machine_id uuid references public.machines(id) on delete set null,
  expires_at timestamptz not null,
  is_revoked boolean not null default false,
  created_at timestamptz not null default now(),
  created_by uuid
);

alter table public.licenses enable row level security;

create policy "buyers_select_provider_or_self" on public.buyers
for select to authenticated
using (
  exists (
    select 1 from public.buyer_users bu
    where bu.user_id = auth.uid() and (bu.role = 'provider' or bu.buyer_id = buyers.id)
  )
);

create policy "buyer_users_select_self" on public.buyer_users
for select to authenticated
using (user_id = auth.uid());

create policy "machines_select_provider_or_owner" on public.machines
for select to authenticated
using (
  exists (
    select 1 from public.buyer_users bu
    where bu.user_id = auth.uid()
      and (bu.role = 'provider' or public.machines.buyer_id = bu.buyer_id)
  )
);

create policy "sales_select_provider_or_owner" on public.sales
for select to authenticated
using (
  exists (
    select 1 from public.machines m
    join public.buyer_users bu on bu.user_id = auth.uid()
    where m.id = public.sales.machine_id
      and (bu.role = 'provider' or m.buyer_id = bu.buyer_id)
  )
);

create policy "sessions_select_provider_or_owner" on public.sessions
for select to authenticated
using (
  exists (
    select 1 from public.machines m
    join public.buyer_users bu on bu.user_id = auth.uid()
    where m.id = public.sessions.machine_id
      and (bu.role = 'provider' or m.buyer_id = bu.buyer_id)
  )
);

create policy "licenses_select_provider_or_owner" on public.licenses
for select to authenticated
using (
  exists (
    select 1 from public.buyer_users bu
    where bu.user_id = auth.uid()
      and (bu.role = 'provider' or public.licenses.buyer_id = bu.buyer_id)
  )
);

create policy "licenses_insert_provider" on public.licenses
for insert to authenticated
with check (
  exists (
    select 1 from public.buyer_users bu
    where bu.user_id = auth.uid() and bu.role = 'provider'
  )
);

create policy "licenses_update_provider" on public.licenses
for update to authenticated
using (
  exists (
    select 1 from public.buyer_users bu
    where bu.user_id = auth.uid() and bu.role = 'provider'
  )
)
with check (
  exists (
    select 1 from public.buyer_users bu
    where bu.user_id = auth.uid() and bu.role = 'provider'
  )
);

create or replace function public.random_key_16()
returns text
language sql
as $$
  select upper(encode(gen_random_bytes(8), 'hex'));
$$;

create or replace function public.create_license(buyer_id uuid, machine_id uuid, expires_at timestamptz)
returns table (id uuid, key text, expires_at timestamptz, is_revoked boolean)
language plpgsql
security definer
set search_path = public
as $$
declare v_key text;
begin
  loop
    select public.random_key_16() into v_key;
    exit when not exists (select 1 from public.licenses where key = v_key);
  end loop;
  insert into public.licenses (key, buyer_id, machine_id, expires_at, created_by)
  values (v_key, create_license.buyer_id, create_license.machine_id, create_license.expires_at, auth.uid())
  returning licenses.id, licenses.key, licenses.expires_at, licenses.is_revoked
  into id, key, expires_at, is_revoked;
  return next;
end;
$$;

grant execute on function public.create_license(uuid, uuid, timestamptz) to authenticated;

create or replace function public.revoke_license(license_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.licenses set is_revoked = true where id = license_id;
  return true;
end;
$$;

grant execute on function public.revoke_license(uuid) to authenticated;

create or replace function public.is_license_active(license_key text, machine_id uuid)
returns table (active boolean, expires_at timestamptz)
language plpgsql
security definer
set search_path = public
as $$
declare v_exp timestamptz;
declare v_active boolean;
begin
  select l.expires_at into v_exp
  from public.licenses l
  where l.key = is_license_active.license_key
    and (is_license_active.machine_id is null or l.machine_id = is_license_active.machine_id)
    and l.is_revoked = false
  order by l.expires_at desc
  limit 1;
  if v_exp is null then
    v_active := false;
  else
    v_active := v_exp > now();
  end if;
  return query select v_active, v_exp;
end;
$$;

grant execute on function public.is_license_active(text, uuid) to anon, authenticated;

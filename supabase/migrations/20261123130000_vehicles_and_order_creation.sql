create table public.vehicles (
  id uuid primary key default gen_random_uuid(),
  plate text not null check (length(btrim(plate)) between 1 and 12),
  make text not null check (length(btrim(make)) > 0),
  model text not null check (length(btrim(model)) > 0),
  model_year integer check (model_year is null or model_year between 1886 and 2100),
  chassis text not null default '',
  customer_name text not null check (length(btrim(customer_name)) > 0),
  contact_phone text not null default '',
  contact_email text not null default '',
  created_by uuid not null default auth.uid()
    references public.profiles (id) on delete restrict,
  created_at timestamptz not null default now()
);

create unique index vehicles_plate_normalized_idx
on public.vehicles (
  upper(regexp_replace(btrim(plate), '[[:space:]-]+', '', 'g'))
);
create index vehicles_created_by_idx on public.vehicles (created_by);

alter table public.jobs
add column vehicle_id uuid references public.vehicles (id) on delete restrict;

create index jobs_vehicle_id_idx on public.jobs (vehicle_id);

alter table public.vehicles enable row level security;

create policy vehicles_read_by_role
on public.vehicles
for select
to authenticated
using (
  (select private.current_app_role()) in (
    'ADMIN'::public.app_role,
    'MECHANIC'::public.app_role
  )
);

create policy vehicles_create_by_role
on public.vehicles
for insert
to authenticated
with check (
  (select private.current_app_role()) in (
    'ADMIN'::public.app_role,
    'MECHANIC'::public.app_role
  )
  and created_by = (select auth.uid())
);

drop policy jobs_create_as_self on public.jobs;

create policy jobs_create_as_self
on public.jobs
for insert
to authenticated
with check (
  (select private.current_app_role()) in (
    'ADMIN'::public.app_role,
    'MECHANIC'::public.app_role
  )
  and created_by = (select auth.uid())
  and vehicle_id is not null
);

revoke all on table public.vehicles from public, anon, authenticated;
grant select on table public.vehicles to authenticated;
grant insert (
  plate,
  make,
  model,
  model_year,
  chassis,
  customer_name,
  contact_phone,
  contact_email
) on public.vehicles to authenticated;
grant insert (vehicle_id) on public.jobs to authenticated;

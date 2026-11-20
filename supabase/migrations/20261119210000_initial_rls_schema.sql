create type public.app_role as enum ('ADMIN', 'MECHANIC');

create schema if not exists private;
revoke all on schema private from public, anon, authenticated;
grant usage on schema private to authenticated;

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  role public.app_role not null default 'MECHANIC',
  created_at timestamptz not null default now()
);

create table public.jobs (
  id uuid primary key default gen_random_uuid(),
  plate text not null check (length(plate) <= 12),
  work_date date not null,
  customer_name text not null,
  contact_phone text not null default '',
  contact_email text not null default '',
  vehicle text not null,
  chassis text not null default '',
  mileage bigint not null default 0 check (mileage >= 0),
  work_description text not null default '',
  supplies text not null default '',
  notes text not null default '',
  created_by uuid not null default auth.uid()
    references public.profiles (id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.job_photos (
  id uuid primary key default gen_random_uuid(),
  job_id uuid not null references public.jobs (id) on delete cascade,
  storage_path text not null unique check (storage_path <> ''),
  file_name text not null,
  mime_type text not null,
  file_size_bytes bigint not null check (file_size_bytes >= 0),
  uploaded_by uuid not null default auth.uid()
    references public.profiles (id) on delete restrict,
  created_at timestamptz not null default now()
);

create index jobs_created_by_idx on public.jobs (created_by);
create index job_photos_job_id_idx on public.job_photos (job_id);

create function private.current_app_role()
returns public.app_role
language sql
stable
security invoker
set search_path = ''
as $$
  select profile.role
  from public.profiles as profile
  where profile.id = (select auth.uid())
$$;

revoke all on function private.current_app_role() from public, anon, authenticated;
grant execute on function private.current_app_role() to authenticated;

create function private.create_mechanic_profile()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, role)
  values (new.id, 'MECHANIC');
  return new;
end;
$$;

revoke all on function private.create_mechanic_profile() from public, anon, authenticated;

create trigger create_profile_for_new_auth_user
after insert on auth.users
for each row execute function private.create_mechanic_profile();

create function private.set_job_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

revoke all on function private.set_job_updated_at() from public, anon, authenticated;

create trigger set_job_updated_at
before update on public.jobs
for each row execute function private.set_job_updated_at();

alter table public.profiles enable row level security;
alter table public.jobs enable row level security;
alter table public.job_photos enable row level security;

create policy profiles_read_self
on public.profiles
for select
to authenticated
using (id = (select auth.uid()));

create policy jobs_read_all
on public.jobs
for select
to authenticated
using (
  (select private.current_app_role()) in (
    'ADMIN'::public.app_role,
    'MECHANIC'::public.app_role
  )
);

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
);

create policy jobs_update_by_role
on public.jobs
for update
to authenticated
using (
  (select private.current_app_role()) = 'ADMIN'::public.app_role
  or (
    (select private.current_app_role()) = 'MECHANIC'::public.app_role
    and created_by = (select auth.uid())
  )
)
with check (
  (select private.current_app_role()) = 'ADMIN'::public.app_role
  or (
    (select private.current_app_role()) = 'MECHANIC'::public.app_role
    and created_by = (select auth.uid())
  )
);

create policy jobs_delete_admin
on public.jobs
for delete
to authenticated
using ((select private.current_app_role()) = 'ADMIN'::public.app_role);

create policy job_photos_read_visible_jobs
on public.job_photos
for select
to authenticated
using (
  (select private.current_app_role()) in (
    'ADMIN'::public.app_role,
    'MECHANIC'::public.app_role
  )
  and exists (
    select 1
    from public.jobs as job
    where job.id = job_photos.job_id
  )
);

create policy job_photos_add_to_visible_jobs
on public.job_photos
for insert
to authenticated
with check (
  (select private.current_app_role()) in (
    'ADMIN'::public.app_role,
    'MECHANIC'::public.app_role
  )
  and uploaded_by = (select auth.uid())
  and exists (
    select 1
    from public.jobs as job
    where job.id = job_photos.job_id
  )
);

create policy job_photos_delete_admin
on public.job_photos
for delete
to authenticated
using ((select private.current_app_role()) = 'ADMIN'::public.app_role);

revoke all on table public.profiles, public.jobs, public.job_photos
from public, anon, authenticated;

grant select on table public.profiles, public.jobs, public.job_photos to authenticated;
grant insert (
  plate,
  work_date,
  customer_name,
  contact_phone,
  contact_email,
  vehicle,
  chassis,
  mileage,
  work_description,
  supplies,
  notes
) on public.jobs to authenticated;
grant update (
  plate,
  work_date,
  customer_name,
  contact_phone,
  contact_email,
  vehicle,
  chassis,
  mileage,
  work_description,
  supplies,
  notes
) on public.jobs to authenticated;
grant delete on public.jobs to authenticated;

grant insert (
  job_id,
  storage_path,
  file_name,
  mime_type,
  file_size_bytes
) on public.job_photos to authenticated;
grant delete on public.job_photos to authenticated;

insert into storage.buckets (id, name, public)
values ('work-photos', 'work-photos', false)
on conflict (id) do update
set name = excluded.name, public = false;

-- Supabase Storage enables RLS on storage.objects by default.
create policy work_photos_read_with_metadata
on storage.objects
for select
to authenticated
using (
  bucket_id = 'work-photos'
  and exists (
    select 1
    from public.job_photos as photo
    where photo.storage_path = storage.objects.name
  )
);

create policy work_photos_add_with_metadata
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'work-photos'
  and exists (
    select 1
    from public.job_photos as photo
    where photo.storage_path = storage.objects.name
      and photo.uploaded_by = (select auth.uid())
  )
);

create policy work_photos_delete_admin
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'work-photos'
  and (select private.current_app_role()) = 'ADMIN'::public.app_role
);

begin;

select no_plan();

create function pg_temp.was_denied(p_sql text)
returns boolean
language plpgsql
as $$
begin
  execute p_sql;
  return false;
exception
  when insufficient_privilege then
    return true;
end;
$$;

create function pg_temp.violates_check(p_sql text)
returns boolean
language plpgsql
as $$
begin
  execute p_sql;
  return false;
exception
  when check_violation then
    return true;
end;
$$;

create function pg_temp.affected_rows(p_sql text)
returns integer
language plpgsql
as $$
declare
  affected integer;
begin
  execute p_sql;
  get diagnostics affected = row_count;
  return affected;
end;
$$;

insert into auth.users (
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at
)
values
  (
    '00000000-0000-0000-0000-000000000001',
    'authenticated',
    'authenticated',
    'admin@example.invalid',
    '',
    now(),
    '{"provider":"email","providers":["email"]}',
    '{"role":"ADMIN"}',
    now(),
    now()
  ),
  (
    '00000000-0000-0000-0000-000000000002',
    'authenticated',
    'authenticated',
    'mechanic@example.invalid',
    '',
    now(),
    '{"provider":"email","providers":["email"]}',
    '{"role":"ADMIN"}',
    now(),
    now()
  );

update public.profiles
set role = 'ADMIN'
where id = '00000000-0000-0000-0000-000000000001';

select is(
  (select role from public.profiles where id = '00000000-0000-0000-0000-000000000002'),
  'MECHANIC'::public.app_role,
  'auth user metadata cannot grant ADMIN'
);

insert into public.jobs (
  id, plate, work_date, customer_name, vehicle, created_by
)
values
  (
    '10000000-0000-0000-0000-000000000001',
    'DE-MO-01',
    '2026-01-01',
    'Cliente ficticio 01',
    'Vehículo de prueba 01',
    '00000000-0000-0000-0000-000000000002'
  ),
  (
    '10000000-0000-0000-0000-000000000002',
    'DE-MO-02',
    '2026-01-02',
    'Cliente ficticio 02',
    'Vehículo de prueba 02',
    '00000000-0000-0000-0000-000000000001'
  );

insert into public.job_photos (
  id, job_id, storage_path, file_name, mime_type, file_size_bytes, uploaded_by
)
values
  (
    '20000000-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000001',
    'fixture/mechanic.jpg',
    'mechanic.jpg',
    'image/jpeg',
    100,
    '00000000-0000-0000-0000-000000000002'
  ),
  (
    '20000000-0000-0000-0000-000000000002',
    '10000000-0000-0000-0000-000000000002',
    'fixture/admin.jpg',
    'admin.jpg',
    'image/jpeg',
    100,
    '00000000-0000-0000-0000-000000000001'
  );

select is(
  (select file_size_limit from storage.buckets where id = 'work-photos'),
  10485760::bigint,
  'photo bucket enforces a 10 MiB upload limit'
);
select is(
  (select allowed_mime_types from storage.buckets where id = 'work-photos'),
  array['image/jpeg', 'image/png', 'image/webp']::text[],
  'photo bucket allows only JPEG, PNG, and WebP'
);

insert into public.job_photos (
  job_id, storage_path, file_name, mime_type, file_size_bytes, uploaded_by
)
values
  (
    '10000000-0000-0000-0000-000000000001',
    'fixture/policy-min.jpg',
    'policy-min.jpg',
    'image/jpeg',
    1,
    '00000000-0000-0000-0000-000000000002'
  ),
  (
    '10000000-0000-0000-0000-000000000001',
    'fixture/policy-max.png',
    'policy-max.png',
    'image/png',
    10485760,
    '00000000-0000-0000-0000-000000000002'
  ),
  (
    '10000000-0000-0000-0000-000000000001',
    'fixture/policy-webp.webp',
    'policy-webp.webp',
    'image/webp',
    100,
    '00000000-0000-0000-0000-000000000002'
  );
select is(
  (
    select count(*)::integer
    from public.job_photos
    where storage_path in (
      'fixture/policy-min.jpg',
      'fixture/policy-max.png',
      'fixture/policy-webp.webp'
    )
  ),
  3,
  'photo metadata accepts allowed types and inclusive size boundaries'
);
delete from public.job_photos
where storage_path in (
  'fixture/policy-min.jpg',
  'fixture/policy-max.png',
  'fixture/policy-webp.webp'
);

select ok(
  pg_temp.violates_check($command$
    insert into public.job_photos (
      job_id, storage_path, file_name, mime_type, file_size_bytes, uploaded_by
    )
    values (
      '10000000-0000-0000-0000-000000000001',
      'fixture/policy-heic.heic',
      'policy-heic.heic',
      'image/heic',
      100,
      '00000000-0000-0000-0000-000000000002'
    )
  $command$),
  'photo metadata rejects HEIC'
);
select ok(
  pg_temp.violates_check($command$
    insert into public.job_photos (
      job_id, storage_path, file_name, mime_type, file_size_bytes, uploaded_by
    )
    values (
      '10000000-0000-0000-0000-000000000001',
      'fixture/policy-empty.jpg',
      'policy-empty.jpg',
      'image/jpeg',
      0,
      '00000000-0000-0000-0000-000000000002'
    )
  $command$),
  'photo metadata rejects empty files'
);
select ok(
  pg_temp.violates_check($command$
    insert into public.job_photos (
      job_id, storage_path, file_name, mime_type, file_size_bytes, uploaded_by
    )
    values (
      '10000000-0000-0000-0000-000000000001',
      'fixture/policy-too-large.jpg',
      'policy-too-large.jpg',
      'image/jpeg',
      10485761,
      '00000000-0000-0000-0000-000000000002'
    )
  $command$),
  'photo metadata rejects files over 10 MiB'
);

insert into storage.objects (bucket_id, name)
values
  ('work-photos', 'fixture/mechanic.jpg'),
  ('work-photos', 'fixture/admin.jpg');

set local role anon;
select ok(
  pg_temp.was_denied(
    'select count(*) from public.jobs'
  ),
  'anonymous direct job reads are denied'
);
select is(
  (select count(*)::integer from storage.objects),
  0,
  'anonymous direct photo reads return no files'
);

set local role authenticated;
set local request.jwt.claim.sub = '00000000-0000-0000-0000-000000000002';
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-000000000002","role":"authenticated"}';

select is((select count(*)::integer from public.jobs), 2, 'mechanic can list every job');
select is((select count(*)::integer from public.job_photos), 2, 'mechanic can read photo metadata for every visible job');
select is((select count(*)::integer from storage.objects where bucket_id = 'work-photos'), 2, 'mechanic can read files linked to photo metadata');
select ok(
  pg_temp.was_denied(
    $command$
      insert into storage.objects (bucket_id, name)
      values ('work-photos', 'fixture/no-metadata.jpg')
    $command$
  ),
  'photo files cannot be uploaded without matching metadata'
);

insert into public.jobs (
  plate, work_date, customer_name, vehicle
)
values (
  'DE-MO-03',
  '2026-01-03',
  'Cliente ficticio 03',
  'Vehículo de prueba 03'
);

select is(
  (
    select created_by
    from public.jobs
    where plate = 'DE-MO-03'
  ),
  '00000000-0000-0000-0000-000000000002'::uuid,
  'new job author comes from the authenticated identity'
);

insert into public.job_photos (
  job_id, storage_path, file_name, mime_type, file_size_bytes
)
values (
  '10000000-0000-0000-0000-000000000001',
  'fixture/mechanic-added.jpg',
  'mechanic-added.jpg',
  'image/jpeg',
  120
);

select is(
  (
    select uploaded_by
    from public.job_photos
    where storage_path = 'fixture/mechanic-added.jpg'
  ),
  '00000000-0000-0000-0000-000000000002'::uuid,
  'new photo author comes from the authenticated identity'
);

insert into storage.objects (bucket_id, name)
values ('work-photos', 'fixture/mechanic-added.jpg');

update public.jobs
set notes = 'Editado por el mecánico propietario'
where id = '10000000-0000-0000-0000-000000000001';

select is(
  (select notes from public.jobs where id = '10000000-0000-0000-0000-000000000001'),
  'Editado por el mecánico propietario',
  'mechanic can edit their own job'
);

select is(
  pg_temp.affected_rows($command$
    update public.jobs
    set notes = 'No debe cambiar'
    where id = '10000000-0000-0000-0000-000000000002'
  $command$),
  0,
  'mechanic cannot edit another author''s job by changing the target ID'
);
select is(
  (select notes from public.jobs where id = '10000000-0000-0000-0000-000000000002'),
  '',
  'foreign job remains unchanged'
);

select is(
  pg_temp.affected_rows($command$
    delete from public.jobs
    where id = '10000000-0000-0000-0000-000000000002'
  $command$),
  0,
  'mechanic cannot delete a job'
);
select is(
  pg_temp.affected_rows($command$
    delete from public.job_photos
    where id = '20000000-0000-0000-0000-000000000002'
  $command$),
  0,
  'mechanic cannot delete photo metadata'
);
-- Bypass Storage's direct-delete guard in this transaction to exercise RLS.
set local storage.allow_delete_query = 'true';

select is(
  pg_temp.affected_rows($command$
    delete from storage.objects
    where bucket_id = 'work-photos'
      and name = 'fixture/admin.jpg'
  $command$),
  0,
  'mechanic cannot delete a photo file'
);

select ok(
  pg_temp.was_denied($command$
    insert into public.jobs (id, plate, work_date, customer_name, vehicle)
    values ('10000000-0000-0000-0000-000000000003', 'DE-MO-04', '2026-01-04', 'Ficticio', 'Prueba')
  $command$),
  'client cannot choose a job ID'
);
select ok(
  pg_temp.was_denied($command$
    insert into public.jobs (plate, work_date, customer_name, vehicle, created_by)
    values ('DE-MO-05', '2026-01-05', 'Ficticio', 'Prueba', '00000000-0000-0000-0000-000000000001')
  $command$),
  'client cannot forge a job author'
);
select ok(
  pg_temp.was_denied($command$
    update public.jobs
    set created_by = '00000000-0000-0000-0000-000000000001'
    where id = '10000000-0000-0000-0000-000000000001'
  $command$),
  'client cannot change a job author'
);
select ok(
  pg_temp.was_denied($command$
    update public.jobs
    set id = '10000000-0000-0000-0000-000000000003'
    where id = '10000000-0000-0000-0000-000000000001'
  $command$),
  'client cannot change a job ID'
);
select ok(
  pg_temp.was_denied($command$
    update public.profiles
    set role = 'ADMIN'
    where id = '00000000-0000-0000-0000-000000000002'
  $command$),
  'client cannot promote their profile'
);
select ok(
  pg_temp.was_denied($command$
    insert into public.job_photos (
      id, job_id, storage_path, file_name, mime_type, file_size_bytes
    )
    values (
      '20000000-0000-0000-0000-000000000003',
      '10000000-0000-0000-0000-000000000001',
      'fixture/forged-id.jpg',
      'forged-id.jpg',
      'image/jpeg',
      100
    )
  $command$),
  'client cannot choose a photo ID'
);
select ok(
  pg_temp.was_denied($command$
    insert into public.job_photos (
      job_id, storage_path, file_name, mime_type, file_size_bytes, uploaded_by
    )
    values (
      '10000000-0000-0000-0000-000000000001',
      'fixture/forged-author.jpg',
      'forged-author.jpg',
      'image/jpeg',
      100,
      '00000000-0000-0000-0000-000000000001'
    )
  $command$),
  'client cannot forge a photo author'
);
select ok(
  pg_temp.was_denied($command$
    update public.job_photos
    set id = '20000000-0000-0000-0000-000000000003'
    where id = '20000000-0000-0000-0000-000000000001'
  $command$),
  'client cannot change a photo ID'
);
select ok(
  pg_temp.was_denied($command$
    update public.job_photos
    set uploaded_by = '00000000-0000-0000-0000-000000000001'
    where id = '20000000-0000-0000-0000-000000000001'
  $command$),
  'client cannot change a photo author'
);

reset role;
set local role authenticated;
set local request.jwt.claim.sub = '00000000-0000-0000-0000-000000000001';
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-000000000001","role":"authenticated"}';

insert into public.jobs (
  plate, work_date, customer_name, vehicle
)
values (
  'DE-MO-06',
  '2026-01-06',
  'Cliente ficticio 06',
  'Vehículo de prueba 06'
);

select is(
  (select created_by from public.jobs where plate = 'DE-MO-06'),
  '00000000-0000-0000-0000-000000000001'::uuid,
  'admin-created job also uses the authenticated identity'
);

insert into public.job_photos (
  job_id, storage_path, file_name, mime_type, file_size_bytes
)
values (
  '10000000-0000-0000-0000-000000000002',
  'fixture/admin-added.jpg',
  'admin-added.jpg',
  'image/jpeg',
  120
);

select is(
  (select uploaded_by from public.job_photos where storage_path = 'fixture/admin-added.jpg'),
  '00000000-0000-0000-0000-000000000001'::uuid,
  'admin-added photo also uses the authenticated identity'
);

insert into storage.objects (bucket_id, name)
values ('work-photos', 'fixture/admin-added.jpg');

select is((select count(*)::integer from public.jobs), 4, 'admin can list every job');
select is((select count(*)::integer from public.job_photos), 4, 'admin can read every photo metadata row');
select is((select count(*)::integer from storage.objects where bucket_id = 'work-photos'), 4, 'admin can read every linked photo file');
select ok(
  pg_temp.was_denied($command$
    update public.jobs
    set created_by = '00000000-0000-0000-0000-000000000002'
    where id = '10000000-0000-0000-0000-000000000002'
  $command$),
  'admin cannot change job authorship from the client'
);
select ok(
  pg_temp.was_denied($command$
    update public.jobs
    set id = '10000000-0000-0000-0000-000000000003'
    where id = '10000000-0000-0000-0000-000000000002'
  $command$),
  'admin cannot change job IDs from the client'
);

update public.jobs
set notes = 'Editado por administrador'
where id = '10000000-0000-0000-0000-000000000001';
select is(
  (select notes from public.jobs where id = '10000000-0000-0000-0000-000000000001'),
  'Editado por administrador',
  'admin can edit another author''s job'
);

delete from public.jobs
where id = '10000000-0000-0000-0000-000000000001';
select is(
  (select count(*)::integer from public.jobs where id = '10000000-0000-0000-0000-000000000001'),
  0,
  'admin can delete another author''s job'
);
select is(
  (select count(*)::integer from public.job_photos where id = '20000000-0000-0000-0000-000000000001'),
  0,
  'deleting a job removes its photo metadata'
);

delete from public.job_photos
where id = '20000000-0000-0000-0000-000000000002';
select is(
  (select count(*)::integer from public.job_photos where id = '20000000-0000-0000-0000-000000000002'),
  0,
  'admin can delete any photo metadata'
);
delete from public.job_photos
where storage_path = 'fixture/admin-added.jpg';
select is(
  (select count(*)::integer from public.job_photos where storage_path = 'fixture/admin-added.jpg'),
  0,
  'admin can delete metadata for a photo they added'
);

delete from storage.objects
where bucket_id = 'work-photos'
  and name = 'fixture/admin.jpg';
select is(
  (
    select count(*)::integer
    from storage.objects
    where bucket_id = 'work-photos'
      and name = 'fixture/admin.jpg'
  ),
  0,
  'admin can delete a photo file even after its metadata is removed'
);
delete from storage.objects
where bucket_id = 'work-photos'
  and name = 'fixture/admin-added.jpg';
select is(
  (
    select count(*)::integer
    from storage.objects
    where bucket_id = 'work-photos'
      and name = 'fixture/admin-added.jpg'
  ),
  0,
  'admin can delete a file after deleting its metadata'
);

select * from finish();
rollback;

alter table public.job_photos
  drop constraint job_photos_file_size_bytes_check,
  add constraint job_photos_file_size_bytes_check
    check (file_size_bytes between 1 and 10485760),
  add constraint job_photos_mime_type_check
    check (mime_type in ('image/jpeg', 'image/png', 'image/webp'));

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'work-photos',
  'work-photos',
  false,
  10485760,
  array['image/jpeg', 'image/png', 'image/webp']::text[]
)
on conflict (id) do update
set
  name = excluded.name,
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

alter table if exists public.notifikasi
  add column if not exists dibaca boolean not null default false;

create index if not exists idx_notifikasi_lansia_created_at
  on public.notifikasi (lansia_id, created_at desc);

create index if not exists idx_notifikasi_lansia_dibaca
  on public.notifikasi (lansia_id, dibaca);

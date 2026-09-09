-- Tambahkan dukungan target notifikasi WhatsApp ke Keluarga dan Lansia sekaligus.
-- Nilai yang didukung: keluarga, lansia, keduanya.

do $$
declare
  constraint_name text;
begin
  select c.conname
    into constraint_name
  from pg_constraint c
  join pg_class t on t.oid = c.conrelid
  join pg_namespace n on n.oid = t.relnamespace
  where n.nspname = 'public'
    and t.relname = 'lansia'
    and c.contype = 'c'
    and pg_get_constraintdef(c.oid) ilike '%notifikasi_target%'
  limit 1;

  if constraint_name is not null then
    execute format(
      'alter table public.lansia drop constraint %I',
      constraint_name
    );
  end if;
end $$;

alter table public.lansia
  add constraint lansia_notifikasi_target_check
  check (notifikasi_target in ('keluarga', 'lansia', 'keduanya'));

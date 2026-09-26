-- Mengizinkan akun Lansia maupun akun Keluarga yang terhubung
-- menghapus notifikasi milik Lansia yang dapat mereka akses.
alter table public.notifikasi enable row level security;

drop policy if exists "notifikasi_delete_accessible" on public.notifikasi;
create policy "notifikasi_delete_accessible"
on public.notifikasi
for delete
to authenticated
using (
  exists (
    select 1
    from public.lansia l
    where l.id = notifikasi.lansia_id
      and l.user_id = auth.uid()
  )
  or exists (
    select 1
    from public.keluarga_lansia kl
    where kl.lansia_id = notifikasi.lansia_id
      and kl.keluarga_user_id = auth.uid()
  )
);

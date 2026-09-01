create or replace function public.get_lansia_terhubung()
returns table (
  lansia_id uuid,
  nama text,
  email text
)
language plpgsql
security definer
set search_path = public, auth
as $$
begin
  if auth.uid() is null then
    raise exception 'Pengguna belum login.';
  end if;

  return query
  select
    l.id as lansia_id,
    l.nama::text,
    u.email::text
  from public.keluarga_lansia kl
  join public.lansia l on l.id = kl.lansia_id
  join auth.users u on u.id = l.user_id
  where kl.keluarga_user_id = auth.uid()
  order by kl.created_at asc nulls last
  limit 1;
end;
$$;

create or replace function public.putuskan_hubungan_lansia(p_lansia_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_deleted integer;
begin
  if auth.uid() is null then
    raise exception 'Pengguna belum login.';
  end if;

  delete from public.keluarga_lansia
  where keluarga_user_id = auth.uid()
    and lansia_id = p_lansia_id;

  get diagnostics v_deleted = row_count;
  return v_deleted > 0;
end;
$$;

-- Pairing berdasarkan email tetap menggunakan RPC lama, tetapi untuk model
-- satu akun keluarga -> satu Lansia, relasi lama diganti secara atomik.
create or replace function public.hubungkan_lansia_dengan_email(p_email text)
returns uuid
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_keluarga_user_id uuid := auth.uid();
  v_keluarga_role public.user_role;
  v_lansia_user_id uuid;
  v_lansia_id uuid;
begin
  if v_keluarga_user_id is null then
    raise exception 'Pengguna belum login.';
  end if;

  select role
  into v_keluarga_role
  from public.profiles
  where id = v_keluarga_user_id;

  if v_keluarga_role is distinct from 'keluarga'::public.user_role then
    raise exception 'Hanya akun keluarga yang dapat menghubungkan Lansia.';
  end if;

  select u.id
  into v_lansia_user_id
  from auth.users u
  join public.profiles p on p.id = u.id
  where lower(u.email) = lower(trim(p_email))
    and p.role = 'lansia'::public.user_role
  limit 1;

  if v_lansia_user_id is null then
    raise exception 'Akun Lansia dengan email tersebut tidak ditemukan.';
  end if;

  select l.id
  into v_lansia_id
  from public.lansia l
  where l.user_id = v_lansia_user_id
  limit 1;

  if v_lansia_id is null then
    raise exception 'Data Lansia belum tersedia. Silakan minta pengguna Lansia login terlebih dahulu.';
  end if;

  delete from public.keluarga_lansia
  where keluarga_user_id = v_keluarga_user_id
    and lansia_id <> v_lansia_id;

  insert into public.keluarga_lansia (keluarga_user_id, lansia_id)
  values (v_keluarga_user_id, v_lansia_id)
  on conflict (keluarga_user_id, lansia_id) do nothing;

  return v_lansia_id;
end;
$$;

revoke all on function public.get_lansia_terhubung() from public;
revoke all on function public.putuskan_hubungan_lansia(uuid) from public;
revoke all on function public.hubungkan_lansia_dengan_email(text) from public;

grant execute on function public.get_lansia_terhubung() to authenticated;
grant execute on function public.putuskan_hubungan_lansia(uuid) to authenticated;
grant execute on function public.hubungkan_lansia_dengan_email(text) to authenticated;

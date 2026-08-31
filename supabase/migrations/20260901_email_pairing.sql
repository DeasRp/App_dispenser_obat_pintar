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

  insert into public.keluarga_lansia (keluarga_user_id, lansia_id)
  values (v_keluarga_user_id, v_lansia_id)
  on conflict (keluarga_user_id, lansia_id) do nothing;

  return v_lansia_id;
end;
$$;

revoke all on function public.hubungkan_lansia_dengan_email(text) from public;
grant execute on function public.hubungkan_lansia_dengan_email(text) to authenticated;

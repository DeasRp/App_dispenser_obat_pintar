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

revoke all on function public.get_lansia_terhubung() from public;
revoke all on function public.putuskan_hubungan_lansia(uuid) from public;

grant execute on function public.get_lansia_terhubung() to authenticated;
grant execute on function public.putuskan_hubungan_lansia(uuid) to authenticated;

create table public.account_deletions (
  user_id uuid primary key references auth.users(id) on delete cascade
);
alter table public.account_deletions enable row level security;
revoke all on public.account_deletions from anon,authenticated;
grant all on public.account_deletions to service_role;

create table public.rooms (
  id uuid primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null check(length(title) between 1 and 90),
  room_type text not null, style text not null,
  brief text not null check(length(brief)<=1200),
  country text not null check(country in ('pk','in','us','gb','ae')),
  source_path text not null, result_path text,
  status text not null default 'queued' check(status in ('queued','rendering','tagging','ready','failed')),
  items jsonb not null default '[]', error text,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create index rooms_user_date on public.rooms(user_id,created_at desc);
alter table public.rooms enable row level security;
revoke all on public.rooms from anon,authenticated;
grant select on public.rooms to authenticated;
grant all on public.rooms to service_role;
create policy "Read own rooms" on public.rooms for select to authenticated using(user_id=(select auth.uid()));

create table public.favourites (
  user_id uuid not null references auth.users(id) on delete cascade,
  room_id uuid not null references public.rooms(id) on delete cascade,
  primary key(user_id,room_id)
);
alter table public.favourites enable row level security;
revoke all on public.favourites from anon,authenticated;
grant select,insert,delete on public.favourites to authenticated;
grant all on public.favourites to service_role;
create policy "Own favourites" on public.favourites for select to authenticated using(user_id=(select auth.uid()));
create policy "Add own favourite" on public.favourites for insert to authenticated with check(user_id=(select auth.uid()) and exists(select 1 from public.rooms where id=room_id and user_id=(select auth.uid())));
create policy "Delete own favourite" on public.favourites for delete to authenticated using(user_id=(select auth.uid()));

create table public.api_usage (
  user_id uuid not null references auth.users(id) on delete cascade,
  day date not null default ((now() at time zone 'utc')::date),
  kind text not null, used integer not null,
  primary key(user_id,day,kind)
);
alter table public.api_usage enable row level security;
revoke all on public.api_usage from anon,authenticated;
grant all on public.api_usage to service_role;

create table public.offer_cache (
  room_id uuid not null references public.rooms(id) on delete cascade,
  item_id uuid not null, payload jsonb not null,
  created_at timestamptz not null default now(),
  primary key(room_id,item_id)
);
alter table public.offer_cache enable row level security;
revoke all on public.offer_cache from anon,authenticated;
grant all on public.offer_cache to service_role;

create function public.use_credit(p_user uuid,p_kind text,p_limit integer)
returns void language plpgsql security definer set search_path='' as $$
declare n integer;
begin
  insert into public.api_usage(user_id,kind,used) values(p_user,p_kind,1)
    on conflict(user_id,day,kind) do update set used=public.api_usage.used+1
    where public.api_usage.used<p_limit returning used into n;
  if n is null or p_limit<1 then raise exception 'DAILY_LIMIT'; end if;
end $$;
revoke all on function public.use_credit(uuid,text,integer) from public,anon,authenticated;
grant execute on function public.use_credit(uuid,text,integer) to service_role;

create function public.reserve_room(p_id uuid,p_user uuid,p_title text,p_type text,p_style text,p_brief text,p_country text,p_source text,p_limit integer)
returns jsonb language plpgsql security definer set search_path='' as $$
declare r public.rooms;
begin
  perform pg_advisory_xact_lock(hashtextextended(p_user::text,17));
  if exists(select 1 from public.account_deletions where user_id=p_user) then raise exception 'ACCOUNT_DELETING'; end if;
  select * into r from public.rooms where id=p_id;
  if found then
    if r.user_id<>p_user then raise exception 'NOT_FOUND'; end if;
    return jsonb_build_object('created',false,'room',to_jsonb(r));
  end if;
  update public.rooms set status=case when result_path is null then 'failed' else 'ready' end,
    error='INTERRUPTED',updated_at=now()
    where user_id=p_user and status in ('queued','rendering','tagging') and updated_at<now()-interval '3 minutes';
  if exists(select 1 from public.rooms where user_id=p_user and status in ('queued','rendering','tagging')) then raise exception 'ACTIVE_ROOM'; end if;
  perform public.use_credit(p_user,'design',p_limit);
  insert into public.rooms(id,user_id,title,room_type,style,brief,country,source_path)
    values(p_id,p_user,p_title,p_type,p_style,p_brief,p_country,p_source) returning * into r;
  return jsonb_build_object('created',true,'room',to_jsonb(r));
end $$;
revoke all on function public.reserve_room(uuid,uuid,text,text,text,text,text,text,integer) from public,anon,authenticated;
grant execute on function public.reserve_room(uuid,uuid,text,text,text,text,text,text,integer) to service_role;

create function public.lock_account_delete(p_user uuid)
returns void language plpgsql security definer set search_path='' as $$
begin
  perform pg_advisory_xact_lock(hashtextextended(p_user::text,17));
  if exists(select 1 from public.rooms where user_id=p_user and status in ('queued','rendering','tagging')) then raise exception 'ACTIVE_ROOM'; end if;
  insert into public.account_deletions values(p_user) on conflict do nothing;
end $$;
revoke all on function public.lock_account_delete(uuid) from public,anon,authenticated;
grant execute on function public.lock_account_delete(uuid) to service_role;

create function public.can_upload_room() returns boolean language sql stable security definer set search_path='' as $$
  select exists(select 1 from auth.users where id=(select auth.uid()) and email_confirmed_at is not null)
    and not exists(select 1 from public.account_deletions where user_id=(select auth.uid()));
$$;
revoke all on function public.can_upload_room() from public,anon;
grant execute on function public.can_upload_room() to authenticated;

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
  values('rooms','rooms',false,10485760,array['image/jpeg','image/png','image/webp'])
  on conflict(id) do update set public=false,file_size_limit=excluded.file_size_limit,allowed_mime_types=excluded.allowed_mime_types;
create policy "Read room files" on storage.objects for select to authenticated using(bucket_id='rooms' and (storage.foldername(name))[1]=(select auth.uid())::text);
create policy "Upload own immutable original" on storage.objects for insert to authenticated with check(
  bucket_id='rooms' and (storage.foldername(name))[1]=(select auth.uid())::text and (select public.can_upload_room())
  and name ~ '^[a-f0-9-]{36}/[a-f0-9-]{36}/source\.(jpg|png|webp)$');

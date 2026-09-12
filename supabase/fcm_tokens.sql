create table if not exists public.fcm_tokens (
  token text primary key,
  user_id uuid references auth.users(id) on delete set null,
  platform text not null default 'unknown',
  is_enabled boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.fcm_tokens enable row level security;

drop policy if exists "Users can view own fcm tokens" on public.fcm_tokens;
create policy "Users can view own fcm tokens"
on public.fcm_tokens
for select
to authenticated
using (auth.uid() = user_id or user_id is null);

drop policy if exists "Users can register own fcm tokens" on public.fcm_tokens;
create policy "Users can register own fcm tokens"
on public.fcm_tokens
for insert
to authenticated
with check (auth.uid() = user_id or user_id is null);

drop policy if exists "Users can update own fcm tokens" on public.fcm_tokens;
create policy "Users can update own fcm tokens"
on public.fcm_tokens
for update
to authenticated
using (auth.uid() = user_id or user_id is null)
with check (auth.uid() = user_id or user_id is null);

drop policy if exists "Users can delete own fcm tokens" on public.fcm_tokens;
create policy "Users can delete own fcm tokens"
on public.fcm_tokens
for delete
to authenticated
using (auth.uid() = user_id or user_id is null);

drop policy if exists "Anonymous users can register anonymous fcm tokens" on public.fcm_tokens;
create policy "Anonymous users can register anonymous fcm tokens"
on public.fcm_tokens
for insert
to anon
with check (user_id is null);

drop policy if exists "Anonymous users can update anonymous fcm tokens" on public.fcm_tokens;
create policy "Anonymous users can update anonymous fcm tokens"
on public.fcm_tokens
for update
to anon
using (user_id is null)
with check (user_id is null);

drop policy if exists "Anonymous users can delete anonymous fcm tokens" on public.fcm_tokens;
create policy "Anonymous users can delete anonymous fcm tokens"
on public.fcm_tokens
for delete
to anon
using (user_id is null);

create index if not exists fcm_tokens_enabled_idx
on public.fcm_tokens (is_enabled, platform);

create index if not exists fcm_tokens_user_enabled_idx
on public.fcm_tokens (user_id, is_enabled);

create or replace function public.register_fcm_token(
  p_token text,
  p_platform text default 'unknown'
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    raise exception 'register_fcm_token requires an authenticated user';
  end if;

  insert into public.fcm_tokens (
    token,
    user_id,
    platform,
    is_enabled,
    updated_at
  )
  values (
    p_token,
    v_user_id,
    coalesce(nullif(trim(p_platform), ''), 'unknown'),
    true,
    now()
  )
  on conflict (token) do update
  set
    user_id = excluded.user_id,
    platform = excluded.platform,
    is_enabled = true,
    updated_at = now();
end;
$$;

grant execute on function public.register_fcm_token(text, text) to authenticated;

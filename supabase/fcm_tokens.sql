create table if not exists public.fcm_tokens (
  token text primary key,
  user_id uuid references auth.users(id) on delete set null,
  platform text not null default 'unknown',
  is_enabled boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.fcm_tokens enable row level security;

create policy "Users can register own fcm tokens"
on public.fcm_tokens
for insert
to authenticated
with check (auth.uid() = user_id or user_id is null);

create policy "Users can update own fcm tokens"
on public.fcm_tokens
for update
to authenticated
using (auth.uid() = user_id or user_id is null)
with check (auth.uid() = user_id or user_id is null);

create policy "Users can delete own fcm tokens"
on public.fcm_tokens
for delete
to authenticated
using (auth.uid() = user_id or user_id is null);

create policy "Anonymous users can register anonymous fcm tokens"
on public.fcm_tokens
for insert
to anon
with check (user_id is null);

create policy "Anonymous users can update anonymous fcm tokens"
on public.fcm_tokens
for update
to anon
using (user_id is null)
with check (user_id is null);

create policy "Anonymous users can delete anonymous fcm tokens"
on public.fcm_tokens
for delete
to anon
using (user_id is null);

create index if not exists fcm_tokens_enabled_idx
on public.fcm_tokens (is_enabled, platform);

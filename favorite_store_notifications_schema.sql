create table if not exists public.user_notification_preferences (
  user_id uuid primary key references auth.users(id) on delete cascade,
  favorite_store_notifications_enabled boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.user_notification_preferences enable row level security;

drop policy if exists "Users can view own notification preferences"
on public.user_notification_preferences;

create policy "Users can view own notification preferences"
on public.user_notification_preferences
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "Users can insert own notification preferences"
on public.user_notification_preferences;

create policy "Users can insert own notification preferences"
on public.user_notification_preferences
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "Users can update own notification preferences"
on public.user_notification_preferences;

create policy "Users can update own notification preferences"
on public.user_notification_preferences
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create index if not exists idx_user_notification_preferences_favorite_store
on public.user_notification_preferences (favorite_store_notifications_enabled);

create index if not exists idx_fcm_tokens_user_enabled
on public.fcm_tokens (user_id, is_enabled);

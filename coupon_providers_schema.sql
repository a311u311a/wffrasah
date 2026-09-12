create table if not exists public.coupon_providers (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  location text not null default '',
  created_at timestamptz not null default now()
);

alter table public.stores add column if not exists provider_id uuid references public.coupon_providers(id);
alter table public.coupons add column if not exists provider_id uuid references public.coupon_providers(id);
alter table public.offers add column if not exists provider_id uuid references public.coupon_providers(id);

alter table public.coupon_providers enable row level security;

drop policy if exists "authenticated can insert coupon providers" on public.coupon_providers;
drop policy if exists "authenticated can update coupon providers" on public.coupon_providers;
drop policy if exists "authenticated can delete coupon providers" on public.coupon_providers;

create policy "authenticated can insert coupon providers"
on public.coupon_providers for insert to authenticated with check (true);

create policy "authenticated can update coupon providers"
on public.coupon_providers for update to authenticated using (true) with check (true);

create policy "authenticated can delete coupon providers"
on public.coupon_providers for delete to authenticated using (true);

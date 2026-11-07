-- AliExpress affiliate products, refreshed daily by the `aliexpress-sync`
-- edge function. The app reads this table; only the service role writes it.

create table if not exists public.ali_products (
  product_id       bigint      not null,
  category_id      text        not null,
  title            text        not null,
  image            text,
  sale_price       numeric(12, 2),
  original_price   numeric(12, 2),
  discount_percent integer,
  currency         text        not null default 'SAR',
  commission_rate  numeric(5, 2),
  promotion_link   text        not null,
  detail_url       text,
  orders_count     integer,
  rating           numeric(5, 2),
  is_hot           boolean     not null default false,
  sort_score       numeric     not null default 0,
  updated_at       timestamptz not null default now(),
  primary key (product_id, category_id)
);

create index if not exists ali_products_category_score_idx
  on public.ali_products (category_id, sort_score desc);

create index if not exists ali_products_score_idx
  on public.ali_products (sort_score desc);

alter table public.ali_products enable row level security;

-- Categories that currently have products, so the app can hide empty ones.
create or replace view public.ali_product_categories
with (security_invoker = true) as
  select category_id, count(*)::int as products
  from public.ali_products
  group by category_id;

grant select on public.ali_product_categories to anon, authenticated;

drop policy if exists "ali_products public read" on public.ali_products;
create policy "ali_products public read"
  on public.ali_products
  for select
  to anon, authenticated
  using (true);

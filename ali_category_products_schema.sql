-- Phase 2: products for the new AliExpress categories (public.ali_categories),
-- filled by `aliexpress-sync` with {"source": "ali"}. Kept apart from
-- public.ali_products (store categories) so the current app and website do
-- not change until phase 3 switches the AliExpress screens to this table.

create table if not exists public.ali_category_products (
  product_id       bigint      not null,
  category_id      text        not null references public.ali_categories (id) on delete cascade,
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

create index if not exists ali_category_products_category_score_idx
  on public.ali_category_products (category_id, sort_score desc);

create index if not exists ali_category_products_score_idx
  on public.ali_category_products (sort_score desc);

alter table public.ali_category_products enable row level security;

drop policy if exists "ali_category_products public read" on public.ali_category_products;
create policy "ali_category_products public read"
  on public.ali_category_products for select
  to anon, authenticated
  using (true);

-- Active categories with their product counts, in display order, so the
-- screens can hide empty ones.
create or replace view public.ali_category_counts
with (security_invoker = true) as
  select c.id, c.sort_order, count(p.product_id)::int as products
  from public.ali_categories c
  left join public.ali_category_products p on p.category_id = c.id
  where c.active
  group by c.id, c.sort_order;

grant select on public.ali_category_counts to anon, authenticated;

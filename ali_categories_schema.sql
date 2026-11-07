-- AliExpress categories, separate from the store categories (public.categories).
-- Phase 1: the table and the 18 categories only. Nothing reads it yet; the
-- aliexpress-sync function and the AliExpress screens keep using
-- public.categories until phase 2/3 switch them over.
--
-- keywords: one AliExpress search, or several separated by `|`.
-- A `|` group that starts with `-` lists title words that drop a product.

create table if not exists public.ali_categories (
  id          text        primary key,
  name_ar     text        not null,
  name_en     text        not null,
  icon        text,
  sort_order  integer     not null,
  keywords    text        not null default '',
  active      boolean     not null default true,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create index if not exists ali_categories_sort_idx
  on public.ali_categories (sort_order);

alter table public.ali_categories enable row level security;

drop policy if exists "ali_categories public read" on public.ali_categories;
create policy "ali_categories public read"
  on public.ali_categories for select
  to anon, authenticated
  using (true);

drop policy if exists "ali_categories admin write" on public.ali_categories;
create policy "ali_categories admin write"
  on public.ali_categories for all
  to authenticated
  using (exists (select 1 from public.admins where admins.user_id = auth.uid()))
  with check (exists (select 1 from public.admins where admins.user_id = auth.uid()));

-- The 18 categories. Re-running updates names, icons and order but keeps any
-- keywords an admin has changed since.
insert into public.ali_categories (id, name_ar, name_en, icon, sort_order, keywords)
values
  ('women', 'نساء', 'Women', 'woman.png', 1,
    (select ali_keywords from public.categories where name_en = 'Women' limit 1)),
  ('home-kitchen', 'المنزل والمطبخ', 'Home & Kitchen', 'interior-design.png', 2,
    'kitchen gadgets | coffee tools | incense burner bakhoor | home decor | storage organizer | bedding set'),
  ('phones', 'جوالات وإكسسوارات', 'Phones & Accessories', 'electronic.png', 3,
    'phone case | fast charger | wireless earbuds | phone holder | usb c cable | power bank'),
  ('electronics', 'إلكترونيات', 'Electronics', 'electronic.png', 4,
    'bluetooth headphones | smart home | security camera | computer accessories | gaming accessories'),
  ('beauty', 'الجمال والعناية', 'Beauty & Care', 'makeup.png', 5,
    'makeup brushes tools | skin care device | hair styling tools | nail art | health monitor'),
  ('men', 'رجال', 'Men', 'muslim.png', 6,
    'men shirt long sleeve | men pants trousers | men jacket | men hoodie | men thobe accessories '
    || '| -مثير, سكسي, sexy, شفاف, see through, ملابس داخلية, underwear, شورت قصير'),
  ('shoes', 'أحذية', 'Shoes', 'shoes.png', 7,
    'women shoes | men shoes | kids shoes | sneakers'),
  ('bags-travel', 'حقائب وسفر', 'Bags & Travel', 'shopping-bag.png', 8,
    'women handbag | backpack | luggage suitcase | wallet | travel organizer'),
  ('watches-jewelry', 'ساعات ومجوهرات', 'Watches & Jewelry', 'wristwatch.png', 9,
    'watches | smart watch | women jewelry | men accessories | sunglasses'),
  ('baby-kids', 'الأم والطفل', 'Baby & Kids', 'feeding-bottle.png', 10,
    'baby essentials | kids clothing long sleeve | baby feeding | educational toys'),
  ('cars', 'السيارات', 'Cars', 'car.png', 11,
    'car interior accessories | car electronics | car cleaning tools | car phone holder'),
  ('sports-camping', 'رياضة وكشتات', 'Sports & Camping', 'dumbbell.png', 12,
    'fitness equipment | camping gear | outdoor tent | cycling accessories'),
  ('appliances', 'أجهزة منزلية', 'Appliances', 'interior-design.png', 13,
    'kitchen appliances | vacuum cleaner | personal care appliances | humidifier'),
  ('tools', 'عدد وأدوات', 'Tools', 'service.png', 14,
    'hand tools set | power tools | led lighting | home repair tools'),
  ('toys-hobbies', 'ألعاب وهوايات', 'Toys & Hobbies', 'video-game.png', 15,
    'toys | building blocks | drawing art supplies | diy crafts'),
  ('pets', 'الحيوانات الأليفة', 'Pets', 'pet-friendly.png', 16,
    'cat supplies | dog supplies | pet bed | pet toys'),
  ('office-school', 'مكتبية ومدرسية', 'Office & School', 'libraries.png', 17,
    'stationery | office supplies | school backpack | desk organizer'),
  ('gifts-occasions', 'هدايا ومناسبات', 'Gifts & Occasions', 'gift.png', 18,
    'ramadan decoration | eid decoration | gift box | party supplies')
on conflict (id) do update
  set name_ar    = excluded.name_ar,
      name_en    = excluded.name_en,
      icon       = excluded.icon,
      sort_order = excluded.sort_order,
      updated_at = now();

-- Icons are stored as file names in the `icon` storage bucket; turn them into
-- full public URLs like the store categories use.
update public.ali_categories
set icon = 'https://ilfbqykxkjructxunuxm.supabase.co/storage/v1/object/public/icon/' || icon
where icon is not null and icon not like 'http%';

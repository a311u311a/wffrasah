-- عرض شي إن: أفضل المنتجات المختارة – خصم 50% للمستخدمين الجدد (كود LV47474)
-- شغّل هذا الملف في Supabase SQL Editor.
-- آمن للتشغيل أكثر من مرة: لن يُكرر العرض إذا كان موجوداً.
--
-- الخطوات:
--   1) ارفع الصورة offer_images/shein_offer_LV47474.jpg إلى Supabase Storage
--      في الحاوية images داخل المجلد offers باسم shein_offer_LV47474.jpg
--      (المسار النهائي: images/offers/shein_offer_LV47474.jpg)
--   2) شغّل هذا الملف كاملاً. الجزء الأول يضيف العرض، والجزء الأخير يضيف الصورة.

-- =========================================================
-- الجزء 1: إضافة العرض
-- =========================================================
do $$
declare
  v_store_name  text;
  v_tags_type   text;
begin
  -- لا تكرر العرض
  if exists (
    select 1 from public.offers
    where store_id = 'shein'
      and tags::text like '%LV47474%'
  ) then
    raise notice 'عرض شي إن LV47474 موجود مسبقاً – تم التخطي';
    return;
  end if;

  -- اسم المتجر وفئته من جدول المتاجر (store_id = stores.slug)
  select coalesce(nullif(s.name_ar, ''), nullif(s.name, ''), nullif(s.name_en, ''), 'شي إن')
    into v_store_name
  from public.stores s
  where s.slug = 'shein'
  limit 1;

  if v_store_name is null then
    raise exception 'لا يوجد متجر بالمعرف (slug) shein في جدول stores – أضف المتجر أولاً';
  end if;

  -- عمود tags قد يكون text[] أو jsonb أو text
  select data_type into v_tags_type
  from information_schema.columns
  where table_schema = 'public' and table_name = 'offers' and column_name = 'tags';

  execute format(
    'insert into public.offers
       (name_ar, name_en, description_ar, description_en, web, image, tags,
        store_id, store_name, expiry_date, created_at)
     values ($1, $2, $3, $4, $5, $6, %s, $7, $8, $9, now())',
    case
      when v_tags_type = 'jsonb' then '''["LV47474"]''::jsonb'
      when v_tags_type = 'json'  then '''["LV47474"]''::json'
      when v_tags_type = 'ARRAY' then 'array[''LV47474'']::text[]'
      else '''LV47474'''
    end
  )
  using
    'أفضل المنتجات المختارة – خصم 50%',
    'Top Picks – 50% Off',
    'ابحث عن الكود LV47474 على تطبيق شي إن أو اضغط الرابط للبدء! خصم 50% للمستخدمين الجدد فقط – منتجات مختارة لفترة محدودة.',
    'Search for code LV47474 in the SHEIN app or tap the link to start! 50% off for new users only – selected products for a limited time.',
    'https://onelink.shein.com/59/67igxqght200',
    '',                                   -- الصورة تُضاف في الجزء الأخير
    'shein',
    v_store_name,
    now() + interval '30 days';           -- مدة العرض: 30 يوماً (عدّلها إن لزم)

  -- نفس فئة متجر شي إن (إن وُجدت)
  update public.offers o
  set category_id = s.category_id
  from public.stores s
  where s.slug = 'shein'
    and o.store_id = 'shein'
    and o.tags::text like '%LV47474%';

  raise notice 'تمت إضافة عرض شي إن LV47474';
end $$;

-- =========================================================
-- الجزء الأخير: إضافة صورة العرض
-- (بعد رفع الصورة إلى images/offers/shein_offer_LV47474.jpg)
-- =========================================================
update public.offers
set image = 'https://ilfbqykxkjructxunuxm.supabase.co/storage/v1/object/public/images/offers/shein_offer_LV47474.jpg'
where store_id = 'shein'
  and tags::text like '%LV47474%';

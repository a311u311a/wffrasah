-- Sync coupon display names from their linked stores.
-- Run this once in the Supabase SQL Editor.
--
-- coupons.store_id is expected to contain stores.slug.

UPDATE public.coupons AS c
SET
  name = COALESCE(NULLIF(s.name_ar, ''), NULLIF(s.name, ''), c.name),
  name_ar = COALESCE(NULLIF(s.name_ar, ''), NULLIF(s.name, ''), c.name_ar),
  name_en = COALESCE(
    NULLIF(s.name_en, ''),
    NULLIF(s.name, ''),
    NULLIF(s.name_ar, ''),
    c.name_en
  )
FROM public.stores AS s
WHERE c.store_id = s.slug;

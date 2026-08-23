-- Add expiry_date column to offers table
-- Run this in the Supabase SQL Editor

ALTER TABLE public.offers 
ADD COLUMN IF NOT EXISTS expiry_date TIMESTAMP WITH TIME ZONE;

ALTER TABLE public.offers
ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

ALTER TABLE public.offers
ALTER COLUMN created_at SET DEFAULT NOW();

UPDATE public.offers
SET created_at = NOW()
WHERE created_at IS NULL;

-- Store the linked store display name directly on each offer.
-- offers.store_id is expected to contain stores.slug.
ALTER TABLE public.offers
ADD COLUMN IF NOT EXISTS store_name TEXT;

UPDATE public.offers AS o
SET store_name = COALESCE(
  NULLIF(s.name_ar, ''),
  NULLIF(s.name, ''),
  NULLIF(s.name_en, ''),
  o.store_name
)
FROM public.stores AS s
WHERE o.store_id = s.slug
  AND (
    o.store_name IS NULL
    OR o.store_name = ''
    OR o.store_name IS DISTINCT FROM COALESCE(
      NULLIF(s.name_ar, ''),
      NULLIF(s.name, ''),
      NULLIF(s.name_en, ''),
      o.store_name
    )
  );

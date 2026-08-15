-- Add expiry_date column to coupons table
-- Run this in the Supabase SQL Editor

ALTER TABLE public.coupons 
ADD COLUMN IF NOT EXISTS expiry_date TIMESTAMP WITH TIME ZONE;

-- Approval workflow for automated coupon imports.
-- Manual admin inserts keep the default approved status and continue to publish immediately.
ALTER TABLE public.coupons
ADD COLUMN IF NOT EXISTS approval_status TEXT NOT NULL DEFAULT 'approved';

ALTER TABLE public.coupons
ADD COLUMN IF NOT EXISTS import_source TEXT NOT NULL DEFAULT 'manual';

ALTER TABLE public.coupons
ADD COLUMN IF NOT EXISTS source_coupon_id TEXT;

ALTER TABLE public.coupons
ADD COLUMN IF NOT EXISTS duplicate_key TEXT;

ALTER TABLE public.coupons
ADD COLUMN IF NOT EXISTS reviewed_at TIMESTAMP WITH TIME ZONE;

ALTER TABLE public.coupons
ADD COLUMN IF NOT EXISTS reviewed_by UUID;

ALTER TABLE public.coupons
ADD COLUMN IF NOT EXISTS rejection_reason TEXT;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'coupons_approval_status_check'
  ) THEN
    ALTER TABLE public.coupons
    ADD CONSTRAINT coupons_approval_status_check
    CHECK (approval_status IN ('waiting_approval', 'approved', 'rejected'));
  END IF;
END $$;

UPDATE public.coupons
SET approval_status = 'approved'
WHERE approval_status IS NULL;

UPDATE public.coupons
SET import_source = 'manual'
WHERE import_source IS NULL OR import_source = '';

ALTER TABLE public.coupons
ALTER COLUMN approval_status SET DEFAULT 'approved',
ALTER COLUMN approval_status SET NOT NULL;

ALTER TABLE public.coupons
ALTER COLUMN import_source SET DEFAULT 'manual',
ALTER COLUMN import_source SET NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS coupons_duplicate_key_unique
ON public.coupons (duplicate_key)
WHERE duplicate_key IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS stores_slug_unique
ON public.stores (slug)
WHERE slug IS NOT NULL AND slug <> '';

-- Approval workflow for stores created by automated imports.
-- Existing/manual stores remain visible immediately.
ALTER TABLE public.stores
ADD COLUMN IF NOT EXISTS approval_status TEXT NOT NULL DEFAULT 'approved';

ALTER TABLE public.stores
ADD COLUMN IF NOT EXISTS import_source TEXT NOT NULL DEFAULT 'manual';

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'stores_approval_status_check'
  ) THEN
    ALTER TABLE public.stores
    ADD CONSTRAINT stores_approval_status_check
    CHECK (approval_status IN ('waiting_approval', 'approved', 'rejected'));
  END IF;
END $$;

UPDATE public.stores
SET approval_status = 'approved'
WHERE approval_status IS NULL;

UPDATE public.stores
SET import_source = 'manual'
WHERE import_source IS NULL OR import_source = '';

UPDATE public.stores AS s
SET
  approval_status = 'waiting_approval',
  import_source = c.import_source
FROM (
  SELECT DISTINCT ON (store_id)
    store_id,
    import_source
  FROM public.coupons
  WHERE approval_status = 'waiting_approval'
    AND import_source <> 'manual'
    AND store_id IS NOT NULL
    AND store_id <> ''
  ORDER BY store_id, created_at DESC
) AS c
WHERE s.slug = c.store_id
  AND NOT EXISTS (
    SELECT 1
    FROM public.coupons approved
    WHERE approved.store_id = s.slug
      AND approved.approval_status = 'approved'
  );

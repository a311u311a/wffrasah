-- Store approval workflow for automated imports.
-- Run this once in the Supabase SQL Editor.
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

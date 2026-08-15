-- Immediate fix for the production app:
-- remove automated stores that are still waiting for approval from public stores.
-- Coupons are not deleted, so they stay visible in the admin approval queue.

DELETE FROM public.stores AS s
WHERE COALESCE(s.import_source, 'manual') <> 'manual'
  AND COALESCE(s.approval_status, 'approved') <> 'approved'
  AND NOT EXISTS (
    SELECT 1
    FROM public.coupons AS c
    WHERE c.store_id = s.slug
      AND c.approval_status = 'approved'
  );

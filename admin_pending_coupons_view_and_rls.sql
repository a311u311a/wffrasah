-- Keep waiting coupons visible only through the admin pending approval view.
-- After running this, direct reads from public.coupons show approved coupons only.
-- The admin pending screen should read public.admin_pending_coupons.

CREATE OR REPLACE VIEW public.admin_pending_coupons AS
SELECT
  c.*,
  s.name AS store_name,
  s.name_ar AS store_name_ar,
  s.name_en AS store_name_en,
  s.description AS store_description,
  s.description_ar AS store_description_ar,
  s.description_en AS store_description_en,
  s.image AS store_image
FROM public.coupons AS c
LEFT JOIN public.stores AS s
  ON s.slug = c.store_id
WHERE c.approval_status = 'waiting_approval'
  AND COALESCE(c.import_source, 'manual') <> 'manual'
  AND EXISTS (
    SELECT 1
    FROM public.admins
    WHERE admins.user_id = auth.uid()
  );

GRANT SELECT ON public.admin_pending_coupons TO authenticated;

DROP POLICY IF EXISTS "Admins can view all coupons" ON public.coupons;
DROP POLICY IF EXISTS "Admins can view approved coupons" ON public.coupons;

CREATE POLICY "Admins can view approved coupons"
ON public.coupons
FOR SELECT
TO authenticated
USING (
  COALESCE(approval_status, 'approved') = 'approved'
  AND EXISTS (
    SELECT 1
    FROM public.admins
    WHERE admins.user_id = auth.uid()
  )
);

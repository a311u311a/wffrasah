-- Hide expired coupons, offers and home banners from the public app and website.
-- An item stays visible until the END of its expiry day (Saudi time), then disappears.
-- Items with no expiry_date never expire. Nothing is deleted: extending the date
-- from the admin panel makes the item visible again.
-- Admins keep seeing everything so they can edit or delete expired items.
-- Run this once in the Supabase SQL Editor, after hide_pending_imports_from_public_rls.sql.

-- 1) Banners get an optional expiry date.
ALTER TABLE public.carousel
ADD COLUMN IF NOT EXISTS expiry_date TIMESTAMP WITH TIME ZONE;

-- 2) One shared rule for "not expired yet".
CREATE OR REPLACE FUNCTION public.is_not_expired(expiry TIMESTAMP WITH TIME ZONE)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
AS $$
  SELECT expiry IS NULL
    OR now() < (((expiry AT TIME ZONE 'Asia/Riyadh')::date + 1)::timestamp
                AT TIME ZONE 'Asia/Riyadh');
$$;

GRANT EXECUTE ON FUNCTION public.is_not_expired(TIMESTAMP WITH TIME ZONE)
TO anon, authenticated;

CREATE OR REPLACE FUNCTION public.is_admin_user()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (SELECT 1 FROM public.admins WHERE admins.user_id = auth.uid());
$$;

GRANT EXECUTE ON FUNCTION public.is_admin_user() TO anon, authenticated;

-- 3) Replace the SELECT policies of coupons, offers and carousel.
ALTER TABLE public.coupons ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.offers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.carousel ENABLE ROW LEVEL SECURITY;

DO $$
DECLARE
  policy_record record;
BEGIN
  FOR policy_record IN
    SELECT policyname, tablename
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename IN ('coupons', 'offers', 'carousel')
      AND cmd = 'SELECT'
  LOOP
    EXECUTE format(
      'DROP POLICY IF EXISTS %I ON public.%I',
      policy_record.policyname,
      policy_record.tablename
    );
  END LOOP;
END $$;

-- Coupons: approved and not expired.
CREATE POLICY "Public can view approved active coupons"
ON public.coupons
FOR SELECT
TO anon, authenticated
USING (
  COALESCE(approval_status, 'approved') = 'approved'
  AND public.is_not_expired(expiry_date)
);

CREATE POLICY "Admins can view all coupons"
ON public.coupons
FOR SELECT
TO authenticated
USING (public.is_admin_user());

-- Offers: not expired.
CREATE POLICY "Public can view active offers"
ON public.offers
FOR SELECT
TO anon, authenticated
USING (public.is_not_expired(expiry_date));

CREATE POLICY "Admins can view all offers"
ON public.offers
FOR SELECT
TO authenticated
USING (public.is_admin_user());

-- Banners: not expired.
CREATE POLICY "Public can view active banners"
ON public.carousel
FOR SELECT
TO anon, authenticated
USING (public.is_not_expired(expiry_date));

CREATE POLICY "Admins can view all banners"
ON public.carousel
FOR SELECT
TO authenticated
USING (public.is_admin_user());

-- 4) Keep admin writes working on offers and banners in case RLS was off before.
--    (Existing write policies, if any, are left as they are.)
DROP POLICY IF EXISTS "Admins can insert offers" ON public.offers;
DROP POLICY IF EXISTS "Admins can update offers" ON public.offers;
DROP POLICY IF EXISTS "Admins can delete offers" ON public.offers;
CREATE POLICY "Admins can insert offers" ON public.offers
FOR INSERT TO authenticated WITH CHECK (public.is_admin_user());
CREATE POLICY "Admins can update offers" ON public.offers
FOR UPDATE TO authenticated USING (public.is_admin_user()) WITH CHECK (public.is_admin_user());
CREATE POLICY "Admins can delete offers" ON public.offers
FOR DELETE TO authenticated USING (public.is_admin_user());

DROP POLICY IF EXISTS "Admins can insert banners" ON public.carousel;
DROP POLICY IF EXISTS "Admins can update banners" ON public.carousel;
DROP POLICY IF EXISTS "Admins can delete banners" ON public.carousel;
CREATE POLICY "Admins can insert banners" ON public.carousel
FOR INSERT TO authenticated WITH CHECK (public.is_admin_user());
CREATE POLICY "Admins can update banners" ON public.carousel
FOR UPDATE TO authenticated USING (public.is_admin_user()) WITH CHECK (public.is_admin_user());
CREATE POLICY "Admins can delete banners" ON public.carousel
FOR DELETE TO authenticated USING (public.is_admin_user());

-- 5) The "most copied" ranking bypasses RLS (SECURITY DEFINER), so filter it here too.
CREATE OR REPLACE FUNCTION public.get_most_copied_coupons(
  limit_count INTEGER DEFAULT 6
)
RETURNS SETOF public.coupons
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT c.*
  FROM public.coupons AS c
  INNER JOIN (
    SELECT
      coupon_id,
      COUNT(*) AS copy_count,
      MAX(created_at) AS last_copied_at
    FROM public.coupon_usage_events
    WHERE event_type = 'copy'
    GROUP BY coupon_id
  ) AS usage ON c.id::TEXT = usage.coupon_id
  WHERE COALESCE(c.approval_status, 'approved') = 'approved'
    AND public.is_not_expired(c.expiry_date)
  ORDER BY usage.copy_count DESC, usage.last_copied_at DESC
  LIMIT GREATEST(1, LEAST(limit_count, 24));
$$;

GRANT EXECUTE ON FUNCTION public.get_most_copied_coupons(INTEGER)
TO anon, authenticated;

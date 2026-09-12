-- Most copied coupons ranking.
-- Run this in Supabase SQL Editor after coupon_card_details_schema.sql.

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
  ORDER BY usage.copy_count DESC, usage.last_copied_at DESC
  LIMIT GREATEST(1, LEAST(limit_count, 24));
$$;

GRANT EXECUTE ON FUNCTION public.get_most_copied_coupons(INTEGER)
TO anon, authenticated;

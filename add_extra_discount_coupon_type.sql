-- Allow the extra discount coupon type in the existing Supabase database.

ALTER TABLE public.coupons
DROP CONSTRAINT IF EXISTS coupons_coupon_type_check;

ALTER TABLE public.coupons
ADD CONSTRAINT coupons_coupon_type_check
CHECK (coupon_type IN ('coupon', 'cashback', 'offer', 'extra_discount'));
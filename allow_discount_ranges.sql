-- Preserve existing discount values and allow ranges such as 5 - 10.

ALTER TABLE public.coupons
ALTER COLUMN discount_percent TYPE TEXT
USING discount_percent::TEXT;
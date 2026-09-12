-- Coupon card details and engagement schema.
-- Run in Supabase SQL Editor on the public schema.

ALTER TABLE public.coupons
ADD COLUMN IF NOT EXISTS discount_percent TEXT;

ALTER TABLE public.coupons
ADD COLUMN IF NOT EXISTS coupon_type TEXT NOT NULL DEFAULT 'coupon';

ALTER TABLE public.coupons
ADD COLUMN IF NOT EXISTS terms_ar TEXT;

ALTER TABLE public.coupons
ADD COLUMN IF NOT EXISTS terms_en TEXT;

ALTER TABLE public.coupons
ADD COLUMN IF NOT EXISTS is_active BOOLEAN NOT NULL DEFAULT TRUE;

ALTER TABLE public.coupons
ADD COLUMN IF NOT EXISTS last_used_at TIMESTAMP WITH TIME ZONE;

DO $$
BEGIN
  ALTER TABLE public.coupons
  DROP CONSTRAINT IF EXISTS coupons_coupon_type_check;

  ALTER TABLE public.coupons
  ADD CONSTRAINT coupons_coupon_type_check
  CHECK (coupon_type IN ('coupon', 'cashback', 'offer', 'extra_discount'));
END $$;

CREATE INDEX IF NOT EXISTS idx_coupons_coupon_type
ON public.coupons (coupon_type);

CREATE INDEX IF NOT EXISTS idx_coupons_is_active
ON public.coupons (is_active);

CREATE INDEX IF NOT EXISTS idx_coupons_last_used_at
ON public.coupons (last_used_at DESC);

CREATE TABLE IF NOT EXISTS public.coupon_usage_events (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  coupon_id TEXT NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  event_type TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.coupon_usage_events
ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'coupon_usage_events_event_type_check'
  ) THEN
    ALTER TABLE public.coupon_usage_events
    ADD CONSTRAINT coupon_usage_events_event_type_check
    CHECK (event_type IN ('copy', 'shop_now', 'share'));
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_coupon_usage_events_coupon_id
ON public.coupon_usage_events (coupon_id);

CREATE INDEX IF NOT EXISTS idx_coupon_usage_events_created_at
ON public.coupon_usage_events (created_at DESC);

CREATE OR REPLACE FUNCTION public.update_coupon_last_used_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE public.coupons
  SET last_used_at = NEW.created_at
  WHERE id::TEXT = NEW.coupon_id;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_update_coupon_last_used_at
ON public.coupon_usage_events;

CREATE TRIGGER trg_update_coupon_last_used_at
AFTER INSERT ON public.coupon_usage_events
FOR EACH ROW
EXECUTE FUNCTION public.update_coupon_last_used_at();

DROP POLICY IF EXISTS "Anyone can insert coupon usage events"
ON public.coupon_usage_events;

CREATE POLICY "Anyone can insert coupon usage events"
ON public.coupon_usage_events
FOR INSERT
WITH CHECK (true);

DROP POLICY IF EXISTS "Admins can view coupon usage events"
ON public.coupon_usage_events;

CREATE POLICY "Admins can view coupon usage events"
ON public.coupon_usage_events
FOR SELECT
USING (
  EXISTS (
    SELECT 1
    FROM public.admins
    WHERE admins.user_id = auth.uid()
  )
);

CREATE TABLE IF NOT EXISTS public.store_follows (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  store_id TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, store_id)
);

ALTER TABLE public.store_follows
ENABLE ROW LEVEL SECURITY;

CREATE INDEX IF NOT EXISTS idx_store_follows_user_id
ON public.store_follows (user_id);

CREATE INDEX IF NOT EXISTS idx_store_follows_store_id
ON public.store_follows (store_id);

DROP POLICY IF EXISTS "Users can view their own store follows"
ON public.store_follows;

CREATE POLICY "Users can view their own store follows"
ON public.store_follows
FOR SELECT
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can follow stores"
ON public.store_follows;

CREATE POLICY "Users can follow stores"
ON public.store_follows
FOR INSERT
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can unfollow stores"
ON public.store_follows;

CREATE POLICY "Users can unfollow stores"
ON public.store_follows
FOR DELETE
USING (auth.uid() = user_id);

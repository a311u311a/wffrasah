DROP POLICY IF EXISTS "Users can view their own coupon usage events"
ON public.coupon_usage_events;

CREATE POLICY "Users can view their own coupon usage events"
ON public.coupon_usage_events
FOR SELECT
USING (auth.uid() = user_id);

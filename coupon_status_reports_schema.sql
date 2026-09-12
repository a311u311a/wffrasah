CREATE TABLE IF NOT EXISTS public.coupon_status_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  coupon_id TEXT NOT NULL,
  user_id UUID NULL REFERENCES auth.users(id) ON DELETE SET NULL,
  status TEXT NOT NULL CHECK (status IN ('working', 'not_working')),
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_coupon_status_reports_coupon_id
ON public.coupon_status_reports (coupon_id);

CREATE INDEX IF NOT EXISTS idx_coupon_status_reports_status_created_at
ON public.coupon_status_reports (status, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_coupon_status_reports_user_id
ON public.coupon_status_reports (user_id);

ALTER TABLE public.coupon_status_reports ENABLE ROW LEVEL SECURITY;

GRANT SELECT ON public.coupon_status_reports TO authenticated;
GRANT INSERT ON public.coupon_status_reports TO anon, authenticated;
GRANT DELETE ON public.coupon_status_reports TO authenticated;

DROP POLICY IF EXISTS "Admins can view coupon status reports"
ON public.coupon_status_reports;

CREATE POLICY "Admins can view coupon status reports"
ON public.coupon_status_reports
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.admins
    WHERE admins.user_id = auth.uid()
  )
);

DROP POLICY IF EXISTS "Users can insert coupon status reports"
ON public.coupon_status_reports;

CREATE POLICY "Users can insert coupon status reports"
ON public.coupon_status_reports
FOR INSERT
TO anon, authenticated
WITH CHECK (
  auth.uid() IS NULL OR user_id IS NULL OR user_id = auth.uid()
);

DROP POLICY IF EXISTS "Admins can delete coupon status reports"
ON public.coupon_status_reports;

CREATE POLICY "Admins can delete coupon status reports"
ON public.coupon_status_reports
FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.admins
    WHERE admins.user_id = auth.uid()
  )
);

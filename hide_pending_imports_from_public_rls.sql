-- Hide automated imports that are still waiting for approval from the public app.
-- Admin users keep access so the approval screen can still show pending records.
-- Run this once in the Supabase SQL Editor.

ALTER TABLE public.stores ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.coupons ENABLE ROW LEVEL SECURITY;

DO $$
DECLARE
  policy_record record;
BEGIN
  FOR policy_record IN
    SELECT policyname
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'stores'
      AND cmd = 'SELECT'
  LOOP
    EXECUTE format(
      'DROP POLICY IF EXISTS %I ON public.stores',
      policy_record.policyname
    );
  END LOOP;

  FOR policy_record IN
    SELECT policyname
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'coupons'
      AND cmd = 'SELECT'
  LOOP
    EXECUTE format(
      'DROP POLICY IF EXISTS %I ON public.coupons',
      policy_record.policyname
    );
  END LOOP;
END $$;

CREATE POLICY "Public can view approved stores"
ON public.stores
FOR SELECT
TO anon, authenticated
USING (COALESCE(approval_status, 'approved') = 'approved');

CREATE POLICY "Admins can view all stores"
ON public.stores
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.admins
    WHERE admins.user_id = auth.uid()
  )
);

CREATE POLICY "Public can view approved coupons"
ON public.coupons
FOR SELECT
TO anon, authenticated
USING (COALESCE(approval_status, 'approved') = 'approved');

CREATE POLICY "Admins can view all coupons"
ON public.coupons
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.admins
    WHERE admins.user_id = auth.uid()
  )
);

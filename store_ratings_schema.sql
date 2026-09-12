CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS public.store_ratings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  store_id TEXT NOT NULL,
  rating INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, store_id)
);

ALTER TABLE public.store_ratings
ENABLE ROW LEVEL SECURITY;

GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT ON public.store_ratings TO anon, authenticated;
GRANT INSERT, UPDATE ON public.store_ratings TO authenticated;

CREATE INDEX IF NOT EXISTS idx_store_ratings_store_id
ON public.store_ratings (store_id);

CREATE INDEX IF NOT EXISTS idx_store_ratings_user_store
ON public.store_ratings (user_id, store_id);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'store_ratings'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.store_ratings;
  END IF;
END $$;

CREATE OR REPLACE FUNCTION public.set_store_ratings_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS set_store_ratings_updated_at
ON public.store_ratings;

CREATE TRIGGER set_store_ratings_updated_at
BEFORE UPDATE ON public.store_ratings
FOR EACH ROW
EXECUTE FUNCTION public.set_store_ratings_updated_at();

DROP POLICY IF EXISTS "Public can view store ratings"
ON public.store_ratings;

CREATE POLICY "Public can view store ratings"
ON public.store_ratings
FOR SELECT
TO anon, authenticated
USING (true);

DROP POLICY IF EXISTS "Users can insert own store rating"
ON public.store_ratings;

CREATE POLICY "Users can insert own store rating"
ON public.store_ratings
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own store rating"
ON public.store_ratings;

CREATE POLICY "Users can update own store rating"
ON public.store_ratings
FOR UPDATE
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

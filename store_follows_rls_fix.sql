CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS public.store_follows (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  store_id TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, store_id)
);

ALTER TABLE public.store_follows
ENABLE ROW LEVEL SECURITY;

GRANT USAGE ON SCHEMA public TO authenticated;
GRANT SELECT, INSERT, DELETE ON public.store_follows TO authenticated;

CREATE INDEX IF NOT EXISTS idx_store_follows_user_id
ON public.store_follows (user_id);

CREATE INDEX IF NOT EXISTS idx_store_follows_store_id
ON public.store_follows (store_id);

DROP POLICY IF EXISTS "Users can view their own store follows"
ON public.store_follows;

CREATE POLICY "Users can view their own store follows"
ON public.store_follows
FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can follow stores"
ON public.store_follows;

CREATE POLICY "Users can follow stores"
ON public.store_follows
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can unfollow stores"
ON public.store_follows;

CREATE POLICY "Users can unfollow stores"
ON public.store_follows
FOR DELETE
TO authenticated
USING (auth.uid() = user_id);

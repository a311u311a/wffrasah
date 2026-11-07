-- Broadcast store inserts/updates/deletes so the app and website show a
-- hidden (empty) category as soon as a store is added to it.
alter publication supabase_realtime add table public.stores;

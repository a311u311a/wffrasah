-- Refresh the 18 AliExpress categories (public.ali_categories) every 6 hours,
-- in three batches by sort_order so no single run nears the edge-function
-- time limit. Runs 10, 20 and 30 minutes after the store-category sync
-- (aliexpress-sync-daily at minute 0), i.e. 03:10/03:20/03:30 Riyadh time etc.
-- Uses the same ali_sync_token Vault secret as ali_products_cron.sql.

create extension if not exists pg_cron;
create extension if not exists pg_net;

do $$
declare
  batch record;
begin
  for batch in
    select * from (values
      ('aliexpress-sync-ali-1', '10 */6 * * *', 1, 6),
      ('aliexpress-sync-ali-2', '20 */6 * * *', 7, 12),
      ('aliexpress-sync-ali-3', '30 */6 * * *', 13, 18)
    ) as b(name, schedule, from_order, to_order)
  loop
    perform cron.unschedule(batch.name)
    where exists (select 1 from cron.job where jobname = batch.name);

    perform cron.schedule(
      batch.name,
      batch.schedule,
      format($job$
        select net.http_post(
          url := 'https://ilfbqykxkjructxunuxm.supabase.co/functions/v1/aliexpress-sync',
          headers := jsonb_build_object(
            'Content-Type', 'application/json',
            'x-sync-token', (select decrypted_secret from vault.decrypted_secrets where name = 'ali_sync_token')
          ),
          body := jsonb_build_object('source', 'ali', 'from_order', %s, 'to_order', %s),
          timeout_milliseconds := 150000
        );
      $job$, batch.from_order, batch.to_order)
    );
  end loop;
end $$;

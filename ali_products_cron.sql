-- Refresh AliExpress products every 6 hours: 03:00, 09:00, 15:00, 21:00
-- Riyadh time (00/06/12/18 UTC). For once a day use '0 0 * * *'.
--
-- Prerequisite (run once, not stored here): put the same value as the
-- ALI_SYNC_TOKEN edge-function secret into Vault:
--   select vault.create_secret('<token>', 'ali_sync_token');

create extension if not exists pg_cron;
create extension if not exists pg_net;

select cron.unschedule('aliexpress-sync-daily')
where exists (select 1 from cron.job where jobname = 'aliexpress-sync-daily');

select cron.schedule(
  'aliexpress-sync-daily',
  '0 */6 * * *',
  $$
  select net.http_post(
    url := 'https://ilfbqykxkjructxunuxm.supabase.co/functions/v1/aliexpress-sync',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-sync-token', (select decrypted_secret from vault.decrypted_secrets where name = 'ali_sync_token')
    ),
    body := '{}'::jsonb,
    timeout_milliseconds := 120000
  );
  $$
);

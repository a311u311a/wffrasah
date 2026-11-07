-- Refresh the 18 AliExpress categories (public.ali_categories) every 6 hours,
-- in three batches by sort_order so no single run nears the edge-function
-- time limit. Runs 10, 20 and 30 minutes after the store-category sync
-- (aliexpress-sync-daily at minute 0), i.e. 03:10/03:20/03:30 Riyadh time etc.
-- Uses the same ali_sync_token Vault secret as ali_products_cron.sql.
-- cron.schedule with an existing job name updates that job, so re-running is safe.

select cron.schedule(
  'aliexpress-sync-ali-1',
  '10 */6 * * *',
  $job$
  select net.http_post(
    url := 'https://ilfbqykxkjructxunuxm.supabase.co/functions/v1/aliexpress-sync',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-sync-token', (select decrypted_secret from vault.decrypted_secrets where name = 'ali_sync_token')
    ),
    body := '{"source": "ali", "from_order": 1, "to_order": 6}'::jsonb,
    timeout_milliseconds := 150000
  );
  $job$
);

select cron.schedule(
  'aliexpress-sync-ali-2',
  '20 */6 * * *',
  $job$
  select net.http_post(
    url := 'https://ilfbqykxkjructxunuxm.supabase.co/functions/v1/aliexpress-sync',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-sync-token', (select decrypted_secret from vault.decrypted_secrets where name = 'ali_sync_token')
    ),
    body := '{"source": "ali", "from_order": 7, "to_order": 12}'::jsonb,
    timeout_milliseconds := 150000
  );
  $job$
);

select cron.schedule(
  'aliexpress-sync-ali-3',
  '30 */6 * * *',
  $job$
  select net.http_post(
    url := 'https://ilfbqykxkjructxunuxm.supabase.co/functions/v1/aliexpress-sync',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-sync-token', (select decrypted_secret from vault.decrypted_secrets where name = 'ali_sync_token')
    ),
    body := '{"source": "ali", "from_order": 13, "to_order": 18}'::jsonb,
    timeout_milliseconds := 150000
  );
  $job$
);

-- Check: should list the three aliexpress-sync-ali-* jobs.
select jobname, schedule, active from cron.job
where jobname like 'aliexpress-sync%' order by jobname;

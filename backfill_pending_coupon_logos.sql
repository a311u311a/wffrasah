-- Backfill pending automated coupons with a fallback logo from their website.
-- This uses Google's public favicon endpoint as a lightweight logo fallback.

UPDATE public.coupons
SET image = 'https://www.google.com/s2/favicons?domain=' ||
  regexp_replace(
    regexp_replace(
      regexp_replace(web, '^https?://', ''),
      '^www\.',
      ''
    ),
    '/.*$',
    ''
  ) ||
  '&sz=256'
WHERE approval_status = 'waiting_approval'
  AND import_source <> 'manual'
  AND COALESCE(image, '') = ''
  AND COALESCE(web, '') <> '';

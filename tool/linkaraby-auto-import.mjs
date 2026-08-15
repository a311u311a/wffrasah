import fs from 'node:fs/promises';
import path from 'node:path';
import { createRequire } from 'node:module';

const require = createRequire(import.meta.url);

function loadPlaywright() {
  const candidates = [
    process.env.PLAYWRIGHT_MODULE_PATH,
    '/Users/max/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright',
    'playwright',
  ].filter(Boolean);

  for (const candidate of candidates) {
    try {
      return require(candidate);
    } catch {
      // Try the next runtime location.
    }
  }

  throw new Error('Playwright is not available. Install it with: npm install playwright');
}

const { chromium } = loadPlaywright();

const ROOT = path.resolve(path.dirname(new URL(import.meta.url).pathname), '..');
const PROFILE_DIR = process.env.LINKARABY_PROFILE_DIR ||
  path.join(ROOT, '.linkaraby-browser');
const DEFAULT_URL =
  'https://www.linkaraby.com/affiliates/panel.php#Campaigns-List-Wide';

function parseEnv(text) {
  const env = {};
  for (const line of text.split(/\r?\n/)) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) continue;
    const index = trimmed.indexOf('=');
    if (index === -1) continue;
    env[trimmed.slice(0, index)] = trimmed.slice(index + 1);
  }
  return env;
}

function clean(value) {
  return String(value ?? '').replace(/\s+/g, ' ').trim();
}

function slugify(value) {
  return clean(value)
    .toLowerCase()
    .replace(/^https?:\/\//, '')
    .replace(/^www\./, '')
    .replace(/\s+/g, '-')
    .replace(/[^a-z0-9\u0600-\u06FF-]/g, '-')
    .replace(/-+/g, '-')
    .replace(/^-|-$/g, '') || 'linkaraby-store';
}

async function loadEnv() {
  const text = await fs.readFile(path.join(ROOT, '.env'), 'utf8');
  return { ...parseEnv(text), ...process.env };
}

async function importPayload(payload, env) {
  const endpoint = `${env.SUPABASE_URL}/functions/v1/omolaat-coupons-import`;
  const response = await fetch(endpoint, {
    method: 'POST',
    headers: {
      apikey: env.SUPABASE_ANON_KEY,
      Authorization: `Bearer ${env.SUPABASE_ANON_KEY}`,
      'Content-Type': 'application/json',
      'x-omolaat-import-token': env.OMOLAAT_IMPORT_TOKEN,
    },
    body: JSON.stringify(payload),
  });

  const text = await response.text();
  let result;
  try {
    result = JSON.parse(text);
  } catch {
    result = text;
  }

  if (!response.ok) {
    throw new Error(JSON.stringify(result));
  }

  return result;
}

async function scrollPage(page) {
  let previousHeight = 0;
  for (let index = 0; index < 20; index += 1) {
    const height = await page.evaluate(() => document.body.scrollHeight);
    if (height === previousHeight) break;
    previousHeight = height;
    await page.mouse.wheel(0, 1200);
    await page.waitForTimeout(600);
  }
  await page.evaluate(() => window.scrollTo(0, 0)).catch(() => {});
}

async function extractCampaignCoupons(page) {
  return await page.evaluate(() => {
    const clean = (value) => String(value ?? '').replace(/\s+/g, ' ').trim();
    const looksLikeCode = (value) =>
      /^[A-Z0-9][A-Z0-9_-]{3,30}$/i.test(clean(value)) &&
      !/^(HTTP|HTTPS|WWW|SAR|USD|AED|KSA)$/i.test(clean(value));

    const findCode = (text) => {
      const labeled = clean(text).match(
        /(?:كوبون\s+(?:الخصم|التخفيض)\s+(?:هو|هو:)?|كود\s+(?:الخصم|التخفيض)\s+(?:هو|هو:)?|coupon\s+code|promo\s+code|voucher\s+code|code)\s*[:：-]?\s*([A-Z0-9][A-Z0-9_-]{3,30})/i,
      );
      if (labeled?.[1] && looksLikeCode(labeled[1])) return labeled[1].toUpperCase();
      return '';
    };

    const findDiscount = (text) => {
      const match = clean(text).match(
        /(?:خصم|discount|off|up to|حتى)\s*[:：-]?\s*([0-9٠-٩]+(?:\s?[%٪]| ?(?:ريال|sar|usd|aed))?)/i,
      );
      return clean(match?.[1] || '');
    };

    const findUrl = (element) => {
      const anchor = [...element.querySelectorAll('a')]
        .map((link) => link.href)
        .find((href) => href && !href.includes('javascript:'));
      if (anchor) return anchor;

      const text = clean(element.innerText);
      const match = text.match(/https?:\/\/[^\s]+|(?:[a-z0-9-]+\.)+[a-z]{2,}(?:\/[^\s]*)?/i);
      if (!match) return '';
      const url = match[0];
      return /^https?:\/\//i.test(url) ? url : `https://${url}`;
    };

    const findImage = (element) => {
      const image = [...element.querySelectorAll('img')]
        .map((img) => img.currentSrc || img.src)
        .find((src) => src && !src.startsWith('data:'));
      return image || '';
    };

    const firstUsefulLine = (lines) => {
      const ignored = /^(active|inactive|details|view|join|apply|copy|coupon|code|كوبون|كود|تفاصيل|نسخ|عرض|انضم|تفعيل)$/i;
      return lines.find((line) =>
        line.length >= 2 &&
        line.length <= 80 &&
        !looksLikeCode(line) &&
        !ignored.test(line) &&
        !/https?:\/\/|www\.|@/.test(line)
      ) || '';
    };

    const tableRows = [...document.querySelectorAll('tr')];
    const containers = tableRows.length > 0
      ? tableRows
      : [
          ...document.querySelectorAll('.card, .campaign, [class*="campaign"], [class*="Campaign"], [class*="offer"], [class*="coupon"]'),
        ];
    const seenElements = new Set();
    const coupons = [];

    for (const element of containers) {
      if (seenElements.has(element)) continue;
      seenElements.add(element);
      const text = clean(element.innerText);
      if (!text || text.length < 8) continue;

      const code = findCode(text);
      if (!code) continue;

      const lines = element.innerText.split('\n').map(clean).filter(Boolean);
      const storeName = firstUsefulLine(lines) || code;
      const url = findUrl(element);
      const discount = findDiscount(text);
      const image = findImage(element);

      coupons.push({
        import_source: 'linkaraby',
        source_coupon_id: `${storeName}:${code}`,
        store_id: storeName,
        store_name_ar: storeName,
        store_name_en: '',
        store_description_ar: '',
        store_description_en: '',
        store_image: image,
        category_name: '',
        code,
        discount: discount || `كوبون ${storeName}`,
        web: url,
        affiliate_url: url,
        expiry_date: null,
        tags: [],
      });
    }

    return coupons;
  });
}

async function main() {
  const env = await loadEnv();
  for (const key of ['SUPABASE_URL', 'SUPABASE_ANON_KEY', 'OMOLAAT_IMPORT_TOKEN']) {
    if (!env[key]) throw new Error(`Missing ${key} in .env`);
  }

  const headed = process.argv.includes('--headed') || process.argv.includes('--login');
  const loginOnly = process.argv.includes('--login');
  const context = await chromium.launchPersistentContext(PROFILE_DIR, {
    headless: !headed,
    executablePath: process.env.CHROME_EXECUTABLE_PATH ||
      '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
    locale: 'ar-SA',
    viewport: { width: 1440, height: 1000 },
  });
  const page = context.pages()[0] || (await context.newPage());

  await page.goto(DEFAULT_URL, { waitUntil: 'domcontentloaded' });
  await page.waitForLoadState('networkidle', { timeout: 30000 }).catch(() => {});

  if (loginOnly) {
    console.log('Chrome opened. Log in to LinkAraby, then close the window.');
    await page.waitForTimeout(60 * 60 * 1000);
    return;
  }

  const pageText = await page.locator('body').innerText({ timeout: 15000 });
  const isLoginPage =
    /login|signin|sign-in/i.test(page.url()) ||
    (/كلمة المرور|password/i.test(pageText) &&
      /تسجيل الدخول|دخول|login|sign in/i.test(pageText) &&
      !/الحملات|العمولات|Affiliate Panel/i.test(pageText));

  if (isLoginPage) {
    throw new Error(
      'LinkAraby session is not ready. Run with --login first and sign in.',
    );
  }

  await scrollPage(page);

  const coupons = await extractCampaignCoupons(page);
  const uniqueCoupons = [
    ...new Map(
      coupons.map((coupon) => [
        `${slugify(coupon.store_id)}:${coupon.code || coupon.web}`,
        { ...coupon, store_id: slugify(coupon.store_id) },
      ]),
    ).values(),
  ];

  const payload = { import_source: 'linkaraby', coupons: uniqueCoupons };
  const outDir = path.join(ROOT, '.linkaraby-runs');
  await fs.mkdir(outDir, { recursive: true });
  const outPath = path.join(outDir, `linkaraby-${Date.now()}.json`);
  await fs.writeFile(outPath, JSON.stringify(payload, null, 2));

  const result = await importPayload(payload, env);
  console.log(
    JSON.stringify(
      {
        payload: outPath,
        extracted_coupons: uniqueCoupons.length,
        ...result,
      },
      null,
      2,
    ),
  );

  await context.close();
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});

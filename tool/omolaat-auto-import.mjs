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
const PROFILE_DIR = process.env.OMOLAAT_PROFILE_DIR ||
  path.join(ROOT, '.omolaat-browser');
const DEFAULT_URL = 'https://my.omolaat.com/affiliate/My%20Stores';

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

async function extractCurrentStore(page) {
  return await page.evaluate(() => {
    const clean = (value) => String(value ?? '').replace(/\s+/g, ' ').trim();
    const pageText = clean(document.body.innerText);
    const lines = document.body.innerText
      .split('\n')
      .map(clean)
      .filter(Boolean);

    const readAfterLabel = (label) => {
      const index = lines.findIndex((line) => line.includes(label));
      if (index === -1) return '';
      return lines[index + 1] || '';
    };

    const firstMatch = (...patterns) => {
      for (const pattern of patterns) {
        const match = pageText.match(pattern);
        if (match?.[1]) return clean(match[1]);
      }
      return '';
    };

    const isStoreName = (value) => {
      const text = clean(value);
      if (!text) return false;
      if (/[./]/.test(text)) return false;
      if (text.length > 40) return false;
      if (
        /^(رابط المتجر|التصنيف|نبذة عن المتجر|كوبوناتي|تحت التفعيل)$/.test(
          text,
        )
      ) {
        return false;
      }
      return /[\u0600-\u06FF]/.test(text);
    };

    const storeLinkIndex = lines.findIndex((line) =>
      line.includes('رابط المتجر'),
    );
    const nearbyStoreName =
      storeLinkIndex >= 0
        ? lines
            .slice(Math.max(0, storeLinkIndex - 8), storeLinkIndex)
            .reverse()
            .find(isStoreName) || ''
        : '';
    const selectedStore =
      document.querySelector('[role="combobox"]')?.innerText ||
      document.querySelector('button[aria-haspopup="listbox"]')?.innerText ||
      '';
    const selectedStoreName = isStoreName(selectedStore)
      ? clean(selectedStore).split(' ')[0]
      : '';
    const storeName =
      selectedStoreName ||
      nearbyStoreName ||
      firstMatch(/متجر\s+([^\s]+)/) ||
      '';
    const storeUrl = firstMatch(/([a-z0-9-]+\.[a-z]{2,}(?:\/[^\s]*)?)/i);

    const readCouponCode = () => {
      const direct = firstMatch(
        /كوبوناتي المسجلة\s*\(\d+\)\s*([A-Z0-9_-]+)/i,
        /([A-Z]{2,}[A-Z0-9_-]*)\s*تحت التفعيل/i,
      );
      if (direct) return direct;

      const activeIndex = lines.findIndex((line) =>
        line.includes('تحت التفعيل'),
      );
      const windowText = lines
        .slice(Math.max(0, activeIndex - 4), activeIndex + 4)
        .join(' ');
      const match = windowText.match(/\b([A-Z]{2,}[A-Z0-9_-]{2,})\b/i);
      return match?.[1] || '';
    };

    const category = readAfterLabel('التصنيف');
    const storeDescription = readAfterLabel('نبذة عن المتجر');
    const expiryDate = firstMatch(
      /تاريخ الانتهاء\s*([0-9]{4}-[0-9]{2}-[0-9]{2})/,
    );
    const couponCode = readCouponCode();

    return {
      store_id: storeName ? storeName.toLowerCase().replace(/\s+/g, '-') : '',
      store_name_ar: storeName,
      store_name_en: '',
      store_description_ar: storeDescription,
      store_description_en: '',
      store_image: '',
      category_name: category,
      code: couponCode,
      discount: firstMatch(/خصم الكوبون\s*([0-9٠-٩]+%)/),
      web: storeUrl ? `https://${storeUrl.replace(/^https?:\/\//, '')}` : '',
      affiliate_url: '',
      expiry_date: expiryDate || null,
      tags: category ? [category] : [],
    };
  });
}

async function collectStoreOptions(page) {
  const triggers = [
    page.locator('[role="combobox"]'),
    page.locator('button[aria-haspopup="listbox"]'),
    page.locator('.clickable-element').filter({ hasText: /^[\u0600-\u06FF\s]{2,40}$/ }),
    page.locator('.clickable-element'),
  ];

  for (const candidates of triggers) {
    const triggerCount = await candidates.count().catch(() => 0);
    for (let triggerIndex = 0; triggerIndex < triggerCount; triggerIndex += 1) {
      const trigger = candidates.nth(triggerIndex);
      if (!(await trigger.isVisible().catch(() => false))) continue;

      try {
        await trigger.click({ timeout: 3000 });
      await page.waitForTimeout(900);

      const stores = new Set();
      const readVisibleOptions = async () => {
        const options = await page
          .locator('[role="option"], [role="listbox"] *')
          .evaluateAll((nodes) =>
            nodes
              .map((node) => node.textContent?.trim())
              .filter(Boolean),
          )
          .catch(() => []);
        const bodyLines = await page
          .locator('body')
          .innerText({ timeout: 3000 })
          .then((text) => text.split('\n'))
          .catch(() => []);

        for (const option of [...options, ...bodyLines]) {
          const text = clean(option);
          if (
            text &&
            text.length <= 60 &&
            !/[./]/.test(text) &&
            /[\u0600-\u06FF]/.test(text) &&
            !/^(ابحث عن متجر|نشط|غير نشط|الرئيسية|تصفح المتاجر|متاجري|أدائي|أرباحي|قناة تيليجرام|تواصل معنا|الإعدادات|تسجيل الخروج|رابط المتجر|التصنيف|نبذة عن المتجر|كوبوناتي المسجلة)$/.test(text) &&
            !/(الصفحة|العمولة|الكوبون|التأكيد|التسويق|المنتجات|منطقة|المستهدفة|مجدد|قيود|يجب|مهمة|عن المتجر)/.test(text)
          ) {
            stores.add(text);
          }
        }
      };

      await readVisibleOptions();

      for (let index = 0; index < 80; index += 1) {
        const before = stores.size;
        await page.mouse.wheel(0, 700);
        await page.keyboard.press('PageDown').catch(() => {});
        await page.waitForTimeout(250);
        await readVisibleOptions();
        if (stores.size === before) {
          await page.mouse.wheel(0, 1200);
          await page.keyboard.press('PageDown').catch(() => {});
          await page.waitForTimeout(250);
          await readVisibleOptions();
          if (stores.size === before) break;
        }
      }

      const normalizedStores = [...stores]
        .map((text) => text.replace(/\s+/g, ' ').trim())
        .filter(Boolean);
      await page.keyboard.press('Escape').catch(() => {});
      return normalizedStores;
      } catch {
        await page.keyboard.press('Escape').catch(() => {});
      }
    }
  }

  return [];
}

async function selectStore(page, storeName) {
  const triggerGroups = [
    page.locator('[role="combobox"]'),
    page.locator('button[aria-haspopup="listbox"]'),
    page.locator('.clickable-element').filter({ hasText: /^[\u0600-\u06FF\s]{2,40}$/ }),
    page.locator('.clickable-element'),
  ];
  let clicked = false;
  for (const candidates of triggerGroups) {
    const count = await candidates.count().catch(() => 0);
    for (let index = 0; index < count; index += 1) {
      const candidate = candidates.nth(index);
      if (!(await candidate.isVisible().catch(() => false))) continue;
      await candidate.click({ timeout: 5000 });
      clicked = true;
      break;
    }
    if (clicked) break;
  }
  if (!clicked) return false;
  await page.waitForTimeout(500);
  const options = page.getByText(storeName, { exact: true });
  const optionCount = await options.count();
  if (optionCount === 0) {
    await page.keyboard.press('Escape').catch(() => {});
    return false;
  }

  let optionClicked = false;
  for (let index = 0; index < optionCount; index += 1) {
    const option = options.nth(index);
    if (!(await option.isVisible().catch(() => false))) continue;
    await option.click({ timeout: 5000 });
    optionClicked = true;
    break;
  }

  if (!optionClicked) {
    await page.keyboard.press('Escape').catch(() => {});
    return false;
  }

  await page.waitForLoadState('networkidle', { timeout: 15000 }).catch(() => {});
  await page.waitForTimeout(1200);
  return true;
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
    console.log('Chrome opened. Log in to Omolaat, then close the window.');
    await page.waitForTimeout(60 * 60 * 1000);
    return;
  }

  const pageText = await page.locator('body').innerText({ timeout: 15000 });
  if (!/متاجري|كوبوناتي|رابط المتجر/.test(pageText)) {
    throw new Error(
      'Omolaat session is not ready. Run with --login first and sign in.',
    );
  }

  const storeOptions = await collectStoreOptions(page);
  const coupons = [];
  let storesWithoutCoupons = 0;

  if (storeOptions.length > 0) {
    for (const storeName of storeOptions) {
      const selected = await selectStore(page, storeName);
      if (!selected) continue;
      const coupon = await extractCurrentStore(page);
      if (coupon.code) {
        coupons.push(coupon);
      } else {
        storesWithoutCoupons += 1;
      }
    }
  } else {
    const coupon = await extractCurrentStore(page);
    if (coupon.code) {
      coupons.push(coupon);
    } else {
      storesWithoutCoupons += 1;
    }
  }

  const uniqueCoupons = [
    ...new Map(
      coupons.map((coupon) => [
        `${coupon.store_id}:${coupon.code || coupon.web}`,
        coupon,
      ]),
    ).values(),
  ];

  const payload = { coupons: uniqueCoupons };
  const outDir = path.join(ROOT, '.omolaat-runs');
  await fs.mkdir(outDir, { recursive: true });
  const outPath = path.join(outDir, `omolaat-${Date.now()}.json`);
  await fs.writeFile(outPath, JSON.stringify(payload, null, 2));

  const result = await importPayload(payload, env);
  console.log(
    JSON.stringify(
      {
        payload: outPath,
        discovered_stores: storeOptions.length,
        extracted_coupons: uniqueCoupons.length,
        stores_without_coupons: storesWithoutCoupons,
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

import fs from 'node:fs/promises';
import path from 'node:path';
import { spawn } from 'node:child_process';

const root = process.cwd();
const outDir = path.join(root, 'assets', 'social', 'stores');
const htmlPath = path.join(outDir, '_render.html');
const appLogo = path.join(root, 'assets', 'image', 'wffrhasah.png').replace(/\\/g, '/');
const fontRegular = path.join(root, 'assets', 'fonts', 'Tajawal-Regular.ttf').replace(/\\/g, '/');
const fontBold = path.join(root, 'assets', 'fonts', 'Tajawal-Bold.ttf').replace(/\\/g, '/');
const fontExtraBold = path.join(root, 'assets', 'fonts', 'Tajawal-ExtraBold.ttf').replace(/\\/g, '/');

const formats = {
  instagram_post: { width: 1080, height: 1350, label: 'instagram-post' },
  instagram_reel: { width: 1080, height: 1920, label: 'instagram-reel' },
  tiktok: { width: 1080, height: 1920, label: 'tiktok' },
  pinterest: { width: 1000, height: 1500, label: 'pinterest' },
};

function readEnv(text) {
  const env = {};
  for (const line of text.split(/\r?\n/)) {
    const match = line.match(/^([^#=\s]+)=(.*)$/);
    if (match) env[match[1]] = match[2].trim();
  }
  return env;
}

function escapeHtml(value) {
  return String(value ?? '')
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');
}

function safeName(value) {
  return String(value || 'store')
    .normalize('NFKD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^\w\u0600-\u06FF-]+/g, '-')
    .replace(/-+/g, '-')
    .replace(/^-|-$/g, '')
    .slice(0, 80) || 'store';
}

function pickCoupon(store, coupons) {
  const keys = new Set(
    [store.slug, store.id, store.store_id, store.store_uuid]
      .filter(Boolean)
      .map((v) => String(v).toLowerCase().trim()),
  );
  return coupons.find((coupon) => keys.has(String(coupon.store_id || '').toLowerCase().trim()));
}

function trimText(value, max) {
  const text = String(value || '').replace(/\s+/g, ' ').trim();
  if (text.length <= max) return text;
  return `${text.slice(0, max - 1).trim()}…`;
}

async function fetchImageDataUrl(url) {
  if (!url) return '';
  if (String(url).startsWith('data:') || String(url).startsWith('file:')) return url;
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), 12000);
  try {
    const res = await fetch(url, { signal: controller.signal });
    if (!res.ok) return '';
    const type = res.headers.get('content-type')?.split(';')[0] || 'image/png';
    const bytes = Buffer.from(await res.arrayBuffer());
    return `data:${type};base64,${bytes.toString('base64')}`;
  } catch {
    return '';
  } finally {
    clearTimeout(timer);
  }
}

function pageHtml(store, coupon, formatKey) {
  const f = formats[formatKey];
  const storeName = store.name_ar || store.name || store.name_en || store.slug;
  const description = trimText(
    coupon?.description_ar || coupon?.description || store.description_ar || store.description || `كوبونات وعروض ${storeName} في وفرها صح.`,
    f.height > 1600 ? 150 : 125,
  );
  const code = coupon?.code || 'تابع العروض';
  const logo = store.image || coupon?.image || '';
  const note = coupon ? 'كوبون خصم' : 'عروض المتجر';
  const action = formatKey === 'pinterest' ? 'احفظ العرض' : formatKey === 'tiktok' ? 'استخدم الكود' : 'تسوق بذكاء';
  const tall = f.height > 1600;

  return `<!doctype html>
<html lang="ar" dir="rtl">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=${f.width},height=${f.height},initial-scale=1">
<style>
@font-face{font-family:Tajawal;src:url("file:///${fontRegular}")}
@font-face{font-family:Tajawal;font-weight:700;src:url("file:///${fontBold}")}
@font-face{font-family:Tajawal;font-weight:800;src:url("file:///${fontExtraBold}")}
*{box-sizing:border-box}
html,body{width:${f.width}px;height:${f.height}px;margin:0;overflow:hidden;background:#111;font-family:Tajawal,Arial,sans-serif}
.board{position:relative;width:${f.width}px;height:${f.height}px;overflow:hidden;color:#fff;background:#111;isolation:isolate}
.brand-bg{position:absolute;inset:-90px;background:
  radial-gradient(circle at 18% 16%,rgba(255,212,42,.78),transparent 28%),
  radial-gradient(circle at 84% 24%,rgba(255,82,88,.62),transparent 26%),
  radial-gradient(circle at 70% 82%,rgba(38,187,255,.58),transparent 30%),
  linear-gradient(145deg,#171717,#060606 62%,#171717);
  filter:saturate(1.08)}
.logo-wash{position:absolute;inset:-120px;background-image:url("${escapeHtml(logo)}");background-size:52%;background-repeat:no-repeat;background-position:center 34%;filter:blur(42px) saturate(1.45);opacity:.43;transform:scale(1.22)}
.noise{position:absolute;inset:0;background:linear-gradient(180deg,rgba(0,0,0,.05),rgba(0,0,0,.8));z-index:1}
.top{position:absolute;z-index:5;top:${tall ? 58 : 44}px;left:${tall ? 58 : 48}px;right:${tall ? 58 : 48}px;display:flex;align-items:center;justify-content:flex-start;direction:ltr;gap:16px}
.app-logo{width:${tall ? 86 : 78}px;height:${tall ? 86 : 78}px;border-radius:24px;box-shadow:0 16px 38px rgba(0,0,0,.34)}
.app-name{font-size:${tall ? 32 : 29}px;font-weight:800;line-height:1;color:#fff;text-align:left}
.app-tag{margin-top:8px;font-size:${tall ? 20 : 18}px;font-weight:500;color:rgba(255,255,255,.86);text-align:left}
.mark{position:absolute;z-index:4;top:${tall ? 190 : 150}px;right:${tall ? 68 : 54}px;padding:12px 23px;border-radius:999px;background:#fff;color:#111;font-size:${tall ? 29 : 25}px;font-weight:800;box-shadow:0 12px 28px rgba(0,0,0,.22)}
.store-logo-wrap{position:absolute;z-index:4;left:50%;top:${tall ? 365 : 275}px;transform:translateX(-50%);width:${tall ? 330 : 288}px;height:${tall ? 330 : 288}px;border-radius:44px;background:rgba(255,255,255,.94);display:grid;place-items:center;box-shadow:0 28px 76px rgba(0,0,0,.38);padding:28px}
.store-logo{max-width:100%;max-height:100%;object-fit:contain}
.content{position:absolute;z-index:5;left:${tall ? 70 : 58}px;right:${tall ? 70 : 58}px;bottom:${tall ? 150 : 76}px;text-align:right}
.store-name{font-size:${tall ? 74 : 62}px;line-height:1.08;font-weight:800;margin:0 0 18px;text-wrap:balance}
.desc{font-size:${tall ? 36 : 31}px;line-height:1.35;font-weight:700;margin:0 0 34px;color:rgba(255,255,255,.94)}
.coupon-row{display:flex;direction:rtl;align-items:center;gap:18px;justify-content:space-between}
.coupon{min-width:0;flex:1;border:3px dashed rgba(255,255,255,.72);border-radius:32px;background:rgba(0,0,0,.42);backdrop-filter:blur(10px);padding:${tall ? '24px 30px' : '21px 27px'};box-shadow:inset 0 0 0 1px rgba(255,255,255,.12)}
.coupon-label{font-size:${tall ? 24 : 21}px;color:rgba(255,255,255,.76);font-weight:700;margin-bottom:8px}
.coupon-code{direction:ltr;text-align:center;font-size:${tall ? 55 : 47}px;line-height:1;font-weight:800;letter-spacing:0;color:#fff;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.cta{white-space:nowrap;border-radius:999px;background:#ffd42a;color:#111;padding:${tall ? '24px 32px' : '21px 28px'};font-size:${tall ? 31 : 27}px;font-weight:800;box-shadow:0 14px 32px rgba(255,212,42,.25)}
.handle{margin-top:26px;direction:ltr;text-align:left;font-size:${tall ? 28 : 24}px;font-weight:800;color:rgba(255,255,255,.86)}
</style>
</head>
<body>
<main class="board">
  <div class="brand-bg"></div>
  <div class="logo-wash"></div>
  <div class="noise"></div>
  <header class="top">
    <img class="app-logo" src="file:///${appLogo}">
    <div>
      <div class="app-name">وفرها صح</div>
      <div class="app-tag">كوبونات وعروض مختارة</div>
    </div>
  </header>
  <div class="mark">${escapeHtml(note)}</div>
  <div class="store-logo-wrap"><img class="store-logo" src="${escapeHtml(logo)}"></div>
  <section class="content">
    <h1 class="store-name">${escapeHtml(storeName)}</h1>
    <p class="desc">${escapeHtml(description)}</p>
    <div class="coupon-row">
      <div class="coupon">
        <div class="coupon-label">الكوبون</div>
        <div class="coupon-code">${escapeHtml(code)}</div>
      </div>
      <div class="cta">${escapeHtml(action)}</div>
    </div>
    <div class="handle">@wffrhasah</div>
  </section>
</main>
</body>
</html>`;
}

async function fetchTable(url, key, table, order) {
  const res = await fetch(`${url}/rest/v1/${table}?select=*&order=${order}`, {
    headers: { apikey: key, Authorization: `Bearer ${key}` },
  });
  if (!res.ok) throw new Error(`${table} fetch failed: ${res.status} ${await res.text()}`);
  return res.json();
}

async function runChrome(chromePath, url, output, width, height) {
  const profileDir = await fs.mkdtemp(path.join(outDir, '.chrome-profile-'));
  try {
    await new Promise((resolve, reject) => {
    const args = [
      '--headless=new',
      '--disable-gpu',
      '--disable-background-networking',
      '--disable-extensions',
      '--no-first-run',
      '--no-default-browser-check',
      '--hide-scrollbars',
      '--disable-dev-shm-usage',
      '--allow-file-access-from-files',
      '--run-all-compositor-stages-before-draw',
      '--virtual-time-budget=5000',
      `--user-data-dir=${profileDir}`,
      `--window-size=${width},${height}`,
      `--screenshot=${output}`,
      url,
    ];
    const child = spawn(chromePath, args, { stdio: 'ignore' });
    const timer = setTimeout(() => {
      child.kill('SIGKILL');
      reject(new Error(`Chrome screenshot timed out for ${path.basename(output)}`));
    }, 30000);
    child.on('exit', (code) => {
      clearTimeout(timer);
      code === 0 ? resolve() : reject(new Error(`Chrome exited ${code}`));
    });
    child.on('error', (error) => {
      clearTimeout(timer);
      reject(error);
    });
  });
  } finally {
    await fs.rm(profileDir, { recursive: true, force: true }).catch(() => {});
  }
}

const env = readEnv(await fs.readFile(path.join(root, '.env'), 'utf8'));
if (!env.SUPABASE_URL || !env.SUPABASE_ANON_KEY) {
  throw new Error('Missing SUPABASE_URL or SUPABASE_ANON_KEY in .env');
}

await fs.mkdir(outDir, { recursive: true });
const [stores, coupons] = await Promise.all([
  fetchTable(env.SUPABASE_URL, env.SUPABASE_ANON_KEY, 'stores', 'name_ar.asc'),
  fetchTable(env.SUPABASE_URL, env.SUPABASE_ANON_KEY, 'coupons', 'created_at.desc'),
]);

const chromePath = process.env.CHROME_PATH || 'C:/Program Files/Google/Chrome/Application/chrome.exe';
let written = 0;
const manifest = [];

for (const store of stores) {
  const slug = safeName(store.slug || store.id || store.name_en || store.name_ar);
  const storeDir = path.join(outDir, slug);
  await fs.mkdir(storeDir, { recursive: true });
  const coupon = pickCoupon(store, coupons);
  const logoData = await fetchImageDataUrl(store.image || coupon?.image);
  const renderStore = { ...store, image: logoData || `file:///${appLogo}` };

  for (const [formatKey, format] of Object.entries(formats)) {
    await fs.writeFile(htmlPath, pageHtml(renderStore, coupon, formatKey), 'utf8');
    const output = path.join(storeDir, `${format.label}-${slug}-${format.width}x${format.height}.png`);
    const existing = await fs.stat(output).catch(() => null);
    if (existing?.size > 0) {
      written += 1;
      manifest.push({
        store: store.name_ar || store.name || slug,
        slug,
        format: format.label,
        width: format.width,
        height: format.height,
        coupon: coupon?.code || null,
        file: path.relative(root, output).replace(/\\/g, '/'),
      });
      continue;
    }
    await runChrome(chromePath, `file:///${htmlPath.replace(/\\/g, '/')}`, output, format.width, format.height);
    written += 1;
    manifest.push({
      store: store.name_ar || store.name || slug,
      slug,
      format: format.label,
      width: format.width,
      height: format.height,
      coupon: coupon?.code || null,
      file: path.relative(root, output).replace(/\\/g, '/'),
    });
  }
}

await fs.writeFile(path.join(outDir, 'manifest.json'), JSON.stringify({ generated_at: new Date().toISOString(), stores: stores.length, coupons: coupons.length, images: written, files: manifest }, null, 2), 'utf8');
await fs.rm(htmlPath, { force: true });
console.log(`Generated ${written} images for ${stores.length} stores in ${path.relative(root, outDir)}`);

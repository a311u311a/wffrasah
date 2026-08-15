import fs from 'node:fs/promises';
import path from 'node:path';
import { spawn } from 'node:child_process';

const root = process.cwd();
const outDir = path.join(root, 'assets', 'social', 'coupon-reference-style');
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
      .map((value) => String(value).toLowerCase().trim()),
  );
  return coupons.find((coupon) => keys.has(String(coupon.store_id || '').toLowerCase().trim()));
}

function trimText(value, max) {
  const text = String(value || '').replace(/\s+/g, ' ').trim();
  if (text.length <= max) return text;
  return `${text.slice(0, max - 1).trim()}...`;
}

function extractDiscount(description) {
  const text = String(description || '');
  const percent = text.match(/(\d+)\s*%/);
  if (percent) return `%${percent[1]}`;
  const arabicPercent = text.match(/([٠-٩]+)\s*%/);
  if (arabicPercent) return `%${arabicPercent[1]}`;
  const amount = text.match(/(\d+)\s*(ريال|ر\.س|RS|SAR)/i);
  if (amount) return `${amount[1]} ريال`;
  return 'خصم';
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

async function fetchTable(url, key, table, order) {
  const res = await fetch(`${url}/rest/v1/${table}?select=*&order=${order}`, {
    headers: { apikey: key, Authorization: `Bearer ${key}` },
  });
  if (!res.ok) throw new Error(`${table} fetch failed: ${res.status} ${await res.text()}`);
  return res.json();
}

function pageHtml(store, coupon, formatKey, logoData) {
  const format = formats[formatKey];
  const tall = format.height >= 1500;
  const scale = format.width / 1080;
  const storeName = store.name_ar || store.name || store.name_en || store.slug;
  const description = coupon?.description_ar || coupon?.description || store.description_ar || store.description || `كوبونات وعروض ${storeName}`;
  const discount = extractDiscount(description);
  const code = coupon?.code || 'وفرها صح';
  const shortDesc = trimText(description, tall ? 72 : 58);
  const brandTop = tall ? 46 : 34;
  const contentTop = tall ? 395 : 285;
  const couponBottom = tall ? 410 : 265;

  return `<!doctype html>
<html lang="ar" dir="rtl">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=${format.width},height=${format.height},initial-scale=1">
<style>
@font-face{font-family:Tajawal;src:url("file:///${fontRegular}")}
@font-face{font-family:Tajawal;font-weight:700;src:url("file:///${fontBold}")}
@font-face{font-family:Tajawal;font-weight:800;src:url("file:///${fontExtraBold}")}
*{box-sizing:border-box}
html,body{width:${format.width}px;height:${format.height}px;margin:0;overflow:hidden;background:#f8fbfd;font-family:Tajawal,"Segoe UI",Tahoma,Arial,sans-serif}
:root{--primary:#9bd900;--secondary:#075fae;--dark:#08345f;--muted:#657382}
.board{position:relative;width:${format.width}px;height:${format.height}px;overflow:hidden;background:linear-gradient(135deg,#fbfdff 0%,#f2f7fb 62%,#ffffff 100%);color:var(--dark);isolation:isolate}
.frame{position:absolute;inset:${Math.round(38 * scale)}px;border:${Math.max(2, Math.round(3 * scale))}px solid var(--secondary);border-radius:${Math.round(26 * scale)}px;opacity:.95;z-index:4}
.blob-top{position:absolute;width:${Math.round(660 * scale)}px;height:${Math.round(600 * scale)}px;border-radius:0 0 55% 55%;background:var(--primary);left:${Math.round(-160 * scale)}px;top:${Math.round(-150 * scale)}px;z-index:1}
.blob-bottom{position:absolute;width:${Math.round(560 * scale)}px;height:${Math.round(560 * scale)}px;border-radius:50%;background:var(--secondary);right:${Math.round(-210 * scale)}px;bottom:${Math.round(-210 * scale)}px;z-index:1}
.soft-white{position:absolute;width:${Math.round(360 * scale)}px;height:${Math.round(520 * scale)}px;border-radius:50%;background:rgba(255,255,255,.78);left:${Math.round(-90 * scale)}px;bottom:${Math.round(-120 * scale)}px;z-index:2}
.waves{position:absolute;right:${Math.round(70 * scale)}px;top:${tall ? 420 : 300}px;width:${Math.round(430 * scale)}px;height:${tall ? 760 : 560}px;z-index:2;opacity:.95}
.wave{position:absolute;right:0;width:100%;height:${Math.round(150 * scale)}px;border-top:${Math.round(8 * scale)}px solid var(--primary);border-radius:50% 50% 0 0}
.wave:nth-child(1){top:0}.wave:nth-child(2){top:${Math.round(145 * scale)}px}.wave:nth-child(3){top:${Math.round(290 * scale)}px}.wave:nth-child(4){top:${Math.round(435 * scale)}px}.wave:nth-child(5){top:${Math.round(580 * scale)}px}
.top-brand{position:absolute;left:${Math.round(70 * scale)}px;top:${brandTop}px;z-index:6;display:flex;direction:ltr;align-items:center;gap:${Math.round(13 * scale)}px}
.app-logo{width:${Math.round((tall ? 70 : 58) * scale)}px;height:${Math.round((tall ? 70 : 58) * scale)}px;border-radius:${Math.round(18 * scale)}px;box-shadow:0 12px 26px rgba(31,45,85,.13)}
.app-name{font-size:${Math.round((tall ? 28 : 23) * scale)}px;font-weight:800;line-height:1;color:var(--dark);text-align:left}
.app-tag{font-size:${Math.round((tall ? 16 : 14) * scale)}px;color:var(--muted);margin-top:${Math.round(4 * scale)}px;text-align:left;font-weight:700}
.pill{position:absolute;top:${tall ? 165 : 120}px;left:50%;transform:translateX(-50%);z-index:5;min-width:${Math.round(280 * scale)}px;height:${Math.round((tall ? 82 : 66) * scale)}px;border-radius:999px;background:var(--primary);display:grid;place-items:center;color:var(--dark);font-size:${Math.round((tall ? 28 : 23) * scale)}px;font-weight:800;padding:0 ${Math.round(35 * scale)}px}
.store-card{position:absolute;left:50%;top:${contentTop}px;transform:translateX(-50%);z-index:5;width:${Math.round((tall ? 300 : 235) * scale)}px;height:${Math.round((tall ? 300 : 235) * scale)}px;background:#fff;border-radius:${Math.round(4 * scale)}px;display:grid;place-items:center;padding:${Math.round(42 * scale)}px;box-shadow:0 22px 42px rgba(31,45,85,.18)}
.store-logo{max-width:100%;max-height:100%;object-fit:contain}
.headline{position:absolute;left:${Math.round(72 * scale)}px;right:${Math.round(72 * scale)}px;top:${tall ? 760 : 535}px;z-index:6;display:flex;align-items:flex-end;justify-content:center;gap:${Math.round(30 * scale)}px;direction:ltr;color:var(--dark)}
.discount{font-size:${Math.round((tall ? 148 : 115) * scale)}px;line-height:.86;font-weight:800;letter-spacing:0;white-space:nowrap}
.discount-word{font-size:${Math.round((tall ? 88 : 72) * scale)}px;line-height:.9;font-weight:800;direction:rtl;white-space:nowrap}
.store-line{position:absolute;top:${tall ? 930 : 665}px;left:${Math.round(78 * scale)}px;right:${Math.round(78 * scale)}px;z-index:6;text-align:center;color:#68798a;font-size:${Math.round((tall ? 38 : 30) * scale)}px;font-weight:700}
.coupon-box{position:absolute;left:${Math.round(108 * scale)}px;right:${Math.round(108 * scale)}px;bottom:${couponBottom}px;z-index:7;background:#fff;border-radius:${Math.round(46 * scale)}px;padding:${Math.round((tall ? 36 : 28) * scale)}px ${Math.round(70 * scale)}px ${Math.round((tall ? 40 : 32) * scale)}px;box-shadow:0 24px 44px rgba(31,45,85,.18)}
.coupon-label{text-align:center;color:#69798a;font-size:${Math.round((tall ? 34 : 27) * scale)}px;font-weight:800;margin-bottom:${Math.round(18 * scale)}px}
.code{height:${Math.round((tall ? 94 : 76) * scale)}px;border-radius:999px;background:var(--secondary);display:grid;place-items:center;color:#fff;font-size:${Math.round((tall ? 65 : 52) * scale)}px;font-weight:800;line-height:1;direction:ltr;letter-spacing:0;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;padding:0 ${Math.round(24 * scale)}px}
.desc{position:absolute;left:${Math.round(92 * scale)}px;right:${Math.round(92 * scale)}px;bottom:${tall ? 235 : 125}px;z-index:6;text-align:center;color:#657382;font-size:${Math.round((tall ? 31 : 24) * scale)}px;line-height:1.35;font-weight:700}
</style>
</head>
<body>
<main class="board">
  <div class="blob-top"></div>
  <div class="blob-bottom"></div>
  <div class="soft-white"></div>
  <div class="waves"><div class="wave"></div><div class="wave"></div><div class="wave"></div><div class="wave"></div><div class="wave"></div></div>
  <div class="frame"></div>
  <header class="top-brand">
    <img class="app-logo" src="file:///${appLogo}">
    <div>
      <div class="app-name">وفرها صح</div>
      <div class="app-tag">كوبونات وعروض مختارة</div>
    </div>
  </header>
  <div class="pill">كود خصم</div>
  <div class="store-card"><img id="storeLogo" class="store-logo" src="${escapeHtml(logoData)}"></div>
  <section class="headline">
    <div class="discount">${escapeHtml(discount)}</div>
    <div class="discount-word">خصم</div>
  </section>
  <div class="store-line">على ${escapeHtml(storeName)}</div>
  <section class="coupon-box">
    <div class="coupon-label">كود الخصم</div>
    <div class="code">${escapeHtml(code)}</div>
  </section>
  <div class="desc">${escapeHtml(shortDesc)} استخدم الكود عند الدفع</div>
</main>
<script>
(() => {
  const img = document.getElementById('storeLogo');
  const fallback = ['#9bd900', '#075fae', '#08345f'];
  function setColors(colors) {
    document.documentElement.style.setProperty('--primary', colors[0] || fallback[0]);
    document.documentElement.style.setProperty('--secondary', colors[1] || fallback[1]);
    document.documentElement.style.setProperty('--dark', colors[2] || fallback[2]);
  }
  function hex(r,g,b){return '#' + [r,g,b].map(v => Math.max(0,Math.min(255,v|0)).toString(16).padStart(2,'0')).join('')}
  function brightness(c){return (c[0]*299+c[1]*587+c[2]*114)/1000}
  function dist(a,b){return Math.abs(a[0]-b[0])+Math.abs(a[1]-b[1])+Math.abs(a[2]-b[2])}
  function harvest() {
    const canvas = document.createElement('canvas');
    canvas.width = 80; canvas.height = 80;
    const ctx = canvas.getContext('2d', { willReadFrequently: true });
    ctx.drawImage(img, 0, 0, 80, 80);
    const data = ctx.getImageData(0, 0, 80, 80).data;
    const buckets = new Map();
    for (let i = 0; i < data.length; i += 16) {
      const a = data[i + 3];
      if (a < 80) continue;
      const r = data[i], g = data[i + 1], b = data[i + 2];
      if (r > 236 && g > 236 && b > 236) continue;
      if (r < 18 && g < 18 && b < 18) continue;
      const key = [r,g,b].map(v => Math.round(v / 32) * 32).join(',');
      buckets.set(key, (buckets.get(key) || 0) + 1);
    }
    const colors = [...buckets.entries()]
      .map(([k,count]) => ({ rgb: k.split(',').map(Number), count }))
      .sort((a,b) => b.count - a.count)
      .map(x => x.rgb);
    if (!colors.length) return setColors(fallback);
    const primary = colors.find(c => brightness(c) > 95 && brightness(c) < 230) || colors[0];
    const secondary = colors.find(c => dist(c, primary) > 120 && brightness(c) < 210) || colors.find(c => brightness(c) < brightness(primary)) || [7,95,174];
    const dark = brightness(secondary) < 120 ? secondary : [8,52,95];
    setColors([hex(...primary), hex(...secondary), hex(...dark)]);
  }
  if (img.complete) harvest();
  else img.addEventListener('load', harvest, { once: true });
})();
</script>
</body>
</html>`;
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
  const logoData = await fetchImageDataUrl(store.image || coupon?.image) || `file:///${appLogo}`;

  for (const [formatKey, format] of Object.entries(formats)) {
    await fs.writeFile(htmlPath, pageHtml(store, coupon, formatKey, logoData), 'utf8');
    const output = path.join(storeDir, `${format.label}-${slug}-${format.width}x${format.height}.png`);
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

await fs.writeFile(
  path.join(outDir, 'manifest.json'),
  JSON.stringify({ generated_at: new Date().toISOString(), stores: stores.length, coupons: coupons.length, images: written, files: manifest }, null, 2),
  'utf8',
);
await fs.rm(htmlPath, { force: true });
console.log(`Generated ${written} reference-style images for ${stores.length} stores in ${path.relative(root, outDir)}`);

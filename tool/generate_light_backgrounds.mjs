import fs from 'node:fs/promises';
import path from 'node:path';
import { spawn } from 'node:child_process';

const root = process.cwd();
const outDir = path.join(root, 'assets', 'social', 'backgrounds');
const htmlPath = path.join(outDir, '_background-render.html');
const appLogo = path.join(root, 'assets', 'image', 'wffrhasah.png').replace(/\\/g, '/');

const size = { width: 1080, height: 1920 };

const options = [
  {
    id: 'option-01-soft-app-glow',
    css: `
      .bg{background:
        radial-gradient(circle at 18% 12%, rgba(108,99,255,.30), transparent 28%),
        radial-gradient(circle at 84% 18%, rgba(255,101,132,.24), transparent 26%),
        radial-gradient(circle at 78% 78%, rgba(255,212,42,.30), transparent 32%),
        linear-gradient(160deg,#ffffff 0%,#f7f5ff 45%,#fff9e8 100%);}
      .ribbon{position:absolute;inset:auto -170px 270px -170px;height:430px;background:linear-gradient(90deg,rgba(108,99,255,.16),rgba(255,101,132,.14),rgba(255,212,42,.20));transform:rotate(-12deg);border-radius:999px;filter:blur(1px)}
      .glass{position:absolute;left:76px;right:76px;bottom:132px;height:520px;border-radius:56px;background:rgba(255,255,255,.62);box-shadow:0 28px 90px rgba(108,99,255,.16);border:1px solid rgba(255,255,255,.86);backdrop-filter:blur(10px)}
    `,
  },
  {
    id: 'option-02-clean-coupon-waves',
    css: `
      .bg{background:
        linear-gradient(135deg,#ffffff 0%,#fbfbff 34%,#fff5f7 68%,#fffdf4 100%);}
      .wave{position:absolute;left:-90px;right:-90px;height:520px;border-radius:50%;filter:blur(.2px)}
      .wave.one{top:190px;background:linear-gradient(100deg,rgba(108,99,255,.20),rgba(255,255,255,0));transform:rotate(-8deg)}
      .wave.two{top:510px;background:linear-gradient(100deg,rgba(255,101,132,.18),rgba(255,212,42,.18));transform:rotate(8deg)}
      .ticket-lines{position:absolute;left:82px;right:82px;bottom:150px;height:500px;border:3px dashed rgba(108,99,255,.18);border-radius:58px;background:rgba(255,255,255,.56)}
    `,
  },
  {
    id: 'option-03-bright-social-card',
    css: `
      .bg{background:
        radial-gradient(circle at 26% 18%, rgba(255,212,42,.38), transparent 25%),
        radial-gradient(circle at 78% 30%, rgba(108,99,255,.25), transparent 27%),
        radial-gradient(circle at 34% 82%, rgba(255,101,132,.22), transparent 30%),
        linear-gradient(180deg,#ffffff 0%,#f8fbff 54%,#fff7fb 100%);}
      .panel{position:absolute;left:58px;right:58px;top:258px;bottom:112px;border-radius:64px;background:linear-gradient(180deg,rgba(255,255,255,.72),rgba(255,255,255,.46));border:1px solid rgba(108,99,255,.12);box-shadow:0 32px 100px rgba(33,43,92,.12)}
      .accent{position:absolute;right:-110px;top:670px;width:430px;height:430px;border-radius:50%;background:rgba(255,101,132,.16)}
      .accent.two{left:-125px;right:auto;top:1010px;background:rgba(108,99,255,.15)}
    `,
  },
  {
    id: 'option-04-fresh-diagonal-bands',
    css: `
      .bg{background:
        linear-gradient(150deg,#ffffff 0%,#f6f4ff 42%,#fffaf0 100%);}
      .band{position:absolute;left:-180px;right:-180px;height:360px;border-radius:999px;transform:rotate(-18deg)}
      .band.one{top:290px;background:linear-gradient(90deg,rgba(108,99,255,.20),rgba(255,101,132,.10),rgba(255,255,255,0))}
      .band.two{top:680px;background:linear-gradient(90deg,rgba(255,212,42,.28),rgba(255,101,132,.12),rgba(255,255,255,0));transform:rotate(-18deg) translateX(120px)}
      .coupon-space{position:absolute;left:72px;right:72px;bottom:150px;height:360px;border-radius:52px;background:rgba(255,255,255,.70);border:1px solid rgba(108,99,255,.12);box-shadow:0 30px 80px rgba(108,99,255,.12)}
    `,
  },
  {
    id: 'option-05-minimal-premium',
    css: `
      .bg{background:
        radial-gradient(circle at 76% 14%,rgba(255,212,42,.28),transparent 22%),
        radial-gradient(circle at 18% 74%,rgba(108,99,255,.20),transparent 27%),
        linear-gradient(180deg,#ffffff 0%,#fafaff 58%,#fff8fb 100%);}
      .corner{position:absolute;right:-120px;top:220px;width:520px;height:520px;border-radius:58px;background:rgba(108,99,255,.10);transform:rotate(18deg)}
      .corner.two{left:-130px;right:auto;top:760px;background:rgba(255,101,132,.10);transform:rotate(-18deg)}
      .base-card{position:absolute;left:76px;right:76px;bottom:128px;height:470px;border-radius:58px;background:#fff;box-shadow:0 26px 72px rgba(35,38,78,.10);border:1px solid rgba(35,38,78,.06)}
    `,
  },
  {
    id: 'option-06-yellow-coupon-pop',
    css: `
      .bg{background:
        radial-gradient(circle at 28% 18%,rgba(255,212,42,.42),transparent 28%),
        radial-gradient(circle at 86% 72%,rgba(108,99,255,.18),transparent 28%),
        linear-gradient(160deg,#fffef8 0%,#ffffff 46%,#f8f6ff 100%);}
      .ticket{position:absolute;left:62px;right:62px;bottom:138px;height:460px;border-radius:56px;background:rgba(255,255,255,.76);border:3px dashed rgba(255,101,132,.22);box-shadow:0 30px 80px rgba(255,212,42,.18)}
      .circle{position:absolute;width:260px;height:260px;border-radius:50%;background:rgba(255,101,132,.14);right:-80px;top:380px}
      .circle.two{left:-86px;right:auto;top:1120px;background:rgba(108,99,255,.15)}
    `,
  },
  {
    id: 'option-07-lilac-clean-space',
    css: `
      .bg{background:
        radial-gradient(circle at 72% 22%,rgba(108,99,255,.25),transparent 30%),
        linear-gradient(180deg,#ffffff 0%,#f5f2ff 100%);}
      .sheet{position:absolute;left:54px;right:54px;top:210px;bottom:104px;border-radius:66px;background:rgba(255,255,255,.58);box-shadow:0 28px 88px rgba(108,99,255,.13);border:1px solid rgba(108,99,255,.10)}
      .highlight{position:absolute;left:90px;right:90px;bottom:162px;height:340px;border-radius:46px;background:linear-gradient(90deg,rgba(255,212,42,.22),rgba(255,101,132,.14));}
    `,
  },
  {
    id: 'option-08-soft-confetti',
    css: `
      .bg{background:linear-gradient(180deg,#ffffff 0%,#fbfbff 52%,#fffaf2 100%);}
      .dot{position:absolute;border-radius:999px;opacity:.34}
      .dot.a{width:170px;height:170px;left:128px;top:260px;background:#6c63ff}
      .dot.b{width:110px;height:110px;right:120px;top:430px;background:#ff6584}
      .dot.c{width:210px;height:210px;right:-54px;bottom:500px;background:#ffd42a}
      .dot.d{width:96px;height:96px;left:86px;bottom:360px;background:#ff6584}
      .content-zone{position:absolute;left:74px;right:74px;bottom:126px;height:520px;border-radius:56px;background:rgba(255,255,255,.72);box-shadow:0 26px 82px rgba(45,48,96,.11)}
    `,
  },
  {
    id: 'option-09-modern-split-light',
    css: `
      .bg{background:#fff}
      .split{position:absolute;inset:0;background:linear-gradient(112deg,#ffffff 0%,#ffffff 45%,#f2efff 45%,#fff6fa 100%)}
      .gold{position:absolute;left:-120px;bottom:250px;width:620px;height:620px;border-radius:50%;background:rgba(255,212,42,.22)}
      .purple{position:absolute;right:-160px;top:260px;width:520px;height:520px;border-radius:50%;background:rgba(108,99,255,.18)}
      .coupon-block{position:absolute;left:70px;right:70px;bottom:140px;height:400px;border-radius:52px;background:rgba(255,255,255,.78);border:1px solid rgba(255,255,255,.92);box-shadow:0 32px 88px rgba(108,99,255,.13)}
    `,
  },
];

function page(option) {
  return `<!doctype html>
<html>
<head>
<meta charset="utf-8">
<style>
*{box-sizing:border-box}
html,body{width:${size.width}px;height:${size.height}px;margin:0;overflow:hidden}
.bg{position:relative;width:${size.width}px;height:${size.height}px;overflow:hidden}
.grain{position:absolute;inset:0;opacity:.16;background-image:radial-gradient(rgba(55,55,80,.18) 1px, transparent 1px);background-size:18px 18px;mix-blend-mode:multiply}
.logo-mark{position:absolute;top:48px;left:54px;width:92px;height:92px;border-radius:26px;box-shadow:0 18px 44px rgba(108,99,255,.18)}
.soft-ring{position:absolute;top:42px;left:48px;width:104px;height:104px;border-radius:30px;border:1px solid rgba(108,99,255,.18)}
${option.css}
</style>
</head>
<body>
<main class="bg">
  <div class="ribbon"></div>
  <div class="split"></div>
  <div class="band one"></div>
  <div class="band two"></div>
  <div class="wave one"></div>
  <div class="wave two"></div>
  <div class="panel"></div>
  <div class="sheet"></div>
  <div class="accent"></div>
  <div class="accent two"></div>
  <div class="corner"></div>
  <div class="corner two"></div>
  <div class="gold"></div>
  <div class="purple"></div>
  <div class="circle"></div>
  <div class="circle two"></div>
  <div class="dot a"></div>
  <div class="dot b"></div>
  <div class="dot c"></div>
  <div class="dot d"></div>
  <div class="ticket-lines"></div>
  <div class="glass"></div>
  <div class="coupon-space"></div>
  <div class="base-card"></div>
  <div class="ticket"></div>
  <div class="highlight"></div>
  <div class="content-zone"></div>
  <div class="coupon-block"></div>
  <div class="grain"></div>
  <div class="soft-ring"></div>
  <img class="logo-mark" src="file:///${appLogo}">
</main>
</body>
</html>`;
}

async function renderChrome(chromePath, output) {
  await new Promise((resolve, reject) => {
    const profileDir = path.join(outDir, `.chrome-bg-${Date.now()}-${Math.random().toString(16).slice(2)}`);
    const args = [
      '--headless=new',
      '--disable-gpu',
      '--hide-scrollbars',
      '--disable-background-networking',
      '--disable-extensions',
      '--no-first-run',
      '--no-default-browser-check',
      '--allow-file-access-from-files',
      '--run-all-compositor-stages-before-draw',
      '--virtual-time-budget=1000',
      `--user-data-dir=${profileDir}`,
      `--window-size=${size.width},${size.height}`,
      `--screenshot=${output}`,
      `file:///${htmlPath.replace(/\\/g, '/')}`,
    ];
    const child = spawn(chromePath, args, { stdio: 'ignore' });
    child.on('exit', async (code) => {
      await fs.rm(profileDir, { recursive: true, force: true }).catch(() => {});
      code === 0 ? resolve() : reject(new Error(`Chrome exited ${code}`));
    });
    child.on('error', reject);
  });
}

await fs.mkdir(outDir, { recursive: true });
const chromePath = process.env.CHROME_PATH || 'C:/Program Files/Google/Chrome/Application/chrome.exe';

for (const option of options) {
  await fs.writeFile(htmlPath, page(option), 'utf8');
  await renderChrome(chromePath, path.join(outDir, `${option.id}-1080x1920.png`));
}

await fs.rm(htmlPath, { force: true });
console.log(`Generated ${options.length} light background options in ${path.relative(root, outDir)}`);

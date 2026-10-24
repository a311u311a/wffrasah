import React, {createContext, useContext, useEffect, useState} from 'react';
import {
  AbsoluteFill, Audio, Easing, Img, Sequence, continueRender, delayRender,
  interpolate, spring, staticFile, useCurrentFrame, useVideoConfig,
} from 'remotion';
import {UGC_ENVELOPE, UGC_FRAMES, UGC_LINES} from './ugc-voice';

// UGC-style selfie ad (1080×1920 @30fps): the presenter talks to camera with a face rig
// (lip-sync from the voice envelope, blinks, brow raises, nods on every word).
export {UGC_FRAMES};

const C = {
  purple: '#6B5CFF', deep: '#3B2FC9', night: '#1D1760', ink: '#2E2779',
  yellow: '#FFD84D', red: '#FF4D6D', green: '#22C59A',
};
const FONT = '"Tajawal", sans-serif';
const rtl: React.CSSProperties = {direction: 'rtl', fontFamily: FONT, textAlign: 'center'};
const clamp = {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'} as const;
const fontsCss = ['Bold', 'ExtraBold'].map((w, i) => (
  `@font-face{font-family:'Tajawal';src:url('${staticFile(`ugc/Tajawal-${w}.ttf`)}') format('truetype');font-weight:${700 + i * 100};font-display:block}`
)).join('');

type Key = typeof UGC_LINES[number]['key'];
const line = (k: Key) => UGC_LINES.find((l) => l.key === k)!;
// Global frame where word `i` of line `k` starts.
const wordAt = (k: Key, i: number) => line(k).words[i].f;
const ALL_WORDS = UGC_LINES.flatMap((l) => l.words.map((w) => w.f));
// Words that get a brow raise + stronger nod.
const EMPHASIS = [
  wordAt('hook', 1), wordAt('hook', 10), wordAt('story', 4), wordAt('story', 11), wordAt('coupons', 8),
  wordAt('copy', 4), wordAt('proof', 4), wordAt('proof', 10), wordAt('cta', 0), wordAt('cta', 2), wordAt('cta', 7),
];

// Scene cuts sit just before each line starts.
const CUT = UGC_LINES.map((l, i) => (i === 0 ? 0 : l.from - 4));
const sceneRange = (k: Key) => {
  const i = UGC_LINES.findIndex((l) => l.key === k);
  return [CUT[i], CUT[i + 1] ?? UGC_FRAMES] as const;
};

const SceneStart = createContext(0);
const useGlobalFrame = () => useCurrentFrame() + useContext(SceneStart);
const voiceAt = (f: number) => UGC_ENVELOPE[f] ?? 0;

/* ---------- face rig ---------- */

// Native avatar size; every face coordinate below is in these source pixels.
const AW = 1241, AH = 1268;
// Line between the lips, left corner → right corner.
const MOUTH: [number, number][] = [
  [592, 488], [610, 497], [630, 503], [650, 508], [670, 512], [690, 513], [710, 511], [725, 509], [736, 505],
];
// o/i = eye corners, top/bot = Bezier controls of the upper lash line and the closed-lid edge.
// lid = source rows [skin above lashes, lash line] that get stretched down over the eye on a blink.
const EYES = [
  {o: [551, 321], i: [652, 348], top: [598, 300], bot: [600, 362], lid: [304, 321]},
  {o: [820, 356], i: [725, 355], top: [768, 322], bot: [772, 382], lid: [326, 342]},
];
const BROWS = [{x: 617, y: 288, rx: 88, ry: 30}, {x: 777, y: 306, rx: 64, ry: 22}];

// Deterministic blink times, roughly every 2.5–4s, plus one after each cut.
const BLINKS = (() => {
  const out: number[] = [...CUT.slice(1).map((c) => c + 6)];
  let t = 40;
  for (let i = 0; t < UGC_FRAMES; i++) {
    out.push(t);
    t += 78 + ((i * 37) % 45);
  }
  return out;
})();
const blinkAt = (f: number) => {
  const curve = [0.55, 1, 1, 0.7, 0.3];
  let v = 0;
  for (const b of BLINKS) {
    const d = f - b;
    if (d >= 0 && d < curve.length) v = Math.max(v, curve[d]);
  }
  return v;
};

const decayingHits = (f: number, hits: number[], tau: number, span = 40) => {
  let v = 0;
  for (const h of hits) {
    const d = f - h;
    if (d >= 0 && d < span) v += Math.exp(-d / tau) * Math.sin(Math.min(d / 3, Math.PI / 2));
  }
  return v;
};

const useFace = () => {
  const g = useGlobalFrame();
  const v = (voiceAt(g - 1) + voiceAt(g) * 2 + voiceAt(g + 1)) / 4;
  const open = Math.min(1, v * 1.15) * 13;
  const blink = blinkAt(g);
  const brow = Math.min(1.2, decayingHits(g, EMPHASIS, 9));
  const nod = decayingHits(g, ALL_WORDS, 4, 14) + brow * 0.8;
  const rot = Math.sin(g / 41) * 1.4 + Math.sin(g / 17) * 0.4 + Math.sin(g / 3.1) * 0.5 * v;
  return {g, open, blink, brow, nod, rot, v};
};

const mouthPath = (open: number) => {
  const [x0] = MOUTH[0];
  const x1 = MOUTH[MOUTH.length - 1][0];
  const lower = [...MOUTH].reverse().map(([x, y]) => {
    const t = (x - x0) / (x1 - x0);
    return [x, y + open * 1.15 * Math.pow(Math.sin(Math.PI * t), 0.7)];
  });
  return `M${MOUTH.map(([x, y]) => `${x},${y}`).join(' L')} L${lower.map(([x, y]) => `${x},${y}`).join(' L')} Z`;
};

// Closing lid region plus the vertical stretch that maps the lid's source rows onto it.
const lid = (e: typeof EYES[number], b: number) => {
  const cx = e.top[0] + (e.bot[0] - e.top[0]) * b;
  const cy = e.top[1] + (e.bot[1] - e.top[1]) * b;
  const mid = (c: number) => (e.o[1] + 2 * c + e.i[1]) / 4;
  const top = mid(e.top[1]);
  const s = Math.max(0.05, mid(cy) - top + 3) / (e.lid[1] - e.lid[0]);
  return {
    clip: `M${e.o} Q${e.top} ${e.i} Q${cx},${cy} ${e.o} Z`,
    transform: `translate(0 ${top - e.lid[0] * s}) scale(1 ${s})`,
  };
};

const maskStyle = (m: string): React.CSSProperties => ({maskImage: m, WebkitMaskImage: m});

// The presenter: base photo plus a moving jaw, brows and eyelids, all in native pixels and scaled.
const Presenter: React.FC<{k: number; x: number; y: number; lean?: number}> = ({k, x, y, lean = 0}) => {
  const {g, open, blink, brow, nod, rot} = useFace();
  const breath = Math.sin(g / 16) * 0.006;
  const src = staticFile('ugc/avatar.webp');
  const jawClip = `polygon(540px 486px, ${MOUTH.map(([mx, my]) => `${mx}px ${my}px`).join(', ')}, 790px 505px, 790px 670px, 540px 670px)`;
  return (
    <div style={{
      position: 'absolute', left: x, top: y, width: AW, height: AH, transformOrigin: '0 0',
      transform: `scale(${k})`,
    }}>
      <div style={{
        position: 'absolute', inset: 0, transformOrigin: '54% 92%',
        transform: `translateY(${nod * 7}px) rotate(${rot + lean}deg) scale(1, ${1 + breath})`,
      }}>
        <Img src={src} style={{position: 'absolute', inset: 0, width: AW, height: AH}}/>
        <svg width={AW} height={AH} style={{position: 'absolute', inset: 0}}>
          <defs>
            <linearGradient id="mouthIn" x1="0" y1="0" x2="0" y2="1">
              <stop offset="0" stopColor="#2A0C10"/><stop offset="1" stopColor="#5A1E24"/>
            </linearGradient>
            <clipPath id="mouth"><path d={mouthPath(open)}/></clipPath>
          </defs>
          {open > 0.6 && (
            <g clipPath="url(#mouth)">
              <rect x={580} y={480} width={170} height={60} fill="url(#mouthIn)"/>
              {open > 5 && (
                <ellipse cx={668} cy={512} rx={38} ry={Math.min(open * 0.28, 4)} fill="#E6D6CC" opacity={0.75}/>
              )}
            </g>
          )}
        </svg>
        {/* lower lip + chin, feathered, drops with the voice */}
        <Img src={src} style={{
          position: 'absolute', inset: 0, width: AW, height: AH, clipPath: jawClip, translate: `0 ${open}px`,
          ...maskStyle('radial-gradient(ellipse 96px 125px at 665px 540px, #000 52%, transparent 100%)'),
        }}/>
        {BROWS.map((b, i) => (
          <Img key={i} src={src} style={{
            position: 'absolute', inset: 0, width: AW, height: AH, translate: `0 ${-brow * 7}px`,
            ...maskStyle(`radial-gradient(ellipse ${b.rx}px ${b.ry}px at ${b.x}px ${b.y}px, #000 45%, transparent 100%)`),
          }}/>
        ))}
        {blink > 0.05 && (
          <svg width={AW} height={AH} style={{position: 'absolute', inset: 0}}>
            {EYES.map((e, i) => {
              const p = lid(e, blink);
              return (
                <g key={i}>
                  <clipPath id={`lid${i}`}><path d={p.clip}/></clipPath>
                  <g clipPath={`url(#lid${i})`}>
                    <image href={src} width={AW} height={AH} transform={p.transform}/>
                  </g>
                </g>
              );
            })}
          </svg>
        )}
      </div>
    </div>
  );
};

/* ---------- camera + backgrounds ---------- */

type Shot = {at: number; k: number; fx: number; fy: number};

// Hard jump-cuts between framings (scene-local frames), plus handheld wobble. fx/fy = where the face lands.
const SelfieCam: React.FC<{shots: Shot[]; lean?: number; children?: React.ReactNode}> = ({shots, lean, children}) => {
  const f = useCurrentFrame();
  const g = useGlobalFrame();
  const shot = [...shots].reverse().find((s) => f >= s.at) ?? shots[0];
  const sinceCut = f - shot.at;
  const settle = 1 + 0.035 * Math.exp(-sinceCut / 5);
  const hx = Math.sin(g / 23) * 7 + Math.sin(g / 9.3) * 2.5;
  const hy = Math.cos(g / 29) * 6 + Math.sin(g / 11.7) * 2;
  const k = shot.k * settle;
  return (
    <AbsoluteFill style={{transform: `translate(${hx}px, ${hy}px) rotate(${Math.sin(g / 37) * 0.35}deg)`, transformOrigin: '50% 50%'}}>
      <Room/>
      <Presenter k={k} x={shot.fx - 665 * k} y={shot.fy - 420 * k} lean={lean}/>
      {children}
    </AbsoluteFill>
  );
};

// Soft, out-of-focus living room behind the selfie.
const Room: React.FC = () => {
  const g = useGlobalFrame();
  const bokeh = [
    {x: 120, y: 260, r: 120, c: '#FFE3B3'}, {x: 880, y: 180, r: 90, c: '#FFF4DA'}, {x: 980, y: 760, r: 150, c: '#FFD9A8'},
    {x: 70, y: 980, r: 100, c: '#F6E7FF'}, {x: 760, y: 420, r: 60, c: '#FFFFFF'},
  ];
  return (
    <AbsoluteFill style={{background: 'linear-gradient(160deg, #F4E8DC 0%, #E7D3C2 45%, #CDB3A0 100%)', overflow: 'hidden'}}>
      <div style={{position: 'absolute', left: 620, top: -80, width: 560, height: 1100, background: 'linear-gradient(180deg, #FFFBF3, #F7EBDD)', filter: 'blur(26px)', opacity: 0.85}}/>
      <div style={{position: 'absolute', left: -60, top: 1150, width: 1300, height: 900, background: '#B9967F', filter: 'blur(40px)', opacity: 0.6}}/>
      <div style={{position: 'absolute', left: -40, top: 520, width: 300, height: 520, borderRadius: '50%', background: '#7E9B74', filter: 'blur(44px)', opacity: 0.55}}/>
      {bokeh.map((b, i) => (
        <div key={i} style={{
          position: 'absolute', left: b.x - b.r, top: b.y - b.r + Math.sin((g + i * 30) / 60) * 10, width: b.r * 2, height: b.r * 2,
          borderRadius: '50%', background: b.c, filter: 'blur(22px)', opacity: 0.7,
        }}/>
      ))}
    </AbsoluteFill>
  );
};

/* ---------- overlays ---------- */

const Captions: React.FC<{top?: number}> = ({top = 1330}) => {
  const g = useGlobalFrame();
  const {fps} = useVideoConfig();
  const l = [...UGC_LINES].reverse().find((x) => g >= x.from - 4);
  if (!l || g > l.to + 10) return null;
  const size = l.words.length > 10 ? 3 : 2;
  const chunks: (typeof l.words[number])[][] = [];
  l.words.forEach((w, i) => {
    if (i % size === 0) chunks.push([]);
    chunks[chunks.length - 1].push(w);
  });
  const ci = Math.max(0, chunks.findLastIndex((c) => g >= c[0].f - 2));
  const chunk = chunks[ci];
  const pop = spring({frame: g - (chunk[0].f - 2), fps, config: {damping: 10, mass: 0.5}});
  return (
    <div style={{position: 'absolute', top, left: 40, right: 40, display: 'flex', justifyContent: 'center', flexWrap: 'wrap', gap: '0 22px', direction: 'rtl', scale: `${interpolate(pop, [0, 1], [0.7, 1])}`}}>
      {chunk.map((w, i) => {
        const on = g >= w.f && g < (chunk[i + 1]?.f ?? w.e + 12);
        return (
          <span key={i} style={{
            ...rtl, fontSize: 104, fontWeight: 800, lineHeight: 1.15, color: on ? C.yellow : '#fff',
            WebkitTextStroke: '14px #120E33', paintOrder: 'stroke fill', textShadow: '0 10px 0 rgba(18,14,51,.55)',
            display: 'inline-block', scale: on ? '1.08' : '1', rotate: on ? '-2deg' : '0deg',
          }}>{w.w.replace(/[،,.!]/g, '')}</span>
        );
      })}
    </div>
  );
};

const Sticker: React.FC<{at: number; until?: number; children: React.ReactNode; style: React.CSSProperties; rot?: number; bg?: string; color?: string}> = ({
  at, until = Infinity, children, style, rot = -6, bg = '#fff', color = C.ink,
}) => {
  const f = useCurrentFrame();
  const {fps} = useVideoConfig();
  const p = spring({frame: f - at, fps, config: {damping: 9, mass: 0.55}});
  if (f < at || f >= until) return null;
  return (
    <div style={{
      position: 'absolute', ...style, scale: `${p}`, rotate: `${rot + Math.sin(f / 12) * 2}deg`,
      background: bg, color, borderRadius: 34, padding: '18px 34px', ...rtl, fontSize: 56, fontWeight: 800,
      boxShadow: '0 18px 40px rgba(18,14,51,.28)', whiteSpace: 'nowrap',
    }}>{children}</div>
  );
};

const Phone: React.FC<{src: string; width: number; zoom?: number; origin?: string; children?: React.ReactNode; style?: React.CSSProperties}> = ({
  src, width, zoom = 1, origin = '50% 0%', children, style,
}) => {
  const h = (width * 2000) / 920;
  return (
    <div style={{width: width + 24, height: h + 24, borderRadius: 84, background: '#111', padding: 12, boxShadow: '0 50px 100px rgba(0,0,0,.45)', ...style}}>
      <div style={{width, height: h, borderRadius: 72, overflow: 'hidden', position: 'relative', background: '#fff'}}>
        <div style={{position: 'absolute', inset: 0, scale: `${zoom}`, transformOrigin: origin}}>
          <Img src={staticFile(src)} style={{width, height: h, display: 'block'}}/>
          {children}
        </div>
      </div>
    </div>
  );
};

// "Green screen" UGC format: the app fills the background and the presenter talks from the bottom.
const GreenScreen: React.FC<{src: string; children?: React.ReactNode; phone: React.ReactNode}> = ({src, children, phone}) => {
  const f = useCurrentFrame();
  const {fps} = useVideoConfig();
  const enter = spring({frame: f, fps, config: {damping: 14, mass: 0.8}});
  return (
    <AbsoluteFill style={{background: C.night}}>
      <Img src={staticFile(src)} style={{position: 'absolute', left: -200, top: -300, width: 1480, height: 3200, filter: 'blur(40px) saturate(1.2)', opacity: 0.55}}/>
      <AbsoluteFill style={{background: `linear-gradient(180deg, ${C.deep}AA, ${C.night}EE)`}}/>
      <div style={{position: 'absolute', top: 70, left: 50, translate: `0 ${interpolate(enter, [0, 1], [900, 0])}px`, rotate: `${interpolate(enter, [0, 1], [-8, -2])}deg`}}>
        {phone}
      </div>
      <Presenter k={0.9} x={730 - 665 * 0.9} y={1300 - 420 * 0.9} lean={-4}/>
      {children}
    </AbsoluteFill>
  );
};

/* ---------- scenes ---------- */

const local = (k: Key, i: number) => wordAt(k, i) - sceneRange(k)[0];

const Hook: React.FC = () => (
  <SelfieCam shots={[{at: 0, k: 1.45, fx: 540, fy: 760}, {at: local('hook', 1), k: 1.75, fx: 540, fy: 720}, {at: local('hook', 2), k: 1.3, fx: 540, fy: 800}]}>
    <Sticker at={local('hook', 0)} style={{top: 150, right: 70}} rot={6} bg={C.red} color="#fff">✋ لحظة!</Sticker>
    <Sticker at={local('hook', 6)} style={{top: 290, left: 70}} rot={-7}>🛒 قبل ما تطلب</Sticker>
    <Captions/>
  </SelfieCam>
);

const Story: React.FC = () => {
  const f = useCurrentFrame();
  const {fps} = useVideoConfig();
  const logo = spring({frame: f - local('story', 10), fps, config: {damping: 10, mass: 0.6}});
  return (
    <SelfieCam shots={[{at: 0, k: 1.12, fx: 560, fy: 1000}, {at: local('story', 8), k: 1.35, fx: 520, fy: 900}]}>
      <Sticker at={local('story', 3)} until={local('story', 10)} style={{top: 210, left: 80}} rot={-8}>😩 السعر كامل</Sticker>
      {f >= local('story', 10) && (
        <div style={{position: 'absolute', top: 170, left: 0, right: 0, display: 'flex', justifyContent: 'center', scale: `${logo}`}}>
          <div style={{display: 'flex', alignItems: 'center', gap: 26, direction: 'rtl', background: '#fff', borderRadius: 60, padding: '22px 44px 22px 30px', boxShadow: '0 24px 60px rgba(46,39,121,.3)'}}>
            <Img src={staticFile('ugc/logo.png')} style={{width: 120, height: 120, borderRadius: 30}}/>
            <div style={{...rtl, fontSize: 92, fontWeight: 800, color: C.purple}}>وفّرها صح</div>
          </div>
        </div>
      )}
      <Captions/>
    </SelfieCam>
  );
};

const Coupons: React.FC = () => {
  const f = useCurrentFrame();
  const {fps} = useVideoConfig();
  const badges = [
    {t: '20%', x: 700, y: 150, r: 8, w: 1}, {t: '10%', x: 820, y: 360, r: -6, w: 2}, {t: '7%', x: 690, y: 570, r: 5, w: 3},
  ];
  return (
    <GreenScreen src="ugc/coupons.webp" phone={<Phone src="ugc/coupons.webp" width={560} zoom={interpolate(f, [0, 140], [1, 1.08])}/>}>
      {badges.map((b, i) => {
        const p = spring({frame: f - local('coupons', b.w), fps, config: {damping: 9, mass: 0.6}});
        return (
          <div key={i} style={{
            position: 'absolute', left: b.x, top: b.y + Math.sin((f + i * 20) / 14) * 10, rotate: `${b.r}deg`, scale: `${p}`,
            background: C.yellow, color: C.night, borderRadius: 34, padding: '10px 30px', fontFamily: FONT, fontSize: 84, fontWeight: 800,
            boxShadow: '0 22px 46px rgba(0,0,0,.4)', border: '5px solid #fff',
          }}>{b.t}</div>
        );
      })}
      <Sticker at={local('coupons', 5)} style={{top: 800, right: 40}} rot={5} bg={C.green} color="#fff">🎁 كوبون كل يوم</Sticker>
      <Captions top={1640}/>
    </GreenScreen>
  );
};

const Copy: React.FC = () => {
  const f = useCurrentFrame();
  const {fps} = useVideoConfig();
  const s = 560 / 920;
  const swap = local('copy', 2);
  const tap = interpolate(f, [local('copy', 3) - 4, local('copy', 3) + 12], [0, 1], clamp);
  const toast = spring({frame: f - local('copy', 4), fps, config: {damping: 11, mass: 0.6}});
  const zoom = interpolate(f, [swap, swap + 14], [1, 1.25], {...clamp, easing: Easing.inOut(Easing.cubic)});
  const storeTap = interpolate(f, [8, 24], [0, 1], clamp);
  const phone = f < swap ? (
    <Phone src="ugc/stores.webp" width={560}>
      <div style={{
        position: 'absolute', left: 345 * s + 115 * s - 55, top: 500 * s + 100 * s - 55, width: 110, height: 110, borderRadius: 55,
        background: 'rgba(107,92,255,.35)', border: '5px solid #fff', opacity: storeTap > 0 && storeTap < 1 ? 1 - storeTap : 0,
        scale: `${interpolate(storeTap, [0, 1], [0.3, 1.8])}`,
      }}/>
    </Phone>
  ) : (
    <Phone src="ugc/home.webp" width={560} zoom={zoom} origin="50% 50%">
      <div style={{
        position: 'absolute', left: 30 * s, top: 878 * s, width: 868 * s, height: 296 * s, borderRadius: 40 * s,
        border: `7px solid ${C.yellow}`, opacity: interpolate(f, [swap + 6, swap + 14], [0, 1], clamp),
      }}/>
      <div style={{
        position: 'absolute', left: 560 * s - 55, top: 990 * s - 55, width: 110, height: 110, borderRadius: 55,
        background: 'rgba(107,92,255,.35)', border: '5px solid #fff', opacity: tap > 0 && tap < 1 ? 1 - tap : 0,
        scale: `${interpolate(tap, [0, 1], [0.3, 1.8])}`,
      }}/>
    </Phone>
  );
  return (
    <GreenScreen src="ugc/home.webp" phone={phone}>
      {f >= local('copy', 4) && (
        <div style={{position: 'absolute', top: 640, right: 30, scale: `${toast}`, transformOrigin: '100% 50%'}}>
          <div style={{display: 'flex', alignItems: 'center', gap: 20, background: '#fff', color: C.ink, borderRadius: 60, padding: '22px 44px', ...rtl, fontSize: 50, fontWeight: 800, boxShadow: '0 25px 60px rgba(0,0,0,.4)'}}>
            <span style={{width: 60, height: 60, borderRadius: 30, background: C.green, color: '#fff', display: 'inline-flex', alignItems: 'center', justifyContent: 'center', fontSize: 38}}>✓</span>
            تم نسخ الكود
          </div>
        </div>
      )}
      <Captions top={1640}/>
    </GreenScreen>
  );
};

const Confetti: React.FC<{at: number}> = ({at}) => {
  const f = useCurrentFrame();
  const d = f - at;
  if (d < 0 || d > 60) return null;
  const colors = [C.yellow, C.purple, C.green, C.red, '#fff'];
  return (
    <AbsoluteFill>
      {Array.from({length: 46}).map((_, i) => {
        const a = (i * 137.5 * Math.PI) / 180;
        const v = 22 + (i % 7) * 4;
        const x = 540 + Math.cos(a) * v * d;
        const y = 470 + Math.sin(a) * v * d * 0.8 + 0.9 * d * d;
        return <div key={i} style={{position: 'absolute', left: x, top: y, width: 22, height: 34, background: colors[i % 5], rotate: `${d * (8 + i)}deg`, opacity: 1 - d / 60, borderRadius: 4}}/>;
      })}
    </AbsoluteFill>
  );
};

const Proof: React.FC = () => {
  const f = useCurrentFrame();
  const {fps} = useVideoConfig();
  const card = spring({frame: f - local('proof', 1), fps, config: {damping: 12, mass: 0.7}});
  const strike = interpolate(f, [local('proof', 6), local('proof', 6) + 8], [0, 1], {...clamp, easing: Easing.out(Easing.cubic)});
  const paid = spring({frame: f - local('proof', 7), fps, config: {damping: 8, mass: 0.5}});
  return (
    <SelfieCam shots={[{at: 0, k: 1.25, fx: 540, fy: 1060}, {at: local('proof', 10), k: 1.5, fx: 540, fy: 1000}]}>
      <div style={{position: 'absolute', top: 140, left: 110, right: 110, scale: `${card}`, rotate: '-3deg', background: '#fff', borderRadius: 44, padding: '34px 44px', boxShadow: '0 30px 70px rgba(18,14,51,.3)', ...rtl}}>
        <div style={{fontSize: 44, fontWeight: 700, color: '#8A84AD', textAlign: 'right'}}>🧾 آخر طلب</div>
        <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: 10, direction: 'rtl'}}>
          <span style={{fontSize: 56, fontWeight: 700, color: C.ink}}>المجموع</span>
          <span style={{position: 'relative', fontSize: 72, fontWeight: 800, color: C.ink}}>
            500 ريال
            <span style={{position: 'absolute', top: '48%', right: -10, height: 12, borderRadius: 6, background: C.red, width: `${strike * 110}%`, rotate: '-6deg'}}/>
          </span>
        </div>
        {f >= local('proof', 7) && (
          <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: 8, direction: 'rtl', scale: `${paid}`}}>
            <span style={{fontSize: 56, fontWeight: 700, color: C.green}}>بعد الكوبون</span>
            <span style={{fontSize: 92, fontWeight: 800, color: C.green}}>375 ريال</span>
          </div>
        )}
      </div>
      <Sticker at={local('proof', 10)} style={{top: 455, left: 300}} rot={4} bg={C.yellow} color={C.night}>🎉 وفّرت 125 ريال</Sticker>
      <Confetti at={local('proof', 10)}/>
      <Captions top={1400}/>
    </SelfieCam>
  );
};

const Cta: React.FC = () => {
  const f = useCurrentFrame();
  const {fps} = useVideoConfig();
  const head = spring({frame: f - 2, fps, config: {damping: 11, mass: 0.6}});
  const btn = spring({frame: f - local('cta', 1), fps, config: {damping: 10, mass: 0.6}});
  const pulse = 1 + Math.max(0, Math.sin((f - local('cta', 1)) / 6)) * 0.05;
  const badges = spring({frame: f - local('cta', 4), fps, config: {damping: 12, mass: 0.6}});
  return (
    <SelfieCam shots={[{at: 0, k: 1.1, fx: 540, fy: 1080}, {at: local('cta', 5), k: 1.22, fx: 540, fy: 1060}]}>
      <div style={{position: 'absolute', top: 110, left: 0, right: 0, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 28}}>
        <div style={{display: 'flex', alignItems: 'center', gap: 24, direction: 'rtl', scale: `${head}`}}>
          <Img src={staticFile('ugc/logo.png')} style={{width: 130, height: 130, borderRadius: 34, boxShadow: '0 20px 50px rgba(107,92,255,.45)'}}/>
          <div style={{...rtl, fontSize: 100, fontWeight: 800, color: C.purple, textShadow: '0 6px 0 #fff'}}>وفّرها صح</div>
        </div>
        <div style={{scale: `${btn * pulse}`, background: C.purple, color: '#fff', borderRadius: 70, padding: '26px 70px', ...rtl, fontSize: 60, fontWeight: 800, boxShadow: '0 24px 60px rgba(59,47,201,.5)'}}>
          حمّل التطبيق مجاناً 👇
        </div>
        <div style={{display: 'flex', gap: 24, scale: `${badges}`, opacity: interpolate(badges, [0, 0.3], [0, 1], clamp)}}>
          <Img src={staticFile('ugc/app-store.svg')} style={{height: 92}}/>
          <Img src={staticFile('ugc/google-play.svg')} style={{height: 92}}/>
        </div>
      </div>
      <Captions top={1420}/>
    </SelfieCam>
  );
};

/* ---------- root ---------- */

export const UgcVideo: React.FC = () => {
  const {fps} = useVideoConfig();
  const [handle] = useState(() => delayRender('Loading Tajawal'));
  useEffect(() => {
    Promise.all([700, 800].map((w) => document.fonts.load(`${w} 100px "Tajawal"`, 'وفرها صح')))
      .then(() => continueRender(handle), () => continueRender(handle));
  }, [handle]);

  const scenes: [Key, React.FC][] = [['hook', Hook], ['story', Story], ['coupons', Coupons], ['copy', Copy], ['proof', Proof], ['cta', Cta]];
  return (
    <AbsoluteFill style={{background: C.night}}>
      <style>{fontsCss}</style>
      {scenes.map(([k, Scene]) => {
        const [from, to] = sceneRange(k);
        return (
          <Sequence key={k} from={from} durationInFrames={to - from} premountFor={fps}>
            <SceneStart.Provider value={from}><Scene/></SceneStart.Provider>
          </Sequence>
        );
      })}
      <Audio
        src={staticFile('assets/soft-music.wav')}
        volume={(f) => interpolate(f, [0, 6, UGC_FRAMES - 30, UGC_FRAMES], [0, 0.12, 0.12, 0], clamp)}
      />
      <Audio src={staticFile('ugc/voice.wav')}/>
    </AbsoluteFill>
  );
};

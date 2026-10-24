import React, {createContext, useContext, useEffect, useState} from 'react';
import {
  AbsoluteFill, Audio, Easing, Img, Sequence, continueRender, delayRender,
  interpolate, spring, staticFile, useCurrentFrame, useVideoConfig,
} from 'remotion';
import {VOICE_ENVELOPE} from './voice-envelope';

// 20s vertical promo (1080×1920 @30fps) with the presenter avatar.
export const PROMO_FRAMES = 600;

const C = {
  purple: '#6B5CFF', deep: '#3B2FC9', night: '#1D1760', ink: '#2E2779',
  lav: '#EEEBFF', yellow: '#FFD84D', red: '#FF4D6D', green: '#22C59A', muted: '#8A84AD',
};
const FONT = '"Readex Pro", sans-serif';
const rtl: React.CSSProperties = {direction: 'rtl', fontFamily: FONT, textAlign: 'center'};
const clamp = {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'} as const;

// Scene boundaries (frames), cut on the pauses of public/promo/voice.wav.
const S = {hook: 0, talk: 68, home: 205, coupons: 315, stores: 395, cta: 468};

// Global frame where the current scene starts, so avatars can read the voice envelope.
const SceneStart = createContext(0);
const voiceAt = (frame: number) => VOICE_ENVELOPE[frame] ?? 0;

const usePop = (delay = 0, damping = 12, mass = 0.7) => {
  const f = useCurrentFrame();
  const {fps} = useVideoConfig();
  return spring({frame: f - delay, fps, config: {damping, mass}});
};

const fontsCss = `@font-face{font-family:'Readex Pro';src:url('${staticFile('reel/ReadexPro.ttf')}') format('truetype');font-weight:160 700;font-display:block}`;

/* ---------- shared pieces ---------- */

const Burst: React.FC<{color?: string; opacity?: number}> = ({color = '#ffffff', opacity = 0.08}) => {
  const f = useCurrentFrame();
  const rays = Array.from({length: 18});
  return (
    <AbsoluteFill style={{alignItems: 'center', justifyContent: 'center'}}>
      <div style={{width: 3000, height: 3000, position: 'relative', rotate: `${f * 0.35}deg`}}>
        {rays.map((_, i) => (
          <div key={i} style={{
            position: 'absolute', left: '50%', top: '50%', width: 1500, height: 160,
            transformOrigin: '0 50%', rotate: `${(360 / rays.length) * i}deg`,
            background: `linear-gradient(90deg, ${color}00, ${color})`, opacity,
            clipPath: 'polygon(0 50%, 100% 0, 100% 100%)',
          }}/>
        ))}
      </div>
    </AbsoluteFill>
  );
};

const Floaters: React.FC<{color: string}> = ({color}) => {
  const f = useCurrentFrame();
  const items = [
    {x: 90, y: 300, s: 70, d: 0}, {x: 930, y: 420, s: 50, d: 40}, {x: 160, y: 1250, s: 44, d: 80},
    {x: 900, y: 1500, s: 80, d: 20}, {x: 520, y: 180, s: 36, d: 60},
  ];
  return (
    <AbsoluteFill>
      {items.map((p, i) => (
        <div key={i} style={{
          position: 'absolute', left: p.x, top: p.y + Math.sin((f + p.d) / 18) * 22,
          fontFamily: FONT, fontWeight: 700, fontSize: p.s, color, opacity: 0.35,
          rotate: `${Math.sin((f + p.d) / 25) * 14}deg`,
        }}>%</div>
      ))}
    </AbsoluteFill>
  );
};

type Beat = {at: number; kind: 'nod' | 'jump' | 'shock'};
type AvatarMotion = {
  beats?: Beat[];
  lean?: {at: number; deg: number}[]; // turns toward the text being shown
};

// Idle breathing/sway plus damped reactions on each text beat; returns body transform values.
const useAvatarMotion = ({beats = [], lean = []}: AvatarMotion) => {
  const f = useCurrentFrame();
  const start = useContext(SceneStart);
  const voice = voiceAt(start + f);
  const {fps} = useVideoConfig();
  let rot = Math.sin(f / 32) * 1.2;
  let y = 0;
  let sc = 1;
  for (const l of lean) rot += l.deg * spring({frame: f - l.at, fps, config: {damping: 14}});
  for (const b of beats) {
    const dt = f - b.at;
    if (dt < 0 || dt > 45) continue;
    const env = Math.exp(-dt / 7);
    if (b.kind === 'nod') {
      rot -= 2.6 * env * Math.sin(dt / 2.4);
      y += 14 * env * Math.abs(Math.sin(dt / 2.4));
    } else if (b.kind === 'jump') {
      y -= 70 * env * Math.abs(Math.sin(dt / 3.2));
      sc += 0.04 * env;
    } else {
      sc += 0.07 * env * Math.cos(dt / 2.2);
      rot += 2 * env * Math.sin(dt / 1.6);
    }
  }
  // Head bob follows the loudness of the voiceover.
  const speaking = voice > 0.12;
  rot += Math.sin(f / 5) * 0.9 * voice;
  y -= voice * 9;
  const breath = Math.sin(f / 14) * 0.008;
  return {f, rot, y, sc, breath, speaking, voice};
};

const Sparks: React.FC<{beats: Beat[]; x: number; y: number; size: number}> = ({beats, x, y, size}) => {
  const f = useCurrentFrame();
  return (
    <>
      {beats.filter((b) => b.kind !== 'nod').map((b) => {
        const dt = f - b.at;
        if (dt < 0 || dt > 16) return null;
        const p = interpolate(dt, [0, 16], [0, 1]);
        return [-50, -10, 30].map((a, i) => (
          <div key={`${b.at}-${i}`} style={{
            position: 'absolute', left: x, top: y, width: size * (0.5 + p), height: size * 0.14, borderRadius: size,
            background: C.yellow, transformOrigin: '0 50%', rotate: `${a}deg`,
            translate: `${size * 0.4 * p}px 0`, opacity: 1 - p, scale: `${1 - p * 0.5} 1`,
          }}/>
        ));
      })}
    </>
  );
};

const SoundWaves: React.FC<{x: number; y: number; size: number; on: boolean}> = ({x, y, size, on}) => {
  const f = useCurrentFrame();
  if (!on) return null;
  return (
    <>
      {[0, 1, 2].map((i) => {
        const ph = ((f / 10 + i / 3) % 1);
        const d = size * (0.5 + ph);
        return (
          <div key={i} style={{
            position: 'absolute', left: x - d / 2, top: y - d / 2, width: d, height: d, borderRadius: '50%',
            borderRight: `${size * 0.09}px solid ${C.yellow}`, borderTop: '0 solid transparent', borderBottom: '0 solid transparent',
            opacity: Math.sin(ph * Math.PI) * 0.9,
          }}/>
        );
      })}
    </>
  );
};

// Full-body presenter that breathes, sways, leans toward text and reacts on beats.
const Avatar: React.FC<{width: number; style?: React.CSSProperties; glow?: string} & AvatarMotion> = ({width, style, glow = '#ffffff', ...motion}) => {
  const {f, rot, y, sc, breath, speaking, voice} = useAvatarMotion(motion);
  const h = width * 1268 / 1241;
  const halo = 1 + Math.sin(f / 10) * 0.04 + voice * 0.1;
  return (
    <div style={{width, height: h, ...style}}>
      <div style={{
        position: 'absolute', inset: 0, transformOrigin: '50% 100%',
        transform: `translateY(${y}px) rotate(${rot}deg) scale(${sc}, ${sc * (1 + breath)})`,
      }}>
        <div style={{
          position: 'absolute', left: width * 0.52 - width * 0.42, top: h * 0.34 - width * 0.42, width: width * 0.84, height: width * 0.84,
          borderRadius: '50%', background: `radial-gradient(circle, ${glow}66, ${glow}00 68%)`, scale: halo,
        }}/>
        <Img src={staticFile('promo/avatar.webp')} style={{position: 'absolute', inset: 0, width, height: h}}/>
        <SoundWaves x={width * 0.72} y={h * 0.4} size={width * 0.16} on={speaking}/>
        <Sparks beats={motion.beats ?? []} x={width * 0.7} y={h * 0.1} size={width * 0.09}/>
      </div>
    </div>
  );
};

// Circular picture-in-picture presenter for screens where the app UI takes the stage.
const AvatarBadge: React.FC<{size: number; style?: React.CSSProperties} & AvatarMotion> = ({size, style, ...motion}) => {
  const {rot, y, sc, speaking, voice} = useAvatarMotion(motion);
  const img = size * 2.1;
  const ring = 1 + voice * 0.12;
  return (
    <div style={{width: size, height: size, ...style, transform: `translateY(${y}px) rotate(${rot * 2}deg) scale(${sc})`}}>
      <div style={{position: 'absolute', inset: -14, borderRadius: '50%', border: `8px solid ${C.yellow}`, scale: ring, opacity: speaking ? 1 : 0.5}}/>
      <div style={{position: 'absolute', inset: 0, borderRadius: '50%', overflow: 'hidden', background: C.lav, border: '6px solid #fff', boxShadow: '0 20px 50px rgba(0,0,0,.35)'}}>
        <Img src={staticFile('promo/avatar.webp')} style={{
          position: 'absolute', width: img, height: img * 1268 / 1241,
          left: size / 2 - img * 0.525, top: size * 0.56 - img * 0.36,
        }}/>
      </div>
    </div>
  );
};

const Phone: React.FC<{src: string; width?: number; zoom?: number; children?: React.ReactNode; style?: React.CSSProperties}> = ({
  src, width = 640, zoom = 1, children, style,
}) => {
  const h = (width * 2000) / 920;
  return (
    <div style={{
      width: width + 28, height: h + 28, borderRadius: 96, background: C.night, padding: 14,
      boxShadow: '0 60px 120px rgba(29,23,96,.45), inset 0 0 0 3px rgba(255,255,255,.15)', ...style,
    }}>
      <div style={{width, height: h, borderRadius: 82, overflow: 'hidden', position: 'relative', background: '#fff'}}>
        <div style={{position: 'absolute', inset: 0, scale: zoom, transformOrigin: '50% 0%'}}>
          <Img src={staticFile(src)} style={{width, height: h, display: 'block'}}/>
          {children}
        </div>
      </div>
    </div>
  );
};

// Crops a region (in source-image px) from a 920×2000 screenshot into a tile.
const Crop: React.FC<{src: string; x: number; y: number; w: number; h: number; scale: number}> = ({src, x, y, w, h, scale}) => (
  <div style={{width: w * scale, height: h * scale, overflow: 'hidden', position: 'relative'}}>
    <Img src={staticFile(src)} style={{position: 'absolute', width: 920 * scale, height: 2000 * scale, left: -x * scale, top: -y * scale}}/>
  </div>
);

const Headline: React.FC<{lines: string[]; top: number; color?: string; size?: number; delay?: number; highlight?: number}> = ({
  lines, top, color = C.ink, size = 96, delay = 0, highlight = -1,
}) => {
  const f = useCurrentFrame();
  const {fps} = useVideoConfig();
  return (
    <div style={{position: 'absolute', top, left: 50, right: 50, ...rtl}}>
      {lines.map((l, i) => {
        const p = spring({frame: f - delay - i * 5, fps, config: {damping: 11, mass: 0.6}});
        return (
          <div key={i} style={{
            fontSize: size, fontWeight: 700, lineHeight: 1.22, color,
            opacity: interpolate(p, [0, 0.3], [0, 1], clamp),
            translate: `0 ${interpolate(p, [0, 1], [70, 0])}px`, scale: interpolate(p, [0, 1], [1.25, 1]),
          }}>
            {i === highlight ? (
              <span style={{background: C.yellow, color: C.night, padding: '0 26px', borderRadius: 26, boxDecorationBreak: 'clone'}}>{l}</span>
            ) : l}
          </div>
        );
      })}
    </div>
  );
};

const Bubble: React.FC<{text: string; delay?: number; style?: React.CSSProperties; tail?: 'left' | 'right'}> = ({text, delay = 0, style, tail = 'right'}) => {
  const p = usePop(delay, 10, 0.6);
  return (
    <div style={{
      position: 'absolute', ...style, scale: p, transformOrigin: tail === 'right' ? '85% 100%' : '15% 100%',
      background: '#fff', borderRadius: 44, padding: '30px 44px', boxShadow: '0 24px 60px rgba(46,39,121,.22)',
      ...rtl, fontSize: 52, fontWeight: 600, color: C.ink, lineHeight: 1.35,
    }}>
      {text}
      <div style={{
        position: 'absolute', bottom: -26, [tail]: 90, width: 0, height: 0,
        borderLeft: '22px solid transparent', borderRight: '22px solid transparent', borderTop: '30px solid #fff',
      }}/>
    </div>
  );
};

/* ---------- scenes ---------- */

// 0–2.3s: pattern-interrupt hook — full price gets slashed on frame ~20.
const Hook: React.FC = () => {
  const f = useCurrentFrame();
  const {fps} = useVideoConfig();
  const slam = spring({frame: f, fps, config: {damping: 9, mass: 0.5}});
  const strike = interpolate(f, [16, 24], [0, 1], {...clamp, easing: Easing.out(Easing.cubic)});
  const newPrice = spring({frame: f - 24, fps, config: {damping: 8, mass: 0.5}});
  const shake = f < 8 || (f >= 24 && f < 32) ? Math.sin(f * 3.1) * (f < 8 ? 14 : 10) : 0;
  const avatarIn = spring({frame: f - 6, fps, config: {damping: 14, mass: 0.8}});
  return (
    <AbsoluteFill style={{background: `radial-gradient(circle at 50% 35%, ${C.purple}, ${C.deep} 60%, ${C.night})`, translate: `${shake}px ${shake * 0.6}px`}}>
      <Burst opacity={0.09}/>
      <div style={{position: 'absolute', top: 170, left: 0, right: 0, ...rtl, color: '#fff', scale: interpolate(slam, [0, 1], [2.2, 1]), opacity: interpolate(slam, [0, 0.2], [0, 1], clamp)}}>
        <div style={{fontSize: 92, fontWeight: 600, opacity: 0.92}}>لسّه تدفع</div>
        <div style={{fontSize: 150, fontWeight: 700, lineHeight: 1.1}}>السعر كامل؟</div>
      </div>
      {/* price tag */}
      <div style={{position: 'absolute', top: 590, left: 0, right: 0, display: 'flex', justifyContent: 'center'}}>
        <div style={{position: 'relative', rotate: '-4deg', scale: interpolate(slam, [0, 1], [0.4, 1])}}>
          <div style={{background: '#fff', borderRadius: 40, padding: '18px 60px', ...rtl, fontSize: 120, fontWeight: 700, color: C.night, boxShadow: '0 30px 70px rgba(0,0,0,.3)'}}>
            500 ريال
          </div>
          <div style={{position: 'absolute', top: '50%', left: -20, height: 18, borderRadius: 9, background: C.red, width: `${strike * 112}%`, rotate: '-8deg'}}/>
          <div style={{
            position: 'absolute', top: 175, left: 160, scale: newPrice, rotate: '6deg',
            background: C.yellow, borderRadius: 40, padding: '14px 50px', ...rtl, fontSize: 112, fontWeight: 700, color: C.night,
            boxShadow: '0 26px 60px rgba(0,0,0,.35)', whiteSpace: 'nowrap',
          }}>
            375 ريال
          </div>
        </div>
      </div>
      <Avatar width={1060} style={{position: 'absolute', left: 10, bottom: -40, translate: `0 ${interpolate(avatarIn, [0, 1], [700, 0])}px`}}
        beats={[{at: 20, kind: 'shock'}, {at: 32, kind: 'nod'}, {at: 54, kind: 'nod'}]} lean={[{at: 26, deg: -2}]}/>
    </AbsoluteFill>
  );
};

// 2.3–6.8s: avatar speaks to camera, then reveals the brand.
const Talk: React.FC = () => {
  const f = useCurrentFrame();
  const {fps} = useVideoConfig();
  const zoom = interpolate(f, [0, 137], [1.12, 1.0], clamp);
  const logo = spring({frame: f - 95, fps, config: {damping: 10, mass: 0.6}});
  return (
    <AbsoluteFill style={{background: `linear-gradient(170deg, ${C.lav}, #fff 55%, #E3DEFF)`}}>
      <Floaters color={C.purple}/>
      <Avatar width={1180} style={{position: 'absolute', left: -50, bottom: -60, scale: zoom, transformOrigin: '50% 100%'}} glow={C.purple}
        beats={[{at: 6, kind: 'nod'}, {at: 32, kind: 'nod'}, {at: 72, kind: 'nod'}, {at: 97, kind: 'jump'}, {at: 122, kind: 'nod'}]}/>
      {f < 70 ? (
        <Bubble text="صرت أوفّر في كل طلب!" style={{top: 330, left: 150, right: 150}}/>
      ) : (
        <div style={{position: 'absolute', top: 230, left: 0, right: 0, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 22}}>
          <div style={{...rtl, fontSize: 64, fontWeight: 600, color: C.ink, opacity: interpolate(f, [70, 76], [0, 1], clamp), scale: interpolate(f, [70, 78], [1.6, 1], clamp)}}>والسر؟</div>
          <div style={{display: 'flex', alignItems: 'center', gap: 34, scale: logo, direction: 'rtl'}}>
            <Img src={staticFile('promo/logo.png')} style={{width: 190, height: 190, borderRadius: 48, boxShadow: '0 24px 60px rgba(107,92,255,.45)'}}/>
            <div style={{...rtl, fontSize: 132, fontWeight: 700, color: C.purple}}>وفّرها صح</div>
          </div>
          <div style={{
            ...rtl, fontSize: 42, fontWeight: 500, color: C.ink, marginTop: 10, background: '#fff', borderRadius: 40, padding: '16px 40px',
            boxShadow: '0 16px 40px rgba(46,39,121,.14)', opacity: interpolate(f, [115, 123], [0, 1], clamp),
            translate: `0 ${interpolate(f, [115, 123], [30, 0], clamp)}px`,
          }}>كوبونات وعروض متاجرك… في تطبيق واحد</div>
        </div>
      )}
    </AbsoluteFill>
  );
};

// 6.8–10.5s: home screen, "coupon of the day", tap to copy.
const Home: React.FC = () => {
  const f = useCurrentFrame();
  const {fps} = useVideoConfig();
  const enter = spring({frame: f, fps, config: {damping: 15, mass: 0.9}});
  const s = 640 / 920;
  const ring = interpolate(f, [22, 34], [0, 1], clamp);
  const tap = interpolate(f, [70, 88], [0, 1], clamp);
  const toast = spring({frame: f - 76, fps, config: {damping: 11, mass: 0.6}});
  const zoom = interpolate(f, [20, 50], [1, 1.12], {...clamp, easing: Easing.inOut(Easing.cubic)});
  return (
    <AbsoluteFill style={{background: `linear-gradient(180deg, ${C.purple}, ${C.deep})`}}>
      <Burst opacity={0.06}/>
      <Headline lines={['كوبون جديد', 'كل يوم بانتظارك']} top={110} color="#fff" size={92} highlight={1}/>
      <div style={{position: 'absolute', top: 430, left: 0, right: 0, display: 'flex', justifyContent: 'center'}}>
        <Phone src="promo/home.webp" zoom={zoom} style={{
          translate: `0 ${interpolate(enter, [0, 1], [1300, 0])}px`,
          transform: `perspective(2400px) rotateX(${interpolate(enter, [0, 1], [25, 0])}deg)`,
        }}>
          {/* highlight around "coupon of the day" card */}
          <div style={{
            position: 'absolute', left: 30 * s, top: 878 * s, width: 868 * s, height: 296 * s, borderRadius: 50 * s,
            border: `8px solid ${C.yellow}`, opacity: ring, scale: interpolate(ring, [0, 1], [1.15, 1]),
            boxShadow: `0 0 0 ${2000 * ring}px rgba(29,23,96,${0.45 * ring})`,
          }}/>
          {/* tap ripple on the code */}
          <div style={{
            position: 'absolute', left: 560 * s - 60, top: 990 * s - 60, width: 120, height: 120, borderRadius: 60,
            background: 'rgba(107,92,255,.35)', border: '5px solid #fff',
            opacity: tap > 0 && tap < 1 ? 1 - tap : 0, scale: interpolate(tap, [0, 1], [0.3, 1.8]),
          }}/>
        </Phone>
      </div>
      <AvatarBadge size={200} style={{position: 'absolute', left: 30, top: 1330, scale: spring({frame: f - 4, fps, config: {damping: 11}})}}
        beats={[{at: 26, kind: 'nod'}, {at: 78, kind: 'jump'}, {at: 100, kind: 'nod'}]}/>
      <div style={{
        position: 'absolute', bottom: 160, left: 0, right: 0, display: 'flex', justifyContent: 'center',
        scale: toast, opacity: interpolate(toast, [0, 0.3], [0, 1], clamp),
      }}>
        <div style={{display: 'flex', alignItems: 'center', gap: 22, background: C.night, color: '#fff', borderRadius: 60, padding: '26px 50px', ...rtl, fontSize: 50, fontWeight: 600, boxShadow: '0 25px 60px rgba(0,0,0,.4)'}}>
          <span style={{width: 62, height: 62, borderRadius: 31, background: C.green, display: 'inline-flex', alignItems: 'center', justifyContent: 'center', fontSize: 40}}>✓</span>
          تم نسخ الكود <span style={{fontWeight: 700, color: C.yellow, direction: 'ltr'}}>CQTWXTH</span>
        </div>
      </div>
    </AbsoluteFill>
  );
};

// 10.5–13.2s: coupons list with discount badges flying out.
const Coupons: React.FC = () => {
  const f = useCurrentFrame();
  const {fps} = useVideoConfig();
  const enter = spring({frame: f, fps, config: {damping: 14}});
  const badges = [
    {t: '20%', sub: 'الشمس والرمال', x: 40, y: 640, r: -8, d: 14},
    {t: '10%', sub: 'ذي بدي شوب', x: 700, y: 900, r: 7, d: 24},
    {t: '10%', sub: 'كروكس', x: 50, y: 1180, r: -5, d: 34},
    {t: '7%', sub: 'المطار', x: 720, y: 1440, r: 6, d: 44},
  ];
  return (
    <AbsoluteFill style={{background: `linear-gradient(170deg, ${C.lav}, #fff 60%, #E3DEFF)`}}>
      <Floaters color={C.purple}/>
      <Headline lines={['خصومات حقيقية', 'لأشهر المتاجر']} top={110} size={92} highlight={1}/>
      <div style={{position: 'absolute', top: 470, left: 0, right: 0, display: 'flex', justifyContent: 'center'}}>
        <Phone src="promo/coupons.webp" width={560} zoom={interpolate(f, [0, 80], [1, 1.06])} style={{
          scale: interpolate(enter, [0, 1], [0.6, 1]), rotate: `${interpolate(enter, [0, 1], [-12, 0])}deg`,
          opacity: interpolate(enter, [0, 0.3], [0, 1], clamp),
        }}/>
      </div>
      {badges.map((b, i) => {
        const p = spring({frame: f - b.d, fps, config: {damping: 9, mass: 0.6}});
        return (
          <div key={i} style={{
            position: 'absolute', left: b.x, top: b.y + Math.sin((f + i * 20) / 14) * 10, rotate: `${b.r}deg`, scale: p,
            background: C.purple, color: '#fff', borderRadius: 40, padding: '20px 36px', ...rtl,
            boxShadow: '0 26px 50px rgba(59,47,201,.45)', border: '5px solid #fff', minWidth: 270,
          }}>
            <div style={{fontSize: 30, fontWeight: 500, opacity: 0.9}}>{b.sub}</div>
            <div style={{fontSize: 90, fontWeight: 700, lineHeight: 1.05, direction: 'ltr'}}>{b.t}</div>
          </div>
        );
      })}
    </AbsoluteFill>
  );
};

// 13.2–15.6s: store logos cropped from the stores screen pop in as a grid.
const Stores: React.FC = () => {
  const f = useCurrentFrame();
  const {fps} = useVideoConfig();
  const logos = [
    {x: 640, y: 490}, {x: 345, y: 500}, {x: 50, y: 500},
    {x: 640, y: 855}, {x: 345, y: 855}, {x: 50, y: 855},
    {x: 640, y: 1215}, {x: 345, y: 1215}, {x: 50, y: 1215},
  ];
  return (
    <AbsoluteFill style={{background: `radial-gradient(circle at 50% 45%, ${C.purple}, ${C.deep} 65%, ${C.night})`}}>
      <Burst opacity={0.07}/>
      <Headline lines={['كل متاجرك المفضّلة', 'في مكان واحد']} top={130} color="#fff" size={88} highlight={1}/>
      <div style={{position: 'absolute', top: 520, left: 70, right: 70, display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 36, direction: 'rtl'}}>
        {logos.map((l, i) => {
          const p = spring({frame: f - 8 - i * 4, fps, config: {damping: 10, mass: 0.6}});
          return (
            <div key={i} style={{
              background: '#fff', borderRadius: 48, height: 290, display: 'flex', alignItems: 'center', justifyContent: 'center',
              scale: p, rotate: `${interpolate(p, [0, 1], [i % 2 ? 20 : -20, 0])}deg`, boxShadow: '0 22px 50px rgba(0,0,0,.28)',
              translate: `0 ${Math.sin((f + i * 9) / 16) * 8}px`,
            }}>
              <Crop src="promo/stores.webp" x={l.x} y={l.y} w={230} h={200} scale={1.05}/>
            </div>
          );
        })}
      </div>
      <AvatarBadge size={250} style={{position: 'absolute', right: 70, bottom: 130, scale: spring({frame: f, fps, config: {damping: 11}})}}
        beats={[{at: 8, kind: 'nod'}, {at: 42, kind: 'nod'}, {at: 60, kind: 'jump'}]}/>
      <div style={{
        position: 'absolute', bottom: 190, left: 60, right: 370, background: '#fff', color: C.ink, borderRadius: 40, padding: '26px 30px',
        ...rtl, fontSize: 44, fontWeight: 600, lineHeight: 1.35, boxShadow: '0 20px 50px rgba(0,0,0,.3)',
        scale: spring({frame: f - 5, fps, config: {damping: 11, mass: 0.6}}), transformOrigin: '100% 50%',
      }}>
        ابحث عن متجرك… واختر الكوبون
        <div style={{position: 'absolute', right: -24, top: '50%', marginTop: -20, borderTop: '20px solid transparent', borderBottom: '20px solid transparent', borderLeft: '28px solid #fff'}}/>
      </div>
    </AbsoluteFill>
  );
};

// 15.6–20s: avatar CTA.
const Cta: React.FC = () => {
  const f = useCurrentFrame();
  const {fps} = useVideoConfig();
  const icon = spring({frame: f, fps, config: {damping: 9, mass: 0.6}});
  const btn = spring({frame: f - 70, fps, config: {damping: 10, mass: 0.6}});
  const pulse = 1 + Math.max(0, Math.sin((f - 80) / 6)) * 0.05 * (f > 80 ? 1 : 0);
  const avatarIn = spring({frame: f - 4, fps, config: {damping: 15, mass: 0.9}});
  return (
    <AbsoluteFill style={{background: `radial-gradient(circle at 50% 30%, ${C.purple}, ${C.deep} 60%, ${C.night})`}}>
      <Burst opacity={0.1}/>
      <div style={{position: 'absolute', top: 120, left: 0, right: 0, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 26}}>
        <Img src={staticFile('promo/logo.png')} style={{width: 220, height: 220, borderRadius: 56, scale: icon, rotate: `${interpolate(icon, [0, 1], [-30, 0])}deg`, boxShadow: '0 30px 70px rgba(0,0,0,.35)', border: '6px solid rgba(255,255,255,.9)'}}/>
        <Headline lines={['لا تشتري قبل', 'ما توفّرها صح!']} top={250} color="#fff" size={104} delay={6} highlight={1}/>
      </div>
      <div style={{position: 'absolute', top: 700, left: 0, right: 0, display: 'flex', justifyContent: 'center', scale: btn * pulse}}>
        <div style={{background: '#fff', color: C.deep, borderRadius: 80, padding: '30px 80px', ...rtl, fontSize: 62, fontWeight: 700, boxShadow: '0 30px 70px rgba(0,0,0,.35)'}}>
          حمّل التطبيق الآن
        </div>
      </div>
      <Avatar width={1000} style={{position: 'absolute', left: 40, bottom: -40, translate: `0 ${interpolate(avatarIn, [0, 1], [600, 0])}px`}}
        beats={[{at: 10, kind: 'nod'}, {at: 40, kind: 'nod'}, {at: 72, kind: 'jump'}, {at: 100, kind: 'nod'}, {at: 118, kind: 'nod'}]}/>
    </AbsoluteFill>
  );
};

/* ---------- transitions + root ---------- */

const Flash: React.FC<{at: number}> = ({at}) => {
  const f = useCurrentFrame();
  const o = interpolate(f, [at - 2, at, at + 5], [0, 0.85, 0], clamp);
  return <AbsoluteFill style={{background: '#fff', opacity: o, pointerEvents: 'none'}}/>;
};

const ProgressBar: React.FC = () => {
  const f = useCurrentFrame();
  return (
    <div style={{position: 'absolute', top: 40, left: 60, right: 60, height: 10, borderRadius: 5, background: 'rgba(120,110,200,.35)', overflow: 'hidden'}}>
      <div style={{height: '100%', width: `${(f / PROMO_FRAMES) * 100}%`, background: C.yellow, marginLeft: 'auto'}}/>
    </div>
  );
};

export const AvatarPromo: React.FC = () => {
  const {fps} = useVideoConfig();
  const [handle] = useState(() => delayRender('Loading Readex Pro'));
  useEffect(() => {
    Promise.all([400, 500, 600, 700].map((w) => document.fonts.load(`${w} 100px "Readex Pro"`, 'وفرها صح')))
      .then(() => continueRender(handle), () => continueRender(handle));
  }, [handle]);

  const scenes: [number, number, React.FC][] = [
    [S.hook, S.talk, Hook], [S.talk, S.home, Talk], [S.home, S.coupons, Home],
    [S.coupons, S.stores, Coupons], [S.stores, S.cta, Stores], [S.cta, PROMO_FRAMES, Cta],
  ];
  return (
    <AbsoluteFill style={{background: C.night}}>
      <style>{fontsCss}</style>
      {scenes.map(([from, to, Scene], i) => (
        <Sequence key={i} from={from} durationInFrames={to - from} premountFor={fps}>
          <SceneStart.Provider value={from}><Scene/></SceneStart.Provider>
        </Sequence>
      ))}
      {[S.talk, S.home, S.coupons, S.stores, S.cta].map((at) => <Flash key={at} at={at}/>)}
      <ProgressBar/>
      <Audio
        src={staticFile('assets/soft-music.wav')}
        volume={(f) => interpolate(f, [0, 6, PROMO_FRAMES - 30, PROMO_FRAMES], [0, 0.22, 0.22, 0], clamp)}
      />
      <Audio src={staticFile('promo/voice.wav')}/>
    </AbsoluteFill>
  );
};

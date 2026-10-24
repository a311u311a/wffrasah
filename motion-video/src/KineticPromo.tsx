import React from 'react';
import {
  AbsoluteFill, Audio, Easing, Img, Sequence, interpolate, spring, staticFile,
  useCurrentFrame, useVideoConfig,
} from 'remotion';

// 20s vertical kinetic-typography promo (1080×1920 @30fps).
// Idea: your cart total keeps climbing → stop before paying → find and copy a code in the
// app → see the total drop → download وفّرها صح.
export const KINETIC_FRAMES = 600;

const C = {
  purple: '#6461FC', deep: '#3F3BD1', ink: '#1F1A5C', text: '#2B2750',
  lav: '#EFEEFF', bg1: '#FBFAFF', bg2: '#E6E4FF', muted: '#8C88B5', white: '#FFFFFF',
};
const FONT = '"Tajawal", sans-serif';
const clamp = {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'} as const;
const ease = Easing.bezier(0.22, 1, 0.36, 1);

// Scene boundaries (frames), cut on the pauses of public/kinetic/voice.wav (19.2s).
const S = {cart: 0, copy: 150, app: 300, bill: 360, cta: 470, end: KINETIC_FRAMES};

const fontsCss = ['Medium:500', 'Bold:700', 'ExtraBold:800'].map((s) => {
  const [name, weight] = s.split(':');
  return `@font-face{font-family:'Tajawal';src:url('${staticFile(`kinetic/Tajawal-${name}.ttf`)}') format('truetype');font-weight:${weight};font-display:block}`;
}).join('');

const usePop = (delay = 0, damping = 12, mass = 0.7) => {
  const f = useCurrentFrame();
  const {fps} = useVideoConfig();
  return spring({frame: f - delay, fps, config: {damping, mass}});
};

/* ---------- shared pieces ---------- */

const Background: React.FC = () => {
  const f = useCurrentFrame();
  const shapes = [
    {x: 80, y: 260, s: 90, d: 0, t: '%'}, {x: 900, y: 380, s: 70, d: 30, t: '٪'},
    {x: 140, y: 1500, s: 60, d: 70, t: '%'}, {x: 880, y: 1640, s: 100, d: 15, t: '%'},
    {x: 500, y: 120, s: 46, d: 50, t: '٪'}, {x: 60, y: 900, s: 50, d: 90, t: '%'},
    {x: 960, y: 1050, s: 56, d: 110, t: '٪'},
  ];
  return (
    <AbsoluteFill style={{background: `radial-gradient(120% 80% at 50% 35%, ${C.bg1} 0%, ${C.bg2} 100%)`}}>
      {shapes.map((p, i) => (
        <div key={i} style={{
          position: 'absolute', left: p.x, top: p.y + Math.sin((f + p.d) / 22) * 26,
          fontFamily: FONT, fontWeight: 800, fontSize: p.s, color: C.purple, opacity: 0.09,
          rotate: `${Math.sin((f + p.d) / 30) * 18}deg`,
        }}>{p.t}</div>
      ))}
    </AbsoluteFill>
  );
};

// Each scene blurs/zooms in on entry and punches out on exit, like quick editorial cuts.
const Scene: React.FC<{dur: number; children: React.ReactNode}> = ({dur, children}) => {
  const f = useCurrentFrame();
  const inP = interpolate(f, [0, 10], [0, 1], {...clamp, easing: ease});
  const outP = interpolate(f, [dur - 8, dur], [0, 1], {...clamp, easing: Easing.in(Easing.cubic)});
  return (
    <AbsoluteFill style={{
      opacity: inP * (1 - outP),
      filter: `blur(${(1 - inP) * 18 + outP * 22}px)`,
      scale: `${0.94 + inP * 0.06 + outP * 0.12}`,
    }}>
      {children}
    </AbsoluteFill>
  );
};

// Arabic words can't be split into letters without breaking joining, so each word
// wipes in right-to-left with a blur, staggered.
const Words: React.FC<{
  text: string; at: number; size: number; color?: string; weight?: number;
  stagger?: number; blurWord?: number; style?: React.CSSProperties;
}> = ({text, at, size, color = C.text, weight = 800, stagger = 4, blurWord, style}) => {
  const f = useCurrentFrame();
  const words = text.split(' ');
  return (
    <div style={{
      direction: 'rtl', fontFamily: FONT, fontWeight: weight, fontSize: size, color,
      display: 'flex', flexWrap: 'wrap', justifyContent: 'center', gap: `0 ${size * 0.26}px`,
      lineHeight: 1.35, ...style,
    }}>
      {words.map((w, i) => {
        const p = interpolate(f, [at + i * stagger, at + i * stagger + 12], [0, 1], {...clamp, easing: ease});
        // Optional word that stays blurred a beat longer (the "punchline" word).
        const extra = blurWord === i ? interpolate(f, [at + i * stagger + 12, at + i * stagger + 30], [14, 0], clamp) : 0;
        return (
          <span key={i} style={{
            display: 'inline-block', opacity: p,
            clipPath: `inset(-20% -5% -20% ${(1 - p) * 100}%)`,
            filter: `blur(${(1 - p) * 10 + extra}px)`,
            translate: `0 ${(1 - p) * size * 0.35}px`,
          }}>{w}</span>
        );
      })}
    </div>
  );
};

// Line icon that draws itself; accent shapes fill in afterwards.
const DrawIcon: React.FC<{at: number; size: number; lines: string[]; accents?: string[]}> = ({at, size, lines, accents = []}) => {
  const f = useCurrentFrame();
  const draw = interpolate(f, [at, at + 22], [0, 1], {...clamp, easing: Easing.inOut(Easing.cubic)});
  const fill = interpolate(f, [at + 16, at + 26], [0, 1], clamp);
  const pop = usePop(at, 10, 0.6);
  return (
    <svg width={size} height={size} viewBox="0 0 100 100" style={{overflow: 'visible', scale: `${0.7 + pop * 0.3}`}}>
      {lines.map((d, i) => (
        <path key={i} d={d} pathLength={1} fill="none" stroke={C.ink} strokeWidth={4.5}
          strokeLinecap="round" strokeLinejoin="round" strokeDasharray={1} strokeDashoffset={1 - draw}/>
      ))}
      {accents.map((d, i) => (
        <path key={i} d={d} fill={C.purple} opacity={fill} style={{transformOrigin: '50% 50%', scale: `${0.6 + fill * 0.4}`}}/>
      ))}
    </svg>
  );
};

const CART = {
  lines: ['M6 16 H20 L30 64 H80 L90 30 H24', 'M34 44 H84'],
  accents: ['M36 80 a7 7 0 1 1 0.1 0 Z', 'M74 80 a7 7 0 1 1 0.1 0 Z'],
};
const SelectBox: React.FC<{at: number; children: React.ReactNode; width: number}> = ({at, children, width}) => {
  const f = useCurrentFrame();
  const p = interpolate(f, [at, at + 14], [0, 1], {...clamp, easing: ease});
  const handle = (pos: React.CSSProperties) => (
    <div style={{position: 'absolute', width: 22, height: 22, background: C.purple, borderRadius: 4, opacity: p, ...pos}}/>
  );
  return (
    <div style={{position: 'relative', width: width * (0.3 + p * 0.7), padding: '26px 30px', opacity: Math.min(1, p * 2)}}>
      <div style={{position: 'absolute', inset: 0, border: `5px dashed ${C.ink}`, borderRadius: 6}}/>
      {handle({left: -11, top: -11})}{handle({right: -11, top: -11})}
      {handle({left: -11, bottom: -11})}{handle({right: -11, bottom: -11})}
      {children}
    </div>
  );
};

const Logo: React.FC<{size: number; at?: number; spin?: boolean}> = ({size, at = 0, spin}) => {
  const p = usePop(at, 11, 0.8);
  return (
    <Img src={staticFile('kinetic/logo.png')} style={{
      width: size, height: size, borderRadius: size * 0.23,
      boxShadow: `0 ${size * 0.12}px ${size * 0.3}px rgba(100,97,252,0.35)`,
      scale: `${p}`, rotate: spin ? `${(1 - p) * -40}deg` : undefined,
    }}/>
  );
};

const Center: React.FC<{children: React.ReactNode; gap?: number; style?: React.CSSProperties}> = ({children, gap = 40, style}) => (
  <AbsoluteFill style={{alignItems: 'center', justifyContent: 'center', flexDirection: 'column', gap, padding: '0 70px', ...style}}>
    {children}
  </AbsoluteFill>
);

/* ---------- scenes ---------- */

// 1) سلّتك جاهزة: a receipt fills up and the total keeps climbing → قبل ما تدفع.. وقف لحظة!
const CART_ITEMS = [{name: 'عطر', price: 220}, {name: 'حذاء رياضي', price: 180}, {name: 'شنطة', price: 86}];
const CART_TOTAL = CART_ITEMS.reduce((sum, item) => sum + item.price, 0);

const ReceiptRow: React.FC<{name: string; price: number; at: number}> = ({name, price, at}) => {
  const f = useCurrentFrame();
  const p = interpolate(f, [at, at + 12], [0, 1], {...clamp, easing: ease});
  return (
    <div style={{
      display: 'flex', flexDirection: 'row-reverse', justifyContent: 'space-between', alignItems: 'center',
      opacity: p, translate: `${(1 - p) * -80}px 0`, fontSize: 54, fontWeight: 700, color: C.text,
    }}>
      <span style={{display: 'flex', flexDirection: 'row-reverse', alignItems: 'center', gap: 20}}>
        <span style={{width: 18, height: 18, borderRadius: '50%', background: C.purple}}/>{name}
      </span>
      <span style={{direction: 'rtl', color: C.muted}}>{price} ريال</span>
    </div>
  );
};

const CartScene: React.FC = () => {
  const f = useCurrentFrame();
  const card = usePop(10, 13, 0.8);
  const total = Math.round(interpolate(f, [30, 78], [0, CART_TOTAL], {...clamp, easing: Easing.out(Easing.cubic)}));
  // The total turns red and throbs while it climbs.
  const heat = interpolate(f, [30, 78, 92], [0, 1, 0.6], clamp);
  return (
    <Center gap={50}>
      <div style={{display: 'flex', flexDirection: 'row-reverse', alignItems: 'center', gap: 26}}>
        <Words text="سلّتك جاهزة" at={2} size={104} color={C.ink}/>
        <DrawIcon at={6} size={130} {...CART}/>
      </div>
      <div style={{
        width: 860, background: C.white, borderRadius: 44, padding: '50px 60px 44px', fontFamily: FONT,
        boxShadow: '0 40px 80px rgba(31,26,92,0.12)', scale: `${card}`, rotate: `${(1 - card) * -6}deg`,
        display: 'flex', flexDirection: 'column', gap: 30,
      }}>
        {CART_ITEMS.map((item, i) => <ReceiptRow key={i} {...item} at={20 + i * 10}/>)}
        <div style={{borderTop: `5px dashed ${C.lav}`, margin: '6px 0'}}/>
        <div style={{display: 'flex', flexDirection: 'row-reverse', justifyContent: 'space-between', alignItems: 'baseline'}}>
          <span style={{fontSize: 60, fontWeight: 800, color: C.ink}}>الإجمالي</span>
          <span style={{
            direction: 'rtl', fontSize: 92, fontWeight: 800,
            color: heat > 0.5 ? '#E5484D' : C.ink,
            scale: `${1 + Math.sin(f / 2.5) * 0.03 * (f < 78 ? 1 : 0)}`,
          }}>{total} ريال</span>
        </div>
      </div>
      <SelectBox at={86} width={880}>
        <Words text="قبل ما تدفع.. وقف لحظة!" at={90} size={68} color={C.purple} style={{flexWrap: 'nowrap', whiteSpace: 'nowrap'}}/>
      </SelectBox>
    </Center>
  );
};

// 2) Search for your store in the app and copy the code with one tap.
const SEARCH_TEXT = 'متجرك المفضل';

const CopyScene: React.FC = () => {
  const f = useCurrentFrame();
  const bar = usePop(28, 14, 0.8);
  const typed = SEARCH_TEXT.slice(0, Math.floor(interpolate(f, [40, 66], [0, SEARCH_TEXT.length], clamp)));
  const caret = Math.floor(f / 8) % 2 === 0 && f > 30 && f < 72;
  const card = usePop(68, 12, 0.7);
  const press = interpolate(f, [94, 98, 104], [1, 0.88, 1], clamp);
  const copied = f >= 98;
  const ripple = interpolate(f, [98, 116], [0, 1], clamp);
  const cursorX = interpolate(f, [78, 94], [300, 0], {...clamp, easing: ease});
  const cursorY = interpolate(f, [78, 94], [260, 20], {...clamp, easing: ease});
  return (
    <Center gap={54}>
      <Words text="افتح وفّرها صح" at={2} size={100} color={C.purple}/>
      <div style={{
        width: 860, height: 140, borderRadius: 999, background: C.white, scale: `${bar}`,
        boxShadow: '0 24px 60px rgba(31,26,92,0.12)', display: 'flex', flexDirection: 'row-reverse',
        alignItems: 'center', padding: '0 24px 0 40px', gap: 28, fontFamily: FONT,
      }}>
        <div style={{width: 96, height: 96, borderRadius: 30, background: C.lav, display: 'flex', alignItems: 'center', justifyContent: 'center'}}>
          <svg width={52} height={52} viewBox="0 0 24 24" fill="none" stroke={C.purple} strokeWidth={2.6} strokeLinecap="round">
            <circle cx={10.5} cy={10.5} r={6.5}/><path d="M15.5 15.5 L21 21"/>
          </svg>
        </div>
        <div style={{direction: 'rtl', fontSize: 58, fontWeight: 700, color: typed ? C.text : C.muted, flex: 1}}>
          {typed || 'ابحث عن متجر'}{caret && <span style={{color: C.purple}}>|</span>}
        </div>
      </div>
      <div style={{
        position: 'relative', width: 860, borderRadius: 44, background: C.white, scale: `${card}`,
        boxShadow: '0 30px 70px rgba(31,26,92,0.14)', padding: 36, display: 'flex', flexDirection: 'row-reverse',
        alignItems: 'center', gap: 34, fontFamily: FONT,
      }}>
        <div style={{flex: 1, direction: 'rtl', display: 'flex', flexDirection: 'column', gap: 10}}>
          <div style={{fontSize: 52, fontWeight: 800, color: C.ink}}>كوبون خصم 15%</div>
          <div style={{fontSize: 40, fontWeight: 500, color: C.muted}}>على جميع المنتجات</div>
          <div style={{
            marginTop: 10, alignSelf: 'flex-start', border: `4px dashed ${C.purple}`, borderRadius: 18,
            padding: '10px 26px 4px', fontSize: 50, fontWeight: 800, color: C.purple, letterSpacing: 4, direction: 'ltr',
          }}>WFR15</div>
        </div>
        <div style={{position: 'relative', scale: `${press}`}}>
          <div style={{
            width: 260, height: 230, borderRadius: 36, color: C.white, fontSize: 44, fontWeight: 800,
            background: copied ? '#22C59A' : `linear-gradient(160deg, ${C.purple}, ${C.deep})`,
            display: 'flex', alignItems: 'center', justifyContent: 'center', textAlign: 'center', direction: 'rtl',
            lineHeight: 1.3,
          }}>{copied ? <>تم النسخ<br/>✓</> : <>انسخ<br/>الكود</>}</div>
          <div style={{
            position: 'absolute', left: '50%', top: '50%', width: 260, height: 260, marginLeft: -130, marginTop: -130,
            borderRadius: '50%', border: `8px solid ${C.purple}`, opacity: copied ? 1 - ripple : 0,
            scale: `${0.5 + ripple * 1.2}`,
          }}/>
          <svg width={110} height={110} viewBox="0 0 24 24" style={{
            position: 'absolute', left: '50%', top: '50%', translate: `${cursorX}px ${cursorY}px`,
            opacity: interpolate(f, [78, 84], [0, 1], clamp), filter: 'drop-shadow(0 8px 10px rgba(0,0,0,0.25))',
          }}>
            <path d="M5 3 L19 12 L12 13.5 L9 20 Z" fill={C.ink} stroke={C.white} strokeWidth={1.4} strokeLinejoin="round"/>
          </svg>
        </div>
      </div>
      <Words text="انسخ الكود بضغطة وحدة" at={88} size={80} color={C.ink}/>
    </Center>
  );
};
// 3) The app in hand: phone rises with the home screen and scrolls.
const Phone: React.FC<{src: string; scroll?: number}> = ({src, scroll = 0}) => (
  <div style={{
    width: 560, height: 1160, borderRadius: 90, background: '#111', padding: 18,
    boxShadow: '0 60px 120px rgba(31,26,92,0.35), inset 0 0 0 3px #333',
  }}>
    <div style={{width: '100%', height: '100%', borderRadius: 74, overflow: 'hidden', position: 'relative', background: C.white}}>
      <Img src={staticFile(src)} style={{width: '100%', translate: `0 ${-scroll}px`}}/>
    </div>
  </div>
);

const AppScene: React.FC = () => {
  const f = useCurrentFrame();
  const rise = interpolate(f, [0, 22], [0, 1], {...clamp, easing: ease});
  const scroll = interpolate(f, [20, 56], [0, 120], {...clamp, easing: Easing.inOut(Easing.cubic)});
  return (
    <AbsoluteFill style={{alignItems: 'center', perspective: 1800}}>
      <div style={{marginTop: 110, display: 'flex', flexDirection: 'row-reverse', alignItems: 'center', gap: 30}}>
        <Logo size={120} at={2}/>
        <Words text="كل العروض في مكان واحد" at={6} size={64} color={C.ink} stagger={3}/>
      </div>
      <div style={{
        marginTop: 70, translate: `0 ${(1 - rise) * 900}px`,
        transform: `rotateX(${(1 - rise) * 30 + 6}deg) rotateZ(${(1 - rise) * -8 - 2}deg)`,
      }}>
        <Phone src="kinetic/screen-home.png" scroll={scroll}/>
      </div>
    </AbsoluteFill>
  );
};

// 4) شوف الفرق: the same receipt total drops once the code is applied.
const SAVED_TOTAL = Math.round(CART_TOTAL * 0.85);

const BillScene: React.FC = () => {
  const f = useCurrentFrame();
  const card = usePop(8, 13, 0.8);
  const strike = interpolate(f, [20, 30], [0, 1], {...clamp, easing: ease});
  const after = Math.round(interpolate(f, [26, 48], [CART_TOTAL, SAVED_TOTAL], {...clamp, easing: Easing.out(Easing.cubic)}));
  const badge = usePop(50, 9, 0.6);
  const glow = 0.5 + Math.sin(f / 5) * 0.5;
  const row = (label: string, children: React.ReactNode) => (
    <div style={{display: 'flex', flexDirection: 'row-reverse', justifyContent: 'space-between', alignItems: 'center'}}>
      <span style={{fontSize: 56, fontWeight: 700, color: C.muted}}>{label}</span>{children}
    </div>
  );
  return (
    <AbsoluteFill style={{alignItems: 'center'}}>
      <div style={{marginTop: 150}}><Logo size={150}/></div>
      <Center gap={56} style={{paddingTop: 120}}>
        <Words text="شوف الفرق بنفسك" at={4} size={96} color={C.ink} blurWord={2} style={{flexWrap: 'nowrap', whiteSpace: 'nowrap'}}/>
        <div style={{
          width: 860, background: C.white, borderRadius: 44, padding: '50px 60px', fontFamily: FONT,
          boxShadow: '0 40px 80px rgba(31,26,92,0.12)', scale: `${card}`,
          display: 'flex', flexDirection: 'column', gap: 34,
        }}>
          {row('قبل الكود', (
            <span style={{position: 'relative', direction: 'rtl', fontSize: 70, fontWeight: 800, color: C.muted}}>
              {CART_TOTAL} ريال
              <span style={{
                position: 'absolute', right: 0, top: '46%', height: 8, borderRadius: 4, background: '#E5484D',
                width: `${strike * 100}%`,
              }}/>
            </span>
          ))}
          <div style={{borderTop: `5px dashed ${C.lav}`}}/>
          {row('بعد الكود', (
            <span style={{direction: 'rtl', fontSize: 104, fontWeight: 800, color: C.purple}}>{after} ريال</span>
          ))}
        </div>
        <div style={{
          background: '#22C59A', color: C.white, fontFamily: FONT, fontWeight: 800, fontSize: 76, direction: 'rtl',
          padding: '18px 60px 8px', borderRadius: 999, scale: `${badge}`, rotate: `${(1 - badge) * 10 - 3}deg`,
          boxShadow: `0 0 ${50 * glow}px rgba(34,197,154,0.55)`,
        }}>وفّرت {CART_TOTAL - SAVED_TOTAL} ريال</div>
      </Center>
    </AbsoluteFill>
  );
};
// 5) التوفير صار أسهل — حمّل وفّرها صح
const Badge: React.FC<{src: string; at: number}> = ({src, at}) => {
  const p = usePop(at, 12, 0.7);
  return <Img src={staticFile(src)} style={{height: 104, scale: `${p}`, translate: `0 ${(1 - p) * 60}px`}}/>;
};

const CtaScene: React.FC = () => {
  const f = useCurrentFrame();
  const float = Math.sin(f / 14) * 12;
  return (
    <Center gap={36}>
      <div style={{translate: `0 ${float}px`}}><Logo size={340} at={0} spin/></div>
      <Words text="التوفير صار أسهل" at={4} size={108} color={C.ink} style={{marginTop: 30}}/>
      <Words text="حمّل وفّرها صح" at={48} size={92} color={C.purple}/>
      <Words text="كوبونات وعروض متاجرك المفضلة في مكان واحد" at={62} size={60} color={C.text} weight={700} stagger={3}/>
      <div style={{display: 'flex', gap: 28, marginTop: 50}}>
        <Badge src="kinetic/app-store.svg" at={76}/>
        <Badge src="kinetic/google-play.svg" at={84}/>
      </div>
    </Center>
  );
};
export const KineticPromo: React.FC = () => {
  const f = useCurrentFrame();
  const musicVol = (frame: number) =>
    interpolate(frame, [0, 15, KINETIC_FRAMES - 40, KINETIC_FRAMES], [0, 0.18, 0.18, 0], clamp);
  const scenes: [number, number, React.FC][] = [
    [S.cart, S.copy, CartScene], [S.copy, S.app, CopyScene], [S.app, S.bill, AppScene],
    [S.bill, S.cta, BillScene], [S.cta, S.end, CtaScene],
  ];
  return (
    <AbsoluteFill style={{background: C.bg1}}>
      <style>{fontsCss}</style>
      <Background/>
      {scenes.map(([from, to, Comp], i) => (
        <Sequence key={i} from={from} durationInFrames={to - from}>
          {/* The last scene holds to the end instead of punching out. */}
          <Scene dur={i === scenes.length - 1 ? to - from + 20 : to - from}><Comp/></Scene>
        </Sequence>
      ))}
      <Audio src={staticFile('assets/soft-music.wav')} volume={musicVol}/>
      <Audio src={staticFile('kinetic/voice.wav')}/>
      {/* Thin progress bar along the bottom edge. */}
      <div style={{
        position: 'absolute', left: 0, bottom: 0, height: 10, background: C.purple,
        width: `${(f / KINETIC_FRAMES) * 100}%`, opacity: 0.85,
      }}/>
    </AbsoluteFill>
  );
};

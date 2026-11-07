import React, {useEffect, useState} from 'react';
import {
  AbsoluteFill, Audio, Easing, Img, Sequence, continueRender, delayRender,
  interpolate, spring, staticFile, useCurrentFrame, useVideoConfig,
} from 'remotion';
import {
  Avatar, AvatarBadge, Bubble, Burst, C, Crop, FONT, Floaters, Headline, Phone, clamp, fontsCss, rtl,
} from './AvatarPromo';

// 15s vertical story reel modelled on the "woman using coupon app" reference:
// problem → avatar has the answer → app → copy coupon → deals → stores → happy shopping → end card.
export const STORY_FRAMES = 450;

const S = {problem: 0, reveal: 66, home: 126, coupons: 216, stores: 276, happy: 326, end: 380};

/* ---------- 1. problem: prices keep climbing ---------- */

const receipt = [['شنطة', '1,299'], ['جزمة', '899'], ['فستان', '649'], ['عطر', '379']];
const tags = [
  {t: '1,299 ريال', x: 40, y: 560, r: -14, d: 4},
  {t: '899 ريال', x: 730, y: 660, r: 12, d: 12},
  {t: '2,450 ريال', x: 60, y: 1260, r: 9, d: 20},
  {t: '649 ريال', x: 760, y: 1380, r: -10, d: 28},
];

const Problem: React.FC = () => {
  const f = useCurrentFrame();
  const {fps} = useVideoConfig();
  const roll = interpolate(f, [6, 40], [0, 1], {...clamp, easing: Easing.out(Easing.cubic)});
  const total = spring({frame: f - 40, fps, config: {damping: 8, mass: 0.5}});
  const shake = f >= 40 && f < 50 ? Math.sin(f * 3.3) * 12 : 0;
  return (
    <AbsoluteFill style={{background: 'linear-gradient(170deg, #E4E1EC, #BDB7CC)', translate: `${shake}px 0`}}>
      <Headline lines={['كل شي صار غالي؟', 'وكل مرة السعر كامل!']} top={150} size={84} highlight={1}/>
      {/* receipt unrolling */}
      <div style={{
        position: 'absolute', top: 470, left: 250, width: 580, height: 230 + 700 * roll, overflow: 'hidden',
        background: '#fff', boxShadow: '0 40px 80px rgba(46,39,121,.25)',
        clipPath: 'polygon(0 0,100% 0,100% calc(100% - 24px),95% 100%,90% calc(100% - 24px),85% 100%,80% calc(100% - 24px),75% 100%,70% calc(100% - 24px),65% 100%,60% calc(100% - 24px),55% 100%,50% calc(100% - 24px),45% 100%,40% calc(100% - 24px),35% 100%,30% calc(100% - 24px),25% 100%,20% calc(100% - 24px),15% 100%,10% calc(100% - 24px),5% 100%,0 calc(100% - 24px))',
      }}>
        <div style={{...rtl, padding: '44px 54px', color: C.ink}}>
          <div style={{fontSize: 52, fontWeight: 700, borderBottom: '4px dashed #D6D2E6', paddingBottom: 24}}>الفاتورة</div>
          {receipt.map(([name, price], i) => (
            <div key={name} style={{
              display: 'flex', justifyContent: 'space-between', fontSize: 48, padding: '26px 0', borderBottom: '2px solid #EEECF5',
              opacity: interpolate(f, [12 + i * 6, 18 + i * 6], [0, 1], clamp),
            }}>
              <span>{name}</span><span style={{fontWeight: 600}}>{price}</span>
            </div>
          ))}
          <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: 24, marginTop: 30, scale: total}}>
            <span style={{fontSize: 50, fontWeight: 700}}>المجموع</span>
            <span style={{fontSize: 60, fontWeight: 700, color: C.red, whiteSpace: 'nowrap'}}>3,226 ريال</span>
          </div>
        </div>
      </div>
      {tags.map((t) => {
        const p = spring({frame: f - t.d, fps, config: {damping: 9, mass: 0.7}});
        return (
          <div key={t.t} style={{
            position: 'absolute', left: t.x, top: t.y, rotate: `${t.r + Math.sin((f + t.d) / 9) * 3}deg`,
            translate: `0 ${interpolate(p, [0, 1], [-900, 0])}px`,
            background: C.red, color: '#fff', borderRadius: 26, padding: '16px 34px', ...rtl, fontSize: 50, fontWeight: 700,
            boxShadow: '0 20px 40px rgba(255,77,109,.35)', border: '5px solid #fff',
          }}>{t.t}</div>
        );
      })}
    </AbsoluteFill>
  );
};

/* ---------- 2. avatar has the answer ---------- */

const LogoScreen: React.FC<{width: number}> = ({width}) => (
  <div style={{
    width, height: width * 2.05, borderRadius: width * 0.16, background: C.night, padding: width * 0.04,
    boxShadow: '0 40px 80px rgba(0,0,0,.4)',
  }}>
    <div style={{
      width: '100%', height: '100%', borderRadius: width * 0.13, overflow: 'hidden',
      background: `radial-gradient(circle at 50% 40%, ${C.purple}, ${C.deep})`,
      display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: width * 0.06,
    }}>
      <Img src={staticFile('story/logo.png')} style={{width: width * 0.62, height: width * 0.62, borderRadius: width * 0.14}}/>
      <div style={{...rtl, color: '#fff', fontSize: width * 0.15, fontWeight: 700}}>وفّرها صح</div>
    </div>
  </div>
);

const Reveal: React.FC = () => {
  const f = useCurrentFrame();
  const {fps} = useVideoConfig();
  const avatarIn = spring({frame: f, fps, config: {damping: 14, mass: 0.8}});
  const phone = spring({frame: f - 14, fps, config: {damping: 10, mass: 0.7}});
  return (
    <AbsoluteFill style={{background: `radial-gradient(circle at 50% 45%, ${C.purple}, ${C.deep} 60%, ${C.night})`}}>
      <Burst opacity={0.1}/>
      <Avatar width={1120} style={{position: 'absolute', left: -20, bottom: -50, translate: `0 ${interpolate(avatarIn, [0, 1], [800, 0])}px`}}
        beats={[{at: 8, kind: 'jump'}, {at: 30, kind: 'nod'}, {at: 48, kind: 'nod'}]}/>
      <Bubble text="لا تشيلين هم… عندي الحل!" delay={6} style={{top: 210, left: 110, right: 110}}/>
      <div style={{
        position: 'absolute', left: 50, top: 560, scale: phone, rotate: `${-10 + Math.sin(f / 10) * 3}deg`,
        translate: `0 ${Math.sin(f / 12) * 14}px`,
      }}>
        <LogoScreen width={250}/>
      </div>
    </AbsoluteFill>
  );
};

/* ---------- 3. app home → copy today's coupon ---------- */

const CheckBurst: React.FC<{at: number; x: number; y: number}> = ({at, x, y}) => {
  const f = useCurrentFrame();
  const {fps} = useVideoConfig();
  const p = spring({frame: f - at, fps, config: {damping: 9, mass: 0.5}});
  const rays = interpolate(f, [at, at + 14], [0, 1], clamp);
  if (f < at) return null;
  return (
    <div style={{position: 'absolute', left: x, top: y}}>
      {Array.from({length: 10}).map((_, i) => (
        <div key={i} style={{
          position: 'absolute', left: 0, top: -4, width: 34, height: 8, borderRadius: 4, background: C.green,
          transformOrigin: '0 50%', rotate: `${i * 36}deg`, translate: `${40 + rays * 50}px 0`, opacity: 1 - rays,
        }}/>
      ))}
      <div style={{
        position: 'absolute', left: -48, top: -48, width: 96, height: 96, borderRadius: 48, scale: p,
        background: C.green, color: '#fff', fontSize: 60, fontWeight: 700, display: 'flex', alignItems: 'center', justifyContent: 'center',
        boxShadow: '0 12px 30px rgba(34,197,154,.5)', border: '5px solid #fff',
      }}>✓</div>
    </div>
  );
};

const Home: React.FC = () => {
  const f = useCurrentFrame();
  const {fps} = useVideoConfig();
  const enter = spring({frame: f, fps, config: {damping: 15, mass: 0.9}});
  const s = 640 / 920;
  const ring = interpolate(f, [26, 36], [0, 1], clamp);
  const tap = interpolate(f, [50, 64], [0, 1], clamp);
  const toast = spring({frame: f - 58, fps, config: {damping: 11, mass: 0.6}});
  return (
    <AbsoluteFill style={{background: `linear-gradient(180deg, ${C.purple}, ${C.deep})`}}>
      <Burst opacity={0.06}/>
      <div style={{
        position: 'absolute', inset: 0, transformOrigin: '540px 1157px',
        transform: `scale(${interpolate(f, [22, 44], [1, 1.4], {...clamp, easing: Easing.inOut(Easing.cubic)})})`,
      }}>
        <div style={{position: 'absolute', top: 430, left: 0, right: 0, display: 'flex', justifyContent: 'center'}}>
          <Phone src="story/home.webp" style={{
            translate: `0 ${interpolate(enter, [0, 1], [1300, 0])}px`,
            transform: `perspective(2400px) rotateX(${interpolate(enter, [0, 1], [25, 0])}deg)`,
          }}>
            <div style={{
              position: 'absolute', left: 30 * s, top: 878 * s, width: 868 * s, height: 296 * s, borderRadius: 50 * s,
              border: `7px solid ${C.yellow}`, opacity: ring, scale: interpolate(ring, [0, 1], [1.15, 1]),
              boxShadow: `0 0 0 ${2000 * ring}px rgba(29,23,96,${0.45 * ring})`,
            }}/>
            <div style={{
              position: 'absolute', left: 625 * s - 50, top: 968 * s - 50, width: 100, height: 100, borderRadius: 50,
              background: 'rgba(107,92,255,.35)', border: '5px solid #fff',
              opacity: tap > 0 && tap < 1 ? 1 - tap : 0, scale: interpolate(tap, [0, 1], [0.3, 1.8]),
            }}/>
            <CheckBurst at={56} x={430 * s} y={1030 * s}/>
          </Phone>
        </div>
      </div>
      <AbsoluteFill style={{opacity: interpolate(f, [22, 32], [1, 0], clamp)}}>
        <Headline lines={['كوبون جديد', 'كل يوم بانتظارك']} top={110} color="#fff" size={92} highlight={1}/>
      </AbsoluteFill>
      <AvatarBadge size={210} style={{position: 'absolute', left: 30, top: 1330, scale: spring({frame: f - 6, fps, config: {damping: 11}})}}
        beats={[{at: 30, kind: 'nod'}, {at: 58, kind: 'jump'}, {at: 78, kind: 'nod'}]}/>
      <div style={{
        position: 'absolute', bottom: 150, left: 0, right: 0, display: 'flex', justifyContent: 'center',
        scale: toast, opacity: interpolate(toast, [0, 0.3], [0, 1], clamp),
      }}>
        <div style={{display: 'flex', alignItems: 'center', gap: 22, background: C.night, color: '#fff', borderRadius: 60, padding: '26px 50px', ...rtl, fontSize: 50, fontWeight: 600, boxShadow: '0 25px 60px rgba(0,0,0,.4)'}}>
          <span style={{width: 62, height: 62, borderRadius: 31, background: C.green, display: 'inline-flex', alignItems: 'center', justifyContent: 'center', fontSize: 40}}>✓</span>
          تم نسخ الكود <span style={{fontWeight: 700, color: C.yellow, direction: 'ltr'}}>Xx97</span>
        </div>
      </div>
    </AbsoluteFill>
  );
};

/* ---------- 4. coupons list ---------- */

const Coupons: React.FC = () => {
  const f = useCurrentFrame();
  const {fps} = useVideoConfig();
  const enter = spring({frame: f, fps, config: {damping: 14}});
  const chips = [
    {t: '25%', sub: 'سالا', x: 40, y: 640, r: -8, d: 8},
    {t: '20%', sub: 'الشمس والرمال', x: 690, y: 900, r: 7, d: 16},
    {t: '10%', sub: 'برفيوم كو', x: 50, y: 1180, r: -5, d: 24},
    {t: '10%', sub: 'ذي بدي شوب', x: 720, y: 1440, r: 6, d: 32},
  ];
  return (
    <AbsoluteFill style={{background: `linear-gradient(170deg, ${C.lav}, #fff 60%, #E3DEFF)`}}>
      <Floaters color={C.purple}/>
      <Headline lines={['خصومات حقيقية', 'لمتاجرك المفضّلة']} top={110} size={92} highlight={1}/>
      <div style={{position: 'absolute', top: 470, left: 0, right: 0, display: 'flex', justifyContent: 'center'}}>
        <Phone src="story/coupons.webp" width={560} zoom={interpolate(f, [0, 60], [1, 1.06])} style={{
          scale: interpolate(enter, [0, 1], [0.6, 1]), rotate: `${interpolate(enter, [0, 1], [-12, 0])}deg`,
          opacity: interpolate(enter, [0, 0.3], [0, 1], clamp),
        }}/>
      </div>
      {chips.map((b, i) => {
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

/* ---------- 5. stores grid ---------- */

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
      <Headline lines={['كل متاجرك', 'في مكان واحد']} top={150} color="#fff" size={96} highlight={1}/>
      <div style={{position: 'absolute', top: 560, left: 70, right: 70, display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 36, direction: 'rtl'}}>
        {logos.map((l, i) => {
          const p = spring({frame: f - 4 - i * 3, fps, config: {damping: 10, mass: 0.6}});
          return (
            <div key={i} style={{
              background: '#fff', borderRadius: 48, height: 290, display: 'flex', alignItems: 'center', justifyContent: 'center',
              scale: p, rotate: `${interpolate(p, [0, 1], [i % 2 ? 20 : -20, 0])}deg`, boxShadow: '0 22px 50px rgba(0,0,0,.28)',
              translate: `0 ${Math.sin((f + i * 9) / 16) * 8}px`,
            }}>
              <Crop src="story/stores.webp" x={l.x} y={l.y} w={230} h={200} scale={1.05}/>
            </div>
          );
        })}
      </div>
    </AbsoluteFill>
  );
};

/* ---------- 6. happy shopping ---------- */

const bokeh = Array.from({length: 16}).map((_, i) => ({
  x: (i * 263) % 1080, y: (i * 547) % 1500, r: 60 + ((i * 37) % 120), c: i % 3 === 0 ? '#FFE9A8' : i % 3 === 1 ? '#FFFFFF' : '#D9CFFF',
}));
const bags = [
  {x: 20, bottom: 170, c: C.purple, h: 300, d: 6, r: -8},
  {x: 210, bottom: 120, c: C.yellow, h: 240, d: 12, r: 6},
  {x: 800, bottom: 160, c: '#FF8FB1', h: 290, d: 9, r: 8},
  {x: 640, bottom: 110, c: '#fff', h: 230, d: 15, r: -5},
];
const confetti = Array.from({length: 26}).map((_, i) => ({
  x: (i * 173) % 1080, d: (i * 7) % 30, c: [C.yellow, C.purple, '#FF8FB1', C.green][i % 4], s: 0.8 + ((i * 13) % 10) / 20,
}));

const Bag: React.FC<{color: string; h: number}> = ({color, h}) => (
  <div style={{position: 'relative', width: h * 0.82, height: h}}>
    <div style={{
      position: 'absolute', left: '28%', width: '44%', height: h * 0.32, top: -h * 0.2,
      border: `${h * 0.04}px solid ${color === '#fff' ? C.purple : color}`, borderBottom: 'none', borderRadius: `${h}px ${h}px 0 0`,
    }}/>
    <div style={{
      position: 'absolute', inset: 0, background: color, borderRadius: h * 0.06, boxShadow: '0 24px 50px rgba(0,0,0,.25)',
      display: 'flex', alignItems: 'center', justifyContent: 'center',
    }}>
      <Img src={staticFile('story/logo.png')} style={{width: h * 0.42, height: h * 0.42, borderRadius: h * 0.1}}/>
    </div>
  </div>
);

const Happy: React.FC = () => {
  const f = useCurrentFrame();
  const {fps} = useVideoConfig();
  return (
    <AbsoluteFill style={{background: 'linear-gradient(180deg, #F7EEE4, #E7DCF7)', overflow: 'hidden'}}>
      {bokeh.map((b, i) => (
        <div key={i} style={{
          position: 'absolute', left: b.x - b.r, top: b.y - b.r + Math.sin((f + i * 10) / 20) * 20, width: b.r * 2, height: b.r * 2,
          borderRadius: '50%', background: b.c, opacity: 0.55, filter: 'blur(14px)',
        }}/>
      ))}
      <Headline lines={['وفّرتي…', 'وتسوّقتي براحتك!']} top={130} size={104} highlight={1}/>
      <Avatar width={1000} style={{position: 'absolute', left: 40, bottom: -40}} glow="#FFE9A8"
        beats={[{at: 4, kind: 'jump'}, {at: 26, kind: 'nod'}, {at: 44, kind: 'nod'}]}/>
      {bags.map((b, i) => {
        const p = spring({frame: f - b.d, fps, config: {damping: 9, mass: 0.6}});
        return (
          <div key={i} style={{
            position: 'absolute', left: b.x, bottom: b.bottom, scale: p, transformOrigin: '50% 0%',
            rotate: `${b.r + Math.sin((f + i * 8) / 7) * 4}deg`,
          }}>
            <Bag color={b.c} h={b.h}/>
          </div>
        );
      })}
      {confetti.map((c, i) => (
        <div key={i} style={{
          position: 'absolute', left: c.x + Math.sin((f + i) / 6) * 20, top: -40 + (f - c.d) * 26 * c.s,
          width: 22, height: 34, borderRadius: 5, background: c.c, rotate: `${(f + i * 20) * 9}deg`, opacity: f > c.d ? 1 : 0,
        }}/>
      ))}
    </AbsoluteFill>
  );
};

/* ---------- 7. end card (split screen like the reference) ---------- */

const End: React.FC = () => {
  const f = useCurrentFrame();
  const {fps} = useVideoConfig();
  const split = spring({frame: f, fps, config: {damping: 16}});
  const logo = spring({frame: f - 8, fps, config: {damping: 9, mass: 0.6}});
  const cta = spring({frame: f - 22, fps, config: {damping: 10, mass: 0.6}});
  const pulse = f > 34 ? 1 + Math.max(0, Math.sin((f - 34) / 5)) * 0.05 : 1;
  const img = 1050;
  return (
    <AbsoluteFill style={{background: C.purple}}>
      <div style={{position: 'absolute', top: 0, bottom: 0, left: 0, width: 540, background: C.deep, translate: `${interpolate(split, [0, 1], [-540, 0])}px 0`}}/>
      <div style={{position: 'absolute', left: 0, width: 540, top: 470, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 34}}>
        <Img src={staticFile('story/logo.png')} style={{
          width: 330, height: 330, borderRadius: 80, scale: logo, rotate: `${interpolate(logo, [0, 1], [-25, 0])}deg`,
          boxShadow: '0 30px 70px rgba(0,0,0,.35)',
        }}/>
        <div style={{...rtl, color: '#fff', fontSize: 92, fontWeight: 700, opacity: interpolate(logo, [0, 0.5], [0, 1], clamp)}}>وفّرها صح</div>
      </div>
      <div style={{
        position: 'absolute', right: 0, top: 360, width: 500, height: 760, borderRadius: '60px 0 0 60px', overflow: 'hidden',
        background: `linear-gradient(180deg, #E9E4FF, #C9BFFF)`, translate: `${interpolate(split, [0, 1], [560, 0])}px 0`,
        boxShadow: '0 30px 70px rgba(0,0,0,.3)',
      }}>
        <Img src={staticFile('promo/avatar.webp')} style={{
          position: 'absolute', width: img, height: img * 1268 / 1241, left: 250 - img * 0.53, top: 40 + Math.sin(f / 14) * 6,
        }}/>
      </div>
      <div style={{position: 'absolute', bottom: 330, left: 0, right: 0, ...rtl, color: '#fff', fontSize: 150, fontWeight: 700, scale: cta * pulse}}>
        حمّلي الآن
      </div>
      <div style={{
        position: 'absolute', bottom: 220, left: 0, right: 0, ...rtl, color: '#fff', fontSize: 48, fontWeight: 500,
        opacity: interpolate(f, [30, 40], [0, 1], clamp),
      }}>
        وكل مشترياتك… وفّريها صح
      </div>
    </AbsoluteFill>
  );
};

/* ---------- root ---------- */

// Circular reveal at each cut, echoing the reference's quick hard cuts with a bit more polish.
const CircleIn: React.FC<{children: React.ReactNode; skip?: boolean}> = ({children, skip}) => {
  const f = useCurrentFrame();
  const r = skip ? 150 : interpolate(f, [0, 9], [0, 150], {...clamp, easing: Easing.in(Easing.quad)});
  return <AbsoluteFill style={{clipPath: `circle(${r}% at 50% 50%)`}}>{children}</AbsoluteFill>;
};

export const StoryVideo: React.FC = () => {
  const {fps} = useVideoConfig();
  const [handle] = useState(() => delayRender('Loading Readex Pro'));
  useEffect(() => {
    Promise.all([400, 500, 600, 700].map((w) => document.fonts.load(`${w} 100px "Readex Pro"`, 'وفرها صح')))
      .then(() => continueRender(handle), () => continueRender(handle));
  }, [handle]);

  const scenes: [number, number, React.FC][] = [
    [S.problem, S.reveal, Problem], [S.reveal, S.home, Reveal], [S.home, S.coupons, Home],
    [S.coupons, S.stores, Coupons], [S.stores, S.happy, Stores], [S.happy, S.end, Happy], [S.end, STORY_FRAMES, End],
  ];
  return (
    <AbsoluteFill style={{background: C.night, fontFamily: FONT}}>
      <style>{fontsCss}</style>
      {scenes.map(([from, to, Scene], i) => (
        <Sequence key={i} from={from} durationInFrames={to - from} premountFor={fps}>
          <CircleIn skip={i === 0}><Scene/></CircleIn>
        </Sequence>
      ))}
      <Audio
        src={staticFile('assets/soft-music.wav')}
        volume={(f) => interpolate(f, [0, 6, STORY_FRAMES - 30, STORY_FRAMES], [0, 0.9, 0.9, 0], clamp)}
      />
    </AbsoluteFill>
  );
};

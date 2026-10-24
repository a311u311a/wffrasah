import React, {useEffect, useState} from 'react';
import {AbsoluteFill, Audio, continueRender, delayRender, staticFile, useCurrentFrame, useVideoConfig} from 'remotion';
import {reelCss, reelHtml} from './reel-markup';

export const REEL_SECONDS = 22.08;

// Freeze every CSS animation and seek it to the current frame via --t (seconds).
const seekCss = `
.stage,.stage *{animation-play-state:paused!important}
.stage,.sc,.a,.decoW,.decoP,.fl1,.bob,.pulse,.prog{animation-delay:calc(var(--t) * -1s)!important}
.fl2{animation-delay:calc(var(--t) * -1s - 2s)!important}
.fl3{animation-delay:calc(var(--t) * -1s - 4s)!important}
`;

const fontsCss = `@font-face{font-family:'Readex Pro';src:url('${staticFile('reel/ReadexPro.ttf')}') format('truetype');font-weight:160 700;font-display:block}`;

const html = reelHtml
  .split('/_blob/25bc560e62955389631f69b10618f6f0').join(staticFile('reel/logo.png'))
  .split('/_blob/81f264d9c2dd2fab03b8ce37f58c94fd').join(staticFile('reel/home.webp'))
  .split('/_blob/76fa5c9b40c30c164e520d6ef1500cb4').join(staticFile('reel/coupons.webp'))
  .split('/_blob/f43ac8923954a4dfeb3d20629dea22a4').join(staticFile('reel/stores.webp'));

export const VoiceReel: React.FC = () => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const [handle] = useState(() => delayRender('Loading Readex Pro'));

  useEffect(() => {
    Promise.all([
      document.fonts.load('700 100px "Readex Pro"', 'وفرها صح'),
      document.fonts.load('600 100px "Readex Pro"', 'وفرها صح'),
      document.fonts.load('400 100px "Readex Pro"', 'وفرها صح'),
    ]).then(() => continueRender(handle), () => continueRender(handle));
  }, [handle]);

  return (
    <AbsoluteFill style={{['--t' as string]: String(frame / fps)}}>
      <style>{fontsCss + reelCss + seekCss}</style>
      <div dangerouslySetInnerHTML={{__html: html}} />
      <Audio src={staticFile('reel/voice.wav')} />
    </AbsoluteFill>
  );
};

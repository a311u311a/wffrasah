import React from 'react';
import {Composition, registerRoot} from 'remotion';
import {WafrahSah} from './video';
import {REEL_SECONDS, VoiceReel} from './VoiceReel';
import {AvatarPromo, PROMO_FRAMES} from './AvatarPromo';
import {KINETIC_FRAMES, KineticPromo} from './KineticPromo';
import {UGC_FRAMES, UgcVideo} from './UgcVideo';

const Root: React.FC = () => (
  <>
    <Composition id="WafrahSahSocial" component={WafrahSah} durationInFrames={540} fps={30} width={1080} height={1920}/>
    <Composition id="WaffrhaVoiceReel" component={VoiceReel} durationInFrames={Math.ceil(REEL_SECONDS * 30)} fps={30} width={1080} height={1920}/>
    <Composition id="WaffrhaKineticPromo" component={KineticPromo} durationInFrames={KINETIC_FRAMES} fps={30} width={1080} height={1920}/>
    <Composition id="WaffrhaAvatarPromo" component={AvatarPromo} durationInFrames={PROMO_FRAMES} fps={30} width={1080} height={1920}/>
    <Composition id="WaffrhaUGC" component={UgcVideo} durationInFrames={UGC_FRAMES} fps={30} width={1080} height={1920}/>
  </>
);
registerRoot(Root);

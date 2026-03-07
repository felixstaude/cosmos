import starVertSrc from './shaders/star.vert.glsl';
import starFragSrc from './shaders/star.frag.glsl';
import planetVertSrc from './shaders/planet.vert.glsl';
import atmoVertSrc from './shaders/atmosphere.vert.glsl';
import atmoFragSrc from './shaders/atmosphere.frag.glsl';
import ringVertSrc from './shaders/ring.vert.glsl';
import ringFragSrc from './shaders/ring.frag.glsl';

import lavaFrag from './shaders/planets/lava.frag.glsl';
import terrestrialFrag from './shaders/planets/terrestrial.frag.glsl';
import gasGiantFrag from './shaders/planets/gas-giant.frag.glsl';
import iceFrag from './shaders/planets/ice.frag.glsl';
import iceGiantFrag from './shaders/planets/ice-giant.frag.glsl';
import desertFrag from './shaders/planets/desert.frag.glsl';
import oceanFrag from './shaders/planets/ocean.frag.glsl';
import toxicFrag from './shaders/planets/toxic.frag.glsl';
import carbonFrag from './shaders/planets/carbon.frag.glsl';

export const STAR_VERT = starVertSrc;
export const STAR_FRAG = starFragSrc;
export const PLANET_VERT = planetVertSrc;
export const ATMO_VERT = atmoVertSrc;
export const ATMO_FRAG = atmoFragSrc;
export const RING_VERT = ringVertSrc;
export const RING_FRAG = ringFragSrc;

const PLANET_FRAGS = [
  lavaFrag,
  terrestrialFrag,
  gasGiantFrag,
  iceFrag,
  iceGiantFrag,
  desertFrag,
  oceanFrag,
  toxicFrag,
  carbonFrag,
];

export function getPlanetFrag(index) {
  return PLANET_FRAGS[index];
}

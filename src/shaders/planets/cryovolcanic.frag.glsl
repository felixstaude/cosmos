uniform float uTime;
uniform vec3 uColor;
uniform vec3 uLightDir;
varying vec2 vUv;
varying vec3 vNormal;
varying vec3 vViewPos;

#include "../noise.glsl"

void main(){
  vec3 p = vec3(vUv * 10.0, uTime * 0.015);

  // Ice surface base — blue-white with fbm variation
  float n = fbm(p);
  float n2 = fbm(p * 2.0 + 3.0);
  vec3 iceWhite = vec3(0.82, 0.9, 0.96);
  vec3 iceBlue = vec3(0.45, 0.6, 0.78);
  vec3 deepIce = vec3(0.25, 0.4, 0.62);
  vec3 col = mix(iceBlue, iceWhite, n);
  col = mix(col, deepIce, n2 * 0.3);

  // Fissure network — Voronoi-like cracks using noise edge detection
  float crackNoise = noise(vec3(vUv * 14.0, 0.5));
  float crackEdge = abs(crackNoise - 0.5) * 2.0;
  float fissure = 1.0 - smoothstep(0.02, 0.12, crackEdge);

  // Second layer of finer cracks
  float crackNoise2 = noise(vec3(vUv * 28.0 + 7.0, 1.5));
  float crackEdge2 = abs(crackNoise2 - 0.5) * 2.0;
  float fissure2 = 1.0 - smoothstep(0.03, 0.1, crackEdge2);

  float totalFissure = max(fissure, fissure2 * 0.6);

  // Glowing cyan fissure color with pulsing animation
  vec3 cyanGlow = vec3(0.1, 0.85, 0.95);
  float pulse = sin(uTime * 0.5 + crackNoise * 6.0) * 0.3 + 0.7;
  col = mix(col, cyanGlow, totalFissure * pulse);

  // Subsurface cyan glow bleeding through near cracks
  float subsurface = 1.0 - smoothstep(0.0, 0.25, crackEdge);
  float subsurface2 = 1.0 - smoothstep(0.0, 0.2, crackEdge2);
  float totalSub = max(subsurface, subsurface2 * 0.5);
  col = mix(col, vec3(0.15, 0.55, 0.7), totalSub * 0.3 * pulse);

  // Geyser eruption spots at fissure intersections
  vec2 g1 = vec2(0.25, 0.4);
  vec2 g2 = vec2(0.6, 0.7);
  vec2 g3 = vec2(0.45, 0.2);
  vec2 g4 = vec2(0.8, 0.45);

  float geyser = 0.0;
  geyser += smoothstep(0.08, 0.0, length(vUv - g1)) * (sin(uTime * 1.2) * 0.5 + 0.5);
  geyser += smoothstep(0.06, 0.0, length(vUv - g2)) * (sin(uTime * 0.9 + 1.5) * 0.5 + 0.5);
  geyser += smoothstep(0.07, 0.0, length(vUv - g3)) * (sin(uTime * 1.5 + 3.0) * 0.5 + 0.5);
  geyser += smoothstep(0.05, 0.0, length(vUv - g4)) * (sin(uTime * 1.1 + 4.5) * 0.5 + 0.5);

  vec3 geyserColor = vec3(0.3, 0.95, 1.0);
  col = mix(col, geyserColor, geyser * 0.8);

  // Diffuse lighting
  float diff = max(dot(vNormal, uLightDir), 0.0) * 0.6 + 0.4;
  col *= diff;

  // Specular — icy reflections
  float spec = pow(max(dot(reflect(-uLightDir, vNormal), normalize(-vViewPos)), 0.0), 48.0);
  col += vec3(0.9, 0.95, 1.0) * spec * 0.6;

  // Fissure emission not affected by lighting — add back glow
  col += cyanGlow * totalFissure * pulse * 0.25 * (1.0 - diff);
  col += geyserColor * geyser * 0.3 * (1.0 - diff);

  // Rim glow — cold blue atmosphere
  float rim = 1.0 - max(dot(vNormal, normalize(-vViewPos)), 0.0);
  col += vec3(0.3, 0.6, 0.85) * pow(rim, 3.0) * 0.45;

  gl_FragColor = vec4(col, 1.0);
}

uniform float uTime;
uniform vec3 uColor;
uniform vec3 uLightDir;
varying vec2 vUv;
varying vec3 vNormal;
varying vec3 vViewPos;

#include "../noise.glsl"

void main(){
  vec2 uv = vUv;
  float lat = uv.y;
  float lon = uv.x;

  // Layered cloud bands flowing at different speeds
  float band1 = sin(lat * 30.0 + fbm(vec3(lon * 6.0 + uTime * 0.04, lat * 10.0, uTime * 0.01)) * 3.0) * 0.5 + 0.5;
  float band2 = sin(lat * 50.0 + fbm(vec3(lon * 8.0 + uTime * 0.06, lat * 15.0, uTime * 0.015)) * 2.0) * 0.5 + 0.5;
  float band3 = sin(lat * 18.0 + fbm(vec3(lon * 4.0 + uTime * 0.025, lat * 8.0, uTime * 0.008)) * 4.0) * 0.5 + 0.5;

  // Dark purple-grey palette
  vec3 darkPurple = vec3(0.2, 0.12, 0.28);
  vec3 midGrey = vec3(0.35, 0.3, 0.4);
  vec3 lightPurple = vec3(0.5, 0.38, 0.55);
  vec3 stormDark = vec3(0.15, 0.1, 0.2);

  vec3 col = mix(darkPurple, midGrey, band1);
  col = mix(col, lightPurple, band2 * 0.4);
  col = mix(col, stormDark, band3 * 0.3);

  // Turbulent distortion
  float turb = fbm(vec3(uv * 12.0 + uTime * 0.03, uTime * 0.02));
  col = mix(col, darkPurple, turb * 0.3);

  // Vortex 1 — large primary cyclone
  vec2 eye1 = vec2(0.35, 0.45);
  vec2 d1 = (uv - eye1) * vec2(2.0, 3.0);
  float dist1 = length(d1);
  float angle1 = atan(d1.y, d1.x);
  float swirl1 = fbm(vec3(angle1 * 2.0 + uTime * 0.15 + dist1 * 8.0, dist1 * 6.0, uTime * 0.05));
  float vortex1 = smoothstep(0.8, 0.0, dist1);
  col = mix(col, mix(stormDark, lightPurple, swirl1), vortex1 * 0.7);
  // Bright vortex eye
  float eye1Glow = smoothstep(0.15, 0.0, dist1);
  col = mix(col, vec3(0.55, 0.4, 0.6), eye1Glow * 0.5);

  // Vortex 2 — secondary cyclone
  vec2 eye2 = vec2(0.72, 0.62);
  vec2 d2 = (uv - eye2) * vec2(2.5, 3.5);
  float dist2 = length(d2);
  float angle2 = atan(d2.y, d2.x);
  float swirl2 = fbm(vec3(angle2 * 2.0 - uTime * 0.12 + dist2 * 10.0, dist2 * 5.0, uTime * 0.04));
  float vortex2 = smoothstep(0.6, 0.0, dist2);
  col = mix(col, mix(stormDark, midGrey, swirl2), vortex2 * 0.6);

  // Vortex 3 — small tertiary storm
  vec2 eye3 = vec2(0.55, 0.28);
  vec2 d3 = (uv - eye3) * vec2(3.0, 4.0);
  float dist3 = length(d3);
  float angle3 = atan(d3.y, d3.x);
  float swirl3 = fbm(vec3(angle3 * 3.0 + uTime * 0.18 + dist3 * 12.0, dist3 * 7.0, uTime * 0.06));
  float vortex3 = smoothstep(0.4, 0.0, dist3);
  col = mix(col, mix(stormDark, lightPurple, swirl3), vortex3 * 0.5);

  // Lightning flashes — sporadic bright flashes using high-frequency noise thresholding
  float lightning = fbm(vec3(uv * 40.0, uTime * 0.8));
  float flash = smoothstep(0.83, 0.88, lightning);
  vec3 lightningColor = vec3(0.8, 0.7, 1.0);
  col += lightningColor * flash * 0.6;

  // Lighting
  float diff = max(dot(vNormal, uLightDir), 0.0) * 0.5 + 0.5;
  col *= diff;

  // Specular
  float spec = pow(max(dot(reflect(-uLightDir, vNormal), normalize(-vViewPos)), 0.0), 16.0);
  col += vec3(0.5, 0.4, 0.6) * spec * 0.15;

  // Rim glow — muted purple
  float rim = 1.0 - max(dot(vNormal, normalize(-vViewPos)), 0.0);
  col += vec3(0.4, 0.25, 0.55) * pow(rim, 3.0) * 0.45;

  gl_FragColor = vec4(col, 1.0);
}

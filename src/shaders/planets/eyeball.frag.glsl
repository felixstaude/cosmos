uniform float uTime;
uniform vec3 uColor;
uniform vec3 uLightDir;
varying vec2 vUv;
varying vec3 vNormal;
varying vec3 vViewPos;

#include "../noise.glsl"

void main(){
  vec3 N = normalize(vNormal);
  vec3 L = normalize(uLightDir);
  vec3 V = normalize(-vViewPos);

  // Substellar factor: 1.0 at substellar point, -1.0 on far nightside
  float sunDot = dot(N, L);

  // === Zone colors ===
  // Hot substellar zone — molten red-orange with convection
  vec3 hotCore = vec3(1.0, 0.4, 0.05) * 1.6;
  vec3 hotEdge = vec3(0.9, 0.25, 0.03);
  float convection = fbm(vec3(vUv * 8.0, uTime * 0.06));
  float pulse = sin(uTime * 0.3 + convection * 5.0) * 0.5 + 0.5;
  vec3 hotColor = mix(hotEdge, hotCore, pulse * 0.6 + 0.2);

  // Terminator zone — cloud bands
  float cloudNoise = fbm(vec3(vUv.x * 12.0 + uTime * 0.02, vUv.y * 20.0, uTime * 0.015));
  float cloudBand = sin(vUv.y * 40.0 + cloudNoise * 3.0) * 0.5 + 0.5;
  vec3 cloudWhite = vec3(0.85, 0.88, 0.9);
  vec3 cloudGrey = vec3(0.55, 0.58, 0.62);
  vec3 terminatorColor = mix(cloudGrey, cloudWhite, cloudBand);

  // Cold nightside — frozen blue-white with ice fractures
  vec3 iceBlue = vec3(0.6, 0.75, 0.95);
  vec3 iceDark = vec3(0.15, 0.2, 0.35);
  // Fracture pattern using sharp noise thresholding
  float fracture = fbm(vec3(vUv * 15.0, 0.0));
  float crack = smoothstep(0.48, 0.5, fracture);
  vec3 coldColor = mix(iceBlue, iceDark, crack * 0.6);

  // === Blend zones using sunDot ===
  // Hot zone: sunDot > 0.7, terminator: 0.2-0.7, cold: < 0.2
  float hotMask = smoothstep(0.5, 0.8, sunDot);
  float warmMask = smoothstep(0.1, 0.3, sunDot) * (1.0 - smoothstep(0.5, 0.8, sunDot));
  float coldMask = 1.0 - smoothstep(0.1, 0.3, sunDot);

  vec3 col = hotColor * hotMask + terminatorColor * warmMask + coldColor * coldMask;

  // Emissive glow at substellar point (the "eye")
  float eyeGlow = smoothstep(0.6, 1.0, sunDot);
  col += vec3(1.0, 0.5, 0.1) * eyeGlow * 0.4;

  // Diffuse lighting (subtle — the planet has its own heat glow)
  float diff = max(sunDot, 0.0) * 0.3 + 0.15;
  // Nightside gets very dark except for ice reflectance
  float nightBoost = smoothstep(-0.5, 0.0, sunDot) * 0.2;
  col *= diff + nightBoost;
  // Re-add emissive hot glow (not affected by lighting)
  col += hotColor * hotMask * 0.5;

  // Specular highlight at substellar point
  float spec = pow(max(dot(reflect(-L, N), V), 0.0), 32.0);
  col += vec3(1.0, 0.8, 0.5) * spec * 0.2 * hotMask;

  // Rim/fresnel glow — warm on dayside, cold on nightside
  float rim = 1.0 - max(dot(N, V), 0.0);
  vec3 rimColor = mix(vec3(0.3, 0.5, 0.9), vec3(1.0, 0.3, 0.05), smoothstep(-0.2, 0.5, sunDot));
  col += rimColor * pow(rim, 3.0) * 0.5;

  gl_FragColor = vec4(col, 1.0);
}

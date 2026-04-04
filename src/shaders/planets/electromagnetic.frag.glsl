uniform float uTime;
uniform vec3 uColor;
uniform vec3 uLightDir;
varying vec2 vUv;
varying vec3 vNormal;
varying vec3 vViewPos;

#include "../noise.glsl"

// Voronoi with distance-to-edge for lightning vein patterns
vec2 voronoi(vec2 p, float timeOffset){
  vec2 n = floor(p);
  vec2 f = fract(p);
  float nearest = 8.0;
  float secondNearest = 8.0;
  for(int j = -1; j <= 1; j++){
    for(int i = -1; i <= 1; i++){
      vec2 g = vec2(float(i), float(j));
      vec2 o = vec2(
        noise(vec3(n + g, timeOffset)),
        noise(vec3(n + g + 31.7, timeOffset))
      );
      vec2 r = g + o - f;
      float d = dot(r, r);
      if(d < nearest){
        secondNearest = nearest;
        nearest = d;
      } else if(d < secondNearest){
        secondNearest = d;
      }
    }
  }
  return vec2(sqrt(nearest), sqrt(secondNearest));
}

void main(){
  vec3 N = normalize(vNormal);
  vec3 L = normalize(uLightDir);
  vec3 V = normalize(-vViewPos);

  // === Base stormy atmosphere ===
  vec3 darkIndigo = vec3(0.08, 0.06, 0.18);
  vec3 charcoal = vec3(0.12, 0.1, 0.14);
  float stormCloud = fbm(vec3(vUv * 8.0 + uTime * 0.02, uTime * 0.01));
  vec3 baseColor = mix(darkIndigo, charcoal, stormCloud);

  // Layered cloud bands
  float band = sin(vUv.y * 25.0 + fbm(vec3(vUv.x * 6.0 + uTime * 0.03, vUv.y * 12.0, uTime * 0.008)) * 2.5) * 0.5 + 0.5;
  baseColor = mix(baseColor, darkIndigo * 0.7, band * 0.3);

  // === Lightning network — Voronoi edge detection ===
  vec2 lightningUV = vUv * 12.0;
  float t = uTime * 0.15;
  vec2 vor1 = voronoi(lightningUV, t);
  float edge1 = vor1.y - vor1.x;
  // Sharpen into thin veins
  float vein1 = pow(1.0 - smoothstep(0.0, 0.15, edge1), 4.0);

  // Second layer at different scale for branching detail
  vec2 vor2 = voronoi(lightningUV * 1.8 + 5.0, t * 1.3);
  float edge2 = vor2.y - vor2.x;
  float vein2 = pow(1.0 - smoothstep(0.0, 0.12, edge2), 5.0);

  // Combine veins
  float veins = max(vein1, vein2 * 0.7);

  // Flickering pulse — different frequencies for organic feel
  float flicker1 = sin(uTime * 3.0 + vUv.x * 20.0) * 0.5 + 0.5;
  float flicker2 = sin(uTime * 5.7 + vUv.y * 15.0 + 2.0) * 0.5 + 0.5;
  float flicker = flicker1 * 0.6 + flicker2 * 0.4;
  veins *= 0.4 + flicker * 0.6;

  // Lightning color — electric blue-white
  vec3 lightningColor = vec3(0.5, 0.7, 1.0);
  vec3 lightningBright = vec3(0.85, 0.9, 1.0);
  vec3 lightningGlow = mix(lightningColor, lightningBright, veins) * veins * 2.0;

  // === Aurora bands at poles ===
  float polarFactor = abs(N.y);
  float auroraMask = smoothstep(0.55, 0.8, polarFactor);

  // Aurora color shifts with time — green to violet
  float hueShift = sin(uTime * 0.2 + vUv.x * 10.0) * 0.5 + 0.5;
  vec3 auroraGreen = vec3(0.1, 0.9, 0.3);
  vec3 auroraViolet = vec3(0.6, 0.15, 0.85);
  vec3 auroraColor = mix(auroraGreen, auroraViolet, hueShift);

  // Aurora wave pattern
  float auroraWave = fbm(vec3(vUv.x * 8.0 + uTime * 0.1, polarFactor * 6.0, uTime * 0.05));
  float auroraIntensity = auroraMask * auroraWave * 1.2;
  vec3 aurora = auroraColor * auroraIntensity;

  // === Compose ===
  vec3 col = baseColor;

  // Diffuse lighting — subtle, the planet is mostly self-lit by lightning
  float diff = max(dot(N, L), 0.0) * 0.35 + 0.25;
  col *= diff;

  // Add emissive lightning (not affected by diffuse)
  col += lightningGlow;

  // Add emissive aurora
  col += aurora;

  // Specular
  float spec = pow(max(dot(reflect(-L, N), V), 0.0), 24.0);
  col += vec3(0.3, 0.4, 0.7) * spec * 0.15;

  // Rim glow — electric blue
  float rim = 1.0 - max(dot(N, V), 0.0);
  col += vec3(0.2, 0.35, 0.8) * pow(rim, 3.0) * 0.6;

  gl_FragColor = vec4(col, 1.0);
}

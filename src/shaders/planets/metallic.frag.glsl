uniform float uTime;
uniform vec3 uColor;
uniform vec3 uLightDir;
varying vec2 vUv;
varying vec3 vNormal;
varying vec3 vViewPos;

#include "../noise.glsl"

void main(){
  vec3 p=vec3(vUv*6.0,uTime*0.02);
  float n=fbm(p);
  float n2=fbm(p*2.5+3.0);
  float n3=noise(p*8.0);

  // Iron-gray base with rust-oxide patches
  vec3 iron=vec3(0.45,0.42,0.40);
  vec3 rust=vec3(0.6,0.3,0.1);
  vec3 darkIron=vec3(0.28,0.26,0.25);
  float rustMask=smoothstep(0.35,0.65,n);
  vec3 col=mix(iron,rust,rustMask);
  col=mix(col,darkIron,n2*0.4);

  // Brushed-metal anisotropic normal perturbation
  float grain=noise(vec3(vUv.x*80.0,vUv.y*4.0,0.0));
  vec3 perturbedN=normalize(vNormal+vec3(grain*0.15,0.0,grain*0.1));

  // Diffuse lighting
  float diff=max(dot(perturbedN,uLightDir),0.0)*0.7+0.3;

  // Blinn-Phong specular with high shininess
  vec3 viewDir=normalize(-vViewPos);
  vec3 halfDir=normalize(uLightDir+viewDir);
  float NdotH=max(dot(perturbedN,halfDir),0.0);
  float spec=pow(NdotH,64.0);

  // Fresnel via Schlick approximation (F0 ~0.56 for iron)
  float F0=0.56;
  float NdotV=max(dot(perturbedN,viewDir),0.0);
  float fresnel=F0+(1.0-F0)*pow(1.0-NdotV,5.0);

  // Specular contribution boosted by fresnel
  vec3 specColor=vec3(0.9,0.85,0.8)*spec*fresnel*1.5;

  // Subtle micro-sparkle on polished areas
  float sparkle=smoothstep(0.8,0.95,n3)*spec*0.6;
  specColor+=vec3(1.0,0.95,0.9)*sparkle;

  // Fresnel rim reflection
  float rim=pow(1.0-NdotV,4.0);
  vec3 rimColor=vec3(0.6,0.55,0.5)*rim*fresnel*0.5;

  col=col*diff+specColor+rimColor;

  gl_FragColor=vec4(col,1.0);
}

uniform float uTime;
uniform vec3 uColor;
uniform vec3 uLightDir;
varying vec2 vUv;
varying vec3 vNormal;
varying vec3 vViewPos;

#include "../noise.glsl"

void main(){
  vec3 viewDir=normalize(-vViewPos);
  vec3 n=normalize(vNormal);
  float fresnel=1.0-max(dot(n, viewDir), 0.0);

  // Ultra-dark base surface
  vec3 baseColor=vec3(0.02, 0.015, 0.025);

  // Thermal cracks - ridge noise pattern (1.0 - abs(noise*2-1))
  vec3 crackP=vec3(vUv*10.0, uTime*0.03);
  float n1=noise(crackP)*2.0-1.0;
  float ridge=1.0-abs(n1);
  ridge=pow(ridge, 8.0); // sharpen into thin lines
  // Second layer of cracks at different scale
  vec3 crackP2=vec3(vUv*18.0+5.3, uTime*0.02);
  float n2=noise(crackP2)*2.0-1.0;
  float ridge2=1.0-abs(n2);
  ridge2=pow(ridge2, 10.0);
  float cracks=max(ridge, ridge2*0.6);
  // Slow pulsing
  float pulse=sin(uTime*0.3+fbm(vec3(vUv*3.0, 0.0))*6.0)*0.3+0.7;
  cracks*=pulse;

  // Crack color - dark crimson thermal emission
  vec3 crackColor=vec3(0.25, 0.04, 0.02);
  vec3 surface=baseColor+crackColor*cracks;

  // Subtle dark cloud bands - only visible at grazing angles
  float bands=sin(vUv.y*40.0)*0.5+0.5;
  float bandNoise=noise(vec3(vUv*vec2(6.0, 2.0), uTime*0.02));
  bands=bands*0.5+bandNoise*0.5;
  bands=smoothstep(0.3, 0.7, bands);
  // Only show bands near the limb
  float limbMask=smoothstep(0.3, 0.8, fresnel);
  surface+=vec3(0.03, 0.01, 0.015)*bands*limbMask;

  // Very subtle diffuse lighting - planet absorbs >99% of light
  float diff=max(dot(n, uLightDir), 0.0)*0.05;
  vec3 col=surface*(1.0+diff);

  // Eerie crimson limb glow - strong Fresnel rim light
  vec3 rimColor=vec3(0.4, 0.05, 0.05);
  col+=rimColor*pow(fresnel, 2.0)*1.5;

  // Faint specular for atmosphere sheen
  vec3 halfDir=normalize(uLightDir+viewDir);
  float spec=pow(max(dot(n, halfDir), 0.0), 40.0);
  col+=vec3(0.15, 0.02, 0.02)*spec*fresnel;

  gl_FragColor=vec4(col, 1.0);
}

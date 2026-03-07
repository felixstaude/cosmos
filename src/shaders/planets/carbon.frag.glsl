uniform float uTime;
uniform vec3 uColor;
uniform vec3 uLightDir;
varying vec2 vUv;
varying vec3 vNormal;
varying vec3 vViewPos;

#include "../noise.glsl"

void main(){
  vec3 p=vec3(vUv*8.0,0.7);
  float n=fbm(p);
  float n2=fbm(p*3.0+4.0);
  // Dark graphite base
  vec3 graphite=vec3(0.08,0.07,0.09);
  vec3 darkCarbon=vec3(0.12,0.1,0.14);
  vec3 col=mix(graphite,darkCarbon,n);
  // Subtle purple undertone
  col+=vec3(0.2,0.15,0.25)*n2*0.15;
  // Diamond facets - quantized regions
  float facetNoise=noise(p*4.0);
  float facets=floor(facetNoise*12.0)/12.0;
  // Per-facet glint angle based on light
  float glintAngle=sin(facets*47.0+uTime*0.3)*0.5+0.5;
  float lightAlign=max(dot(vNormal,uLightDir),0.0);
  float glint=smoothstep(0.85,0.95,glintAngle*lightAlign);
  // Sharp specular for diamond sparkle
  vec3 viewDir=normalize(-vViewPos);
  float spec=pow(max(dot(reflect(-uLightDir,vNormal),viewDir),0.0),64.0);
  // Time-varying sparkle
  float sparkle=smoothstep(0.7,0.9,sin(facetNoise*40.0+uTime*1.5)*0.5+0.5);
  vec3 diamondColor=vec3(0.7,0.75,0.9);
  col+=diamondColor*glint*1.2;
  col+=diamondColor*spec*0.6;
  col+=vec3(0.9,0.95,1.0)*sparkle*spec*0.8;
  float diff=max(dot(vNormal,uLightDir),0.0)*0.7+0.3;
  col*=diff;
  // Thin hydrocarbon haze rim
  float rim=1.0-max(dot(vNormal,viewDir),0.0);
  col+=vec3(0.4,0.3,0.15)*pow(rim,3.0)*0.4;
  gl_FragColor=vec4(col,1.0);
}

uniform float uTime;
uniform vec3 uColor;
uniform vec3 uLightDir;
varying vec2 vUv;
varying vec3 vNormal;
varying vec3 vViewPos;

#include "../noise.glsl"

void main(){
  vec3 pos=vec3(vUv*4.0,0.0);

  // Domain-warped fbm for complex plasma filaments
  float warp1=fbm(pos+vec3(uTime*0.12,uTime*0.08,-uTime*0.1));
  float warp2=fbm(pos+vec3(-uTime*0.1,uTime*0.15,uTime*0.07)+warp1*2.0);
  float filament=fbm(pos+warp2*2.5+vec3(uTime*0.05));

  // Concentrated bright arcs using power function
  float arcs=pow(filament,3.0);

  // Secondary fine filaments at different scale
  vec3 pos2=vec3(vUv*8.0,uTime*0.2);
  float fine=fbm(pos2+vec3(warp1*1.5));
  float fineArcs=pow(fine,4.0)*0.6;

  // Color mapping: deep violet -> electric blue -> white-hot/magenta
  vec3 deepViolet=vec3(0.15,0.05,0.3);
  vec3 electricBlue=vec3(0.3,0.4,1.0);
  vec3 hotMagenta=vec3(1.0,0.6,0.9);
  vec3 white=vec3(1.2,1.1,1.3);

  vec3 col=deepViolet;
  col=mix(col,electricBlue,smoothstep(0.2,0.5,filament));
  col=mix(col,hotMagenta,smoothstep(0.5,0.75,filament));
  col=mix(col,white,smoothstep(0.7,0.95,filament));

  // Self-luminous emission — no diffuse shading
  col+=electricBlue*arcs*1.5;
  col+=hotMagenta*fineArcs;

  // Pulsing glow
  float pulse=sin(uTime*1.5+filament*8.0)*0.15+0.85;
  col*=pulse;

  // Strong coronal rim glow
  vec3 viewDir=normalize(-vViewPos);
  float NdotV=max(dot(vNormal,viewDir),0.0);
  float rim=pow(1.0-NdotV,2.0);
  col+=vec3(0.4,0.2,0.8)*rim*1.2;

  // Subtle color tint from uColor
  col*=mix(vec3(1.0),uColor,0.15);

  gl_FragColor=vec4(col,1.0);
}

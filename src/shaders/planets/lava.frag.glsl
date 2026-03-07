uniform float uTime;
uniform vec3 uColor;
uniform vec3 uLightDir;
varying vec2 vUv;
varying vec3 vNormal;
varying vec3 vViewPos;

#include "../noise.glsl"

void main(){
  vec3 p=vec3(vUv*5.0,uTime*0.08);
  float n=fbm(p);
  float cracks=smoothstep(0.42,0.48,n);
  vec3 dark=vec3(0.08,0.02,0.01);
  vec3 lava=vec3(1.0,0.35,0.02)*1.5;
  vec3 hotLava=vec3(1.0,0.85,0.2)*2.0;
  float pulse=sin(uTime*0.5+n*6.0)*0.5+0.5;
  vec3 glow=mix(lava,hotLava,pulse*cracks);
  vec3 col=mix(glow,dark,cracks);
  float diff=max(dot(vNormal,uLightDir),0.0)*0.6+0.4;
  col*=diff;
  float rim=1.0-max(dot(vNormal,normalize(-vViewPos)),0.0);
  col+=vec3(1.0,0.2,0.0)*pow(rim,3.0)*0.8;
  col+=vec3(1.0,0.5,0.1)*(1.0-cracks)*0.3;
  gl_FragColor=vec4(col,1.0);
}

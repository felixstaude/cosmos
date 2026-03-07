uniform float uTime;
uniform vec3 uColor;
uniform vec3 uLightDir;
varying vec2 vUv;
varying vec3 vNormal;
varying vec3 vViewPos;

#include "../noise.glsl"

void main(){
  float lat=vUv.y;
  float bands=sin(lat*40.0)*0.5+0.5;
  float turb=fbm(vec3(vUv.x*10.0+uTime*0.03,lat*20.0,uTime*0.02));
  vec3 c1=vec3(0.85,0.65,0.35);
  vec3 c2=vec3(0.65,0.4,0.2);
  vec3 c3=vec3(0.95,0.85,0.65);
  vec3 c4=vec3(0.55,0.3,0.15);
  vec3 col=mix(c1,c2,bands);
  col=mix(col,c3,turb*0.4);
  col=mix(col,c4,sin(lat*80.0+turb*4.0)*0.3+0.3);
  // Great storm
  float stormDist=length(vec2((vUv.x-0.6)*2.0,vUv.y-0.35)*vec2(3.0,5.0));
  float storm=smoothstep(1.0,0.0,stormDist);
  float stormSwirl=fbm(vec3(vUv*20.0+uTime*0.1,uTime*0.05));
  col=mix(col,vec3(0.9,0.4,0.2),storm*0.6*stormSwirl);
  float diff=max(dot(vNormal,uLightDir),0.0)*0.5+0.5;
  col*=diff;
  float rim=1.0-max(dot(vNormal,normalize(-vViewPos)),0.0);
  col+=vec3(0.9,0.7,0.4)*pow(rim,4.0)*0.3;
  gl_FragColor=vec4(col,1.0);
}

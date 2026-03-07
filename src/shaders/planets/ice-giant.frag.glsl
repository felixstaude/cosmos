uniform float uTime;
uniform vec3 uColor;
uniform vec3 uLightDir;
varying vec2 vUv;
varying vec3 vNormal;
varying vec3 vViewPos;

#include "../noise.glsl"

void main(){
  float lat=vUv.y;
  float bands=sin(lat*25.0+uTime*0.05)*0.5+0.5;
  float turb=fbm(vec3(vUv.x*8.0+uTime*0.02,lat*15.0,uTime*0.015));
  vec3 c1=vec3(0.2,0.45,0.85);
  vec3 c2=vec3(0.15,0.35,0.7);
  vec3 c3=vec3(0.35,0.6,0.95);
  vec3 c4=vec3(0.1,0.25,0.55);
  vec3 col=mix(c1,c2,bands);
  col=mix(col,c3,turb*0.35);
  col=mix(col,c4,sin(lat*50.0+turb*3.0)*0.25+0.25);
  float diff=max(dot(vNormal,uLightDir),0.0)*0.5+0.5;
  col*=diff;
  float rim=1.0-max(dot(vNormal,normalize(-vViewPos)),0.0);
  col+=vec3(0.3,0.5,1.0)*pow(rim,3.5)*0.5;
  gl_FragColor=vec4(col,1.0);
}

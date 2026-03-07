uniform float uTime;
uniform vec3 uColor;
uniform vec3 uLightDir;
varying vec2 vUv;
varying vec3 vNormal;
varying vec3 vViewPos;

#include "../noise.glsl"

void main(){
  vec3 p=vec3(vUv*6.0,uTime*0.04);
  float n=fbm(p);float n2=fbm(p*2.5+1.0);
  vec3 deep=vec3(0.02,0.08,0.3);
  vec3 mid=vec3(0.05,0.2,0.55);
  vec3 shallow=vec3(0.1,0.4,0.7);
  vec3 foam=vec3(0.6,0.75,0.9);
  vec3 col=mix(deep,mid,n);
  col=mix(col,shallow,n2*0.4);
  float waves=sin(vUv.x*60.0+uTime*0.3+n*8.0)*0.5+0.5;
  col=mix(col,foam,waves*0.08);
  float clouds=smoothstep(0.48,0.7,fbm(vec3(vUv*10.0+uTime*0.03,uTime*0.04)));
  col=mix(col,vec3(0.85,0.9,0.95),clouds*0.5);
  float spec=pow(max(dot(reflect(-uLightDir,vNormal),normalize(-vViewPos)),0.0),64.0);
  float diff=max(dot(vNormal,uLightDir),0.0)*0.6+0.4;
  col*=diff;
  col+=vec3(0.7,0.85,1.0)*spec*0.4;
  float rim=1.0-max(dot(vNormal,normalize(-vViewPos)),0.0);
  col+=vec3(0.2,0.4,0.9)*pow(rim,3.0)*0.5;
  gl_FragColor=vec4(col,1.0);
}

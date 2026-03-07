uniform float uTime;
uniform vec3 uColor;
uniform vec3 uLightDir;
varying vec2 vUv;
varying vec3 vNormal;
varying vec3 vViewPos;

#include "../noise.glsl"

void main(){
  vec3 p=vec3(vUv*8.0,uTime*0.02);
  float n=fbm(p);float n2=fbm(p*3.0+5.0);
  float cracks=smoothstep(0.45,0.5,abs(n-0.5)*2.0);
  vec3 ice=vec3(0.7,0.9,0.98);
  vec3 deepIce=vec3(0.3,0.55,0.75);
  vec3 crack=vec3(0.15,0.35,0.65);
  vec3 frost=vec3(0.92,0.96,1.0);
  vec3 col=mix(deepIce,ice,n);
  col=mix(col,frost,n2*0.4);
  col=mix(col,crack,(1.0-cracks)*0.5);
  float spec=pow(max(dot(reflect(-uLightDir,vNormal),normalize(-vViewPos)),0.0),32.0);
  float diff=max(dot(vNormal,uLightDir),0.0)*0.6+0.4;
  col*=diff;
  col+=vec3(0.8,0.9,1.0)*spec*0.5;
  float rim=1.0-max(dot(vNormal,normalize(-vViewPos)),0.0);
  col+=vec3(0.5,0.75,1.0)*pow(rim,3.0)*0.5;
  gl_FragColor=vec4(col,1.0);
}

uniform float uTime;
varying vec2 vUv;
varying vec3 vNormal;

#include "noise.glsl"

void main(){
  vec3 p=vec3(vUv*4.0,uTime*0.15);
  float n=fbm(p)*0.6+fbm(p*3.0+uTime*0.1)*0.4;
  vec3 hot=vec3(1.0,0.95,0.7);
  vec3 warm=vec3(1.0,0.6,0.1);
  vec3 col=mix(warm,hot,n);
  float rim=1.0-max(dot(vNormal,vec3(0.0,0.0,1.0)),0.0);
  col+=vec3(1.0,0.8,0.3)*pow(rim,3.0)*0.5;
  gl_FragColor=vec4(col,1.0);
}

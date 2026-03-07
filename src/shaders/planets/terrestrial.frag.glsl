uniform float uTime;
uniform vec3 uColor;
uniform vec3 uLightDir;
varying vec2 vUv;
varying vec3 vNormal;
varying vec3 vViewPos;

#include "../noise.glsl"

void main(){
  vec3 p=vec3(vUv*6.0,0.5);
  float n=fbm(p);float n2=fbm(p*2.0+3.0);
  float land=smoothstep(0.38,0.52,n);
  vec3 ocean=vec3(0.04,0.15,0.45);
  vec3 shallow=vec3(0.06,0.25,0.5);
  vec3 beach=vec3(0.76,0.7,0.5);
  vec3 grass=vec3(0.15,0.45,0.12);
  vec3 forest=vec3(0.06,0.28,0.05);
  vec3 mountain=vec3(0.45,0.42,0.38);
  vec3 snow=vec3(0.92,0.94,0.96);
  vec3 col=mix(ocean,shallow,smoothstep(0.3,0.38,n));
  col=mix(col,beach,smoothstep(0.38,0.42,n));
  col=mix(col,grass,smoothstep(0.42,0.5,n));
  col=mix(col,forest,smoothstep(0.5,0.58,n));
  col=mix(col,mountain,smoothstep(0.58,0.68,n));
  col=mix(col,snow,smoothstep(0.68,0.75,n));
  float clouds=smoothstep(0.5,0.7,fbm(vec3(vUv*8.0+uTime*0.02,uTime*0.05)));
  col=mix(col,vec3(0.95),clouds*0.6);
  float diff=max(dot(vNormal,uLightDir),0.0)*0.7+0.3;
  col*=diff;
  float rim=1.0-max(dot(vNormal,normalize(-vViewPos)),0.0);
  col+=vec3(0.3,0.5,0.9)*pow(rim,4.0)*0.4;
  gl_FragColor=vec4(col,1.0);
}

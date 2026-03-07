uniform float uTime;
uniform vec3 uColor;
uniform vec3 uLightDir;
varying vec2 vUv;
varying vec3 vNormal;
varying vec3 vViewPos;

#include "../noise.glsl"

void main(){
  vec3 p=vec3(vUv*7.0,0.3);
  float n=fbm(p);float n2=fbm(p*3.0+2.0);
  vec3 sand=vec3(0.85,0.68,0.38);
  vec3 darkSand=vec3(0.65,0.45,0.22);
  vec3 rock=vec3(0.5,0.38,0.25);
  vec3 dunes=vec3(0.92,0.78,0.48);
  vec3 polar=vec3(0.9,0.88,0.85);
  vec3 col=mix(darkSand,sand,n);
  col=mix(col,dunes,n2*0.5);
  col=mix(col,rock,smoothstep(0.6,0.75,n)*0.6);
  float polarCap=smoothstep(0.85,0.95,abs(vUv.y-0.5)*2.0);
  col=mix(col,polar,polarCap);
  float dust=fbm(vec3(vUv*12.0+uTime*0.04,uTime*0.06));
  col=mix(col,vec3(0.85,0.6,0.3),smoothstep(0.55,0.7,dust)*0.25);
  float diff=max(dot(vNormal,uLightDir),0.0)*0.7+0.3;
  col*=diff;
  float rim=1.0-max(dot(vNormal,normalize(-vViewPos)),0.0);
  col+=vec3(0.9,0.6,0.2)*pow(rim,3.0)*0.3;
  gl_FragColor=vec4(col,1.0);
}

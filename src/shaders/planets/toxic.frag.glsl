uniform float uTime;
uniform vec3 uColor;
uniform vec3 uLightDir;
varying vec2 vUv;
varying vec3 vNormal;
varying vec3 vViewPos;

#include "../noise.glsl"

void main(){
  float lat=vUv.y;
  float lon=vUv.x;
  // Dense cloud bands with super-rotation offset
  float bands=sin(lat*35.0+uTime*0.02)*0.5+0.5;
  float turb=fbm(vec3(lon*12.0+uTime*0.06,lat*18.0,uTime*0.03));
  float turb2=fbm(vec3(lon*6.0-uTime*0.04,lat*10.0+2.0,uTime*0.015));
  // Toxic color palette
  vec3 sulfur=vec3(0.85,0.78,0.2);
  vec3 acid=vec3(0.5,0.7,0.1);
  vec3 ochre=vec3(0.4,0.35,0.1);
  vec3 highlight=vec3(0.9,0.95,0.3);
  vec3 col=mix(sulfur,acid,bands);
  col=mix(col,ochre,turb*0.45);
  col=mix(col,highlight,turb2*0.2);
  col=mix(col,ochre*0.6,sin(lat*70.0+turb*5.0)*0.25+0.25);
  // Lightning flashes
  float lightning=smoothstep(0.82,0.85,fbm(vec3(vUv*30.0,uTime*0.8)));
  col+=vec3(0.95,1.0,0.6)*lightning*1.5;
  float diff=max(dot(vNormal,uLightDir),0.0)*0.4+0.6;
  col*=diff;
  // Thick atmospheric rim glow
  float rim=1.0-max(dot(vNormal,normalize(-vViewPos)),0.0);
  col+=vec3(0.7,0.75,0.1)*pow(rim,2.5)*0.7;
  gl_FragColor=vec4(col,1.0);
}

uniform float uTime;
uniform vec3 uColor;
uniform vec3 uLightDir;
varying vec2 vUv;
varying vec3 vNormal;
varying vec3 vViewPos;

#include "../noise.glsl"

void main(){
  vec3 viewDir=normalize(-vViewPos);
  vec3 n=normalize(vNormal);

  // Animated sulfur lava flow patterns - layered FBM at different scales
  vec3 p1=vec3(vUv*4.0, uTime*0.1);
  vec3 p2=vec3(vUv*8.0+3.7, uTime*0.07);
  float flow1=fbm(p1);
  float flow2=fbm(p2);
  float lavaPattern=flow1*0.6+flow2*0.4;

  // Volcanic hotspots - cellular pattern using noise peaks
  vec3 cellP=vec3(vUv*12.0, uTime*0.15);
  float cell=noise(cellP);
  float hotspot=smoothstep(0.72, 0.85, cell);
  float eruption=smoothstep(0.85, 0.95, cell)*sin(uTime*2.0+cell*20.0)*0.5+0.5;

  // Color palette
  vec3 sulfurYellow=vec3(0.91, 0.78, 0.12);
  vec3 lavaOrange=vec3(0.82, 0.38, 0.06);
  vec3 darkCrust=vec3(0.35, 0.28, 0.05);
  vec3 hotWhite=vec3(1.0, 0.95, 0.6);

  // Surface color: mix sulfur crust with lava flows
  float flowMask=smoothstep(0.35, 0.55, lavaPattern);
  vec3 surface=mix(sulfurYellow, darkCrust, flowMask);
  surface=mix(surface, lavaOrange, smoothstep(0.5, 0.7, lavaPattern));

  // Add volcanic hotspot glow
  surface=mix(surface, lavaOrange*1.5, hotspot);
  surface=mix(surface, hotWhite*2.0, eruption*hotspot);

  // Emissive glow from lava regions
  float emissive=(1.0-flowMask)*0.25+hotspot*0.5+eruption*hotspot*1.0;

  // Diffuse lighting
  float diff=max(dot(n, uLightDir), 0.0)*0.7+0.3;
  vec3 col=surface*diff;

  // Add emissive lava glow (not affected by lighting)
  col+=surface*emissive*0.4;

  // Specular highlight on lava lakes
  vec3 halfDir=normalize(uLightDir+viewDir);
  float spec=pow(max(dot(n, halfDir), 0.0), 20.0);
  col+=vec3(1.0, 0.9, 0.5)*spec*0.3*(1.0-flowMask);

  // Fresnel limb haze - yellow-green SO2 atmosphere
  float fresnel=1.0-max(dot(n, viewDir), 0.0);
  vec3 hazeColor=vec3(0.63, 0.69, 0.12);
  col+=hazeColor*pow(fresnel, 2.5)*0.6;

  gl_FragColor=vec4(col, 1.0);
}

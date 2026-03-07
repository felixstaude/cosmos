uniform float uTime;
uniform vec3 uColor;
uniform vec3 uLightDir;
varying vec2 vUv;
varying vec3 vNormal;
varying vec3 vViewPos;

#include "../noise.glsl"

// Voronoi returning (min distance, cell ID)
vec2 voronoi(vec2 uv){
  vec2 cell=floor(uv);
  vec2 frac=fract(uv);
  float minD=10.0;
  float cellId=0.0;
  for(int y=-1;y<=1;y++){
    for(int x=-1;x<=1;x++){
      vec2 neighbor=vec2(float(x),float(y));
      vec2 offset=cell+neighbor;
      vec2 pt=fract(sin(vec2(dot(offset,vec2(127.1,311.7)),dot(offset,vec2(269.5,183.3))))*43758.5453);
      vec2 diff=neighbor+pt-frac;
      float d=dot(diff,diff);
      if(d<minD){
        minD=d;
        cellId=fract(sin(dot(offset,vec2(47.13,157.97)))*2345.67);
      }
    }
  }
  return vec2(sqrt(minD),cellId);
}

void main(){
  vec2 uv=vUv*8.0;
  vec2 vor=voronoi(uv);
  float dist=vor.x;
  float cellId=vor.y;

  // Organic surface base with fbm texture
  float surfaceNoise=fbm(vec3(uv*0.6,cellId*2.0));
  vec3 baseColor=vec3(0.06,0.08,0.04);
  baseColor+=vec3(0.03,0.04,0.02)*surfaceNoise;

  // Network veins — bright at cell edges
  float veins=1.0-smoothstep(0.0,0.12,dist);

  // Bioluminescent vein color cycling through cyan/chartreuse/violet
  vec3 veinColor=0.5+0.5*cos(6.2832*(cellId+uTime*0.3+vec3(0.0,0.33,0.67)));

  // Pulsing brightness along veins
  float pulse=sin(uTime*2.0+cellId*10.0)*0.5+0.5;
  float veinBrightness=veins*mix(0.4,1.0,pulse);

  // Node glow at Voronoi cell centers
  float nodeGlow=exp(-dist*8.0);
  vec3 nodeColor=veinColor*nodeGlow*0.8;

  // Diffuse lighting on base surface
  float diff=max(dot(vNormal,uLightDir),0.0)*0.6+0.4;
  vec3 col=baseColor*diff;

  // Add emissive veins (additive, not affected by diffuse)
  col+=veinColor*veinBrightness*0.9;
  col+=nodeColor;

  // Subtle specular
  vec3 viewDir=normalize(-vViewPos);
  vec3 halfDir=normalize(uLightDir+viewDir);
  float spec=pow(max(dot(vNormal,halfDir),0.0),32.0);
  col+=vec3(0.2,0.4,0.3)*spec*0.3;

  // Organic green rim glow
  float NdotV=max(dot(vNormal,viewDir),0.0);
  float rim=pow(1.0-NdotV,2.5);
  col+=vec3(0.1,0.4,0.2)*rim*0.6;

  // Subtle uColor tint
  col*=mix(vec3(1.0),uColor,0.1);

  gl_FragColor=vec4(col,1.0);
}

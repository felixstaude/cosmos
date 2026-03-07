uniform float uTime;
uniform vec3 uColor;
uniform vec3 uLightDir;
varying vec2 vUv;
varying vec3 vNormal;
varying vec3 vViewPos;

#include "../noise.glsl"

// Simple Voronoi — returns (min distance, cell ID)
vec2 voronoi(vec2 uv){
  vec2 cell=floor(uv);
  vec2 frac=fract(uv);
  float minD=10.0;
  float cellId=0.0;
  for(int y=-1;y<=1;y++){
    for(int x=-1;x<=1;x++){
      vec2 neighbor=vec2(float(x),float(y));
      vec2 offset=cell+neighbor;
      // Pseudo-random point per cell
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
  vec2 uv=vUv*10.0;
  vec2 vor=voronoi(uv);
  float dist=vor.x;
  float cellId=vor.y;

  // Per-facet tilted normal for crystalline look
  float tiltX=sin(cellId*63.7)*0.25;
  float tiltY=cos(cellId*91.3)*0.25;
  vec3 facetN=normalize(vNormal+vec3(tiltX,tiltY,0.0));

  // Base crystal color — pale translucent mineral
  vec3 baseColor=vec3(0.75,0.8,0.9);
  float n=fbm(vec3(uv*0.5,cellId*3.0));
  baseColor=mix(baseColor,vec3(0.85,0.88,0.95),n);

  // Thin-film iridescence based on view angle
  vec3 viewDir=normalize(-vViewPos);
  float NdotV=max(dot(facetN,viewDir),0.0);
  float pathLength=1.0/(NdotV+0.01);
  float freq=3.0;
  vec3 iridescence=0.5+0.5*cos(6.2832*(freq*pathLength*0.1+vec3(0.0,0.33,0.67)));
  // Blend iridescence in — stronger at grazing angles
  float iriStrength=pow(1.0-NdotV,2.0)*0.7+0.15;
  vec3 col=mix(baseColor,iridescence,iriStrength);

  // Facet edge darkening
  float edge=smoothstep(0.0,0.08,dist);
  col*=mix(0.6,1.0,edge);

  // Wrapped diffuse for subsurface glow
  float wrapDiff=max(0.0,dot(facetN,uLightDir)*0.5+0.5);
  vec3 subsurface=vec3(0.5,0.6,0.9)*pow(wrapDiff,2.0)*0.3;

  // Diffuse lighting
  float diff=max(dot(facetN,uLightDir),0.0)*0.65+0.35;

  // Sharp per-facet specular (high exponent)
  vec3 halfDir=normalize(uLightDir+viewDir);
  float NdotH=max(dot(facetN,halfDir),0.0);
  float spec=pow(NdotH,128.0);
  vec3 specColor=vec3(1.0,0.98,0.95)*spec*1.2;

  // Time-varying sparkle per facet
  float sparkle=smoothstep(0.85,0.95,sin(cellId*127.0+uTime*1.2)*0.5+0.5);
  specColor+=vec3(1.0)*sparkle*spec*0.8;

  col=col*diff+specColor+subsurface;

  // Subtle Fresnel rim glow
  float rim=pow(1.0-NdotV,3.0);
  col+=vec3(0.5,0.6,1.0)*rim*0.35;

  gl_FragColor=vec4(col,1.0);
}

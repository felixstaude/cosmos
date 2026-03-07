varying vec3 vNormal;
varying vec3 vViewPos;
void main(){
  vNormal = normalize(normalMatrix * normal);
  vViewPos = (modelViewMatrix * vec4(position,1.0)).xyz;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position,1.0);
}

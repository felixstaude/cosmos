uniform vec3 uColor;
uniform float uIntensity;
varying vec3 vNormal;
varying vec3 vViewPos;
void main(){
  float rim = 1.0 - max(dot(vNormal, normalize(-vViewPos)), 0.0);
  float glow = pow(rim, 3.0) * uIntensity;
  gl_FragColor = vec4(uColor, glow * 0.7);
}

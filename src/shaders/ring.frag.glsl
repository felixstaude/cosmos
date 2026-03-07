uniform vec3 uColor;
uniform float uTime;
varying vec2 vUv;
void main(){
  float r = length(vUv - 0.5) * 2.0;
  if(r < 0.4 || r > 1.0) discard;
  float band1 = smoothstep(0.0, 0.02, abs(sin(r * 40.0))) * 0.6 + 0.4;
  float band2 = smoothstep(0.0, 0.03, abs(sin(r * 25.0 + 1.5))) * 0.3 + 0.7;
  float gap1 = smoothstep(0.0, 0.01, abs(r - 0.62)) * smoothstep(0.0, 0.01, abs(r - 0.74));
  float alpha = band1 * band2 * gap1;
  alpha *= smoothstep(1.0, 0.85, r) * smoothstep(0.4, 0.5, r);
  vec3 col = uColor * (0.8 + 0.2 * sin(r * 60.0));
  gl_FragColor = vec4(col, alpha * 0.55);
}

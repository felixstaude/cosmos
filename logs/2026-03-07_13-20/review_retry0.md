Review complete. **STATUS: PASS** — no issues found.

Key checks performed:
- **No object allocation in animation loop**: `_toSun`, `_lightDir`, `_normalMat` correctly pre-allocated at module scope (lines 966-968), mutated in-place via `.set()`, `.copy()`, `.setFromMatrix4()` (lines 988-990).
- **Efficient GLSL**: Both new shaders use minimal fbm/noise calls. Toxic shader has 3 fbm calls (2 turbulence + 1 lightning), Carbon shader has 1 fbm + 1 noise — all reasonable. `pow(...,64.0)` for diamond specular is standard.
- **Consistent style**: New shaders follow the exact same structure as existing ones (same uniforms, NOISE_LIB inclusion, rim calculation pattern).
- **No dead code**: All variables in both shaders are used. `lon` (line 536) feeds into both turbulence calls.
- **No memory leaks**: No dynamic geometry/material creation in the loop, no unmanaged event listeners.
- **Data consistency**: `atmoColors` array has 9 entries matching 9 planets. Minimap scale 0.7 keeps max orbit (116 * 0.7 = 81.2) within the 88px radius.

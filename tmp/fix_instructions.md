FIX_INSTRUCTIONS:
1. **Remove Google Fonts CDN (line 7):** Delete the Google Fonts `<link>` tag. Only the existing Three.js CDN is allowed per project rules. Use a system/fallback font stack instead (e.g., `font-family: monospace` or `font-family: 'Courier New', monospace`).
2. **Eliminate per-frame object allocations (lines 1019-1021):** Pre-allocate `new THREE.Vector3()` and `new THREE.Matrix3()` once outside the animation loop (e.g., at module scope or alongside other reusable objects) and reuse them each frame instead of creating new instances every iteration.
3. **Remove unused `dt` variable (line 1003):** Delete the `clock.getDelta()` call that assigns to `dt`, since `dt` is never used and interferes with `getElapsedTime()`.

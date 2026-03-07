# Implementation Plan — Venomia & Carbonis

## LOCATION

- **PLANETS array**: lines 179–257 of `src/index.html` — add 2 new entries after Oceanus (index 7 and 8)
- **makePlanetFrag()**: lines 336–510 — add 2 new fragment shaders to the `frags` array (indices 7 and 8)
- **Atmosphere colors array**: line 664–667 — add 2 new entries to match new planet indices
- **data/universe.json**: update with new planet entries
- **data/changelog.md**: append session log

## APPROACH

Both planets use the existing shader architecture: `PLANET_VERT` vertex shader + `NOISE_LIB` noise functions + custom fragment shader per planet type. No new uniforms needed — reuse `uTime`, `uColor`, `uLightDir`. The minimap, orbit lines, interaction, and panel system all work off the `PLANETS` array automatically, so adding entries to the array + corresponding shaders is sufficient.

## CHANGES

1. **Add Venomia planet data** (index 7) to `PLANETS` array after Oceanus (line ~256):
   - `name: 'Venomia'`, `type: 'Toxic World'`, `color: [0.7, 0.82, 0.15]`
   - `radius: 1.4`, `orbitRadius: 110` (spacing of 14 from Oceanus at 96)
   - `orbitSpeed: 0.06`, `rotationSpeed: 0.005` (slow rotation, Venus-like)
   - `tilt: 0.08`, `moons: 0`, `hasRings: false`
   - Stats: Venus-analog (high temp ~735K, crushing pressure ~90atm, sulfuric acid atmosphere)
   - Description emphasizing acid cloud bands, runaway greenhouse, volcanic lightning

2. **Add Carbonis planet data** (index 8) to `PLANETS` array after Venomia:
   - `name: 'Carbonis'`, `type: 'Carbon World'`, `color: [0.25, 0.22, 0.28]`
   - `radius: 1.1`, `orbitRadius: 116` (spacing of 6 from Venomia)
   - `orbitSpeed: 0.05`, `rotationSpeed: 0.012`
   - `tilt: 0.2`, `moons: 1`, `hasRings: false`
   - Stats: exotic carbon chemistry, moderate gravity, hydrocarbon atmosphere
   - Description emphasizing diamond geology, graphite plains, dark glittering surface

3. **Add Venomia fragment shader** (index 7) in `makePlanetFrag` `frags` array after Ocean shader:
   - Thick swirling cloud bands using latitude-based sine patterns (similar to gas giant approach) but with toxic yellow-green palette
   - Two noise layers: slow-moving broad cloud bands + faster turbulent acid storm detail
   - Color palette: sulfuric yellow `(0.85, 0.78, 0.2)`, acid green `(0.5, 0.7, 0.1)`, dark ochre `(0.4, 0.35, 0.1)`, bright toxic highlight `(0.9, 0.95, 0.3)`
   - No surface visible — fully cloud-covered like Venus
   - Rim glow in sickly yellow-green using `pow(rim, 2.5)` for thicker atmospheric rim
   - Occasional brighter "lightning" flashes via high-frequency noise threshold

4. **Add Carbonis fragment shader** (index 8) in `makePlanetFrag` `frags` array after Venomia shader:
   - Dark surface base: graphite black-grey `(0.08, 0.07, 0.09)`
   - Diamond facets: use noise with sharp `step()`/`smoothstep()` thresholds to create angular glinting patches
   - High specular highlights — `pow(..., 64.0)` exponent to simulate diamond/crystal reflections
   - Color palette: dark graphite base, cool blue-white diamond sparkle `(0.7, 0.75, 0.9)`, subtle purple undertone `(0.2, 0.15, 0.25)`
   - Thin haze atmosphere rim in muted amber (hydrocarbon haze)
   - Time-varying sparkle: use `sin(noise * highFreq + uTime)` to make facets glint as planet rotates

5. **Add 2 atmosphere color entries** at line 667 (after the Ocean `[0.2, 0.4, 0.9]` entry):
   - Venomia: `[0.7, 0.75, 0.1]` (toxic yellow-green glow)
   - Carbonis: `[0.4, 0.3, 0.15]` (dim amber hydrocarbon haze)

6. **Update `data/universe.json`** — add both planets to the planets array

7. **Update `data/changelog.md`** — log this session's additions

## GLSL_NOTES

- **Venomia shader**: Latitude-driven banding similar to gas giant (index 2) but denser bands (`sin(lat*35.0)`) and different color map. Add a second turbulence layer with slight x-offset over time to simulate super-rotation of the atmosphere. Use `pow(rim, 2.5)` for thicker atmospheric rim than rocky worlds. Lightning effect: `smoothstep(0.82, 0.85, fbm(highFreqCoord))` creates sparse bright spots.
- **Carbonis shader**: Key challenge is convincing diamond sparkle. Use `floor(noise * N) / N` quantization to create faceted regions. Compute a per-facet "glint angle" from the quantized noise value; when it aligns with the light direction (dot product threshold), emit bright specular flash. Keep base albedo very low (dark graphite). Use higher specular exponent (`pow(..., 64.0)`) than other planets for sharp glints.
- Both shaders reuse the existing `NOISE_LIB` (fbm + noise functions) — no new GLSL utility code needed.

## VALIDATION_CRITERIA

- Both planets render without WebGL errors in the browser console
- Venomia appears as a thick-atmosphere world with swirling yellow-green toxic cloud bands — no surface visible, visually distinct from the gas giant's brown bands
- Carbonis appears dark/black with visible diamond-like sparkle highlights that shift as the planet rotates
- Both planets have visible atmosphere glow halos matching their color themes
- Both appear on the minimap at correct orbital positions
- Clicking each planet opens the detail panel with correct name, type, stats, and description
- Hover tooltip shows correct planet name
- Orbit lines render at correct radii (110, 116) with proper spacing from Oceanus (96)
- Existing 7 planets are completely unchanged in appearance and behavior
- No visual overlap or collision between any planet orbits
- Carbonis moon orbits correctly
- `data/universe.json` contains all 9 planets and matches the in-code data

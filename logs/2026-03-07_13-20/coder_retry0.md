# Coder Log — 2026-03-07 (retry 0)

## Changes Made

### 1. Added Venomia (Toxic World) — PLANETS index 7
- **Orbit**: radius 110, speed 0.06 (14 units from Oceanus at 96)
- **Visual**: Venus-analog with impenetrable sulfuric acid clouds, 735K surface temp
- **Stats**: 0.95 Earth masses, CO2/SO2/H2SO4 atmosphere, 90 atm pressure
- **Shader**: Thick swirling yellow-green cloud bands using latitude-based sine patterns (`sin(lat*35.0)`), two turbulence layers for broad cloud movement and fine storm detail, lightning flashes via `smoothstep(0.82,0.85,fbm(...))` threshold, thick atmospheric rim glow with `pow(rim,2.5)`
- **Palette**: sulfuric yellow, acid green, dark ochre, toxic highlight

### 2. Added Carbonis (Carbon World) — PLANETS index 8
- **Orbit**: radius 116, speed 0.05 (6 units from Venomia)
- **Visual**: Dark graphite surface with diamond facet glints, hydrocarbon atmosphere
- **Stats**: 1.4 Earth masses, CH4/C2H6/CO atmosphere, 0.4 atm, 1 moon
- **Shader**: Quantized noise facets (`floor(noise*12.0)/12.0`) for angular diamond regions, per-facet glint angle with light alignment, high specular exponent (`pow(...,64.0)`) for sharp diamond reflections, time-varying sparkle, thin amber hydrocarbon rim haze
- **Palette**: dark graphite base, cool blue-white diamond sparkle, subtle purple undertone

### 3. Atmosphere colors added
- Venomia: `[0.7, 0.75, 0.1]` — toxic yellow-green glow
- Carbonis: `[0.4, 0.3, 0.15]` — dim amber hydrocarbon haze

### 4. Fixed object allocation in animation loop
- Moved `new THREE.Vector3()`, `new THREE.Matrix3()` out of the per-frame loop into module-level constants (`_toSun`, `_lightDir`, `_normalMat`)
- Uses `.set()`, `.copy()`, `.setFromMatrix4()` for zero-allocation updates

### 5. Adjusted minimap scale
- Changed from 0.82 to 0.7 to accommodate larger orbital radii (116) within the 88px minimap radius

## Why
- No open GitHub issues, so following priority order: add 2 new visually distinct planets
- Both fill gaps in the planet type roster (no toxic/carbon worlds existed)
- Animation loop fix enforces the "no object allocation inside animation loop" constraint

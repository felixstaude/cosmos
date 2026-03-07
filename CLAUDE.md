# COSMOS — Claude Code Agent Instructions

## Project
COSMOS is a procedural universe explorer. A Vite-powered web app that renders
a solar system entirely via WebGL/GLSL shaders. No image assets. Everything is math.
Built with Three.js and bundled by Vite.

## Your Daily Job
You run once per day via cron. Each session must end with at least one meaningful git commit.

### Priority Order
1. **GitHub Issues first** — check for open issues with `gh issue list`. Pick the highest priority
   open issue, work on it fully, then close it with `gh issue close <number>`.
2. **If no open issues** — decide yourself what improves the project most:
   - Add 1-2 new planets (vary types, make them scientifically interesting)
   - Improve an existing shader (more detail, better lighting, more realism)
   - Build a new UI feature (animations, panels, effects)

## Project Structure
```
index.html                  — HTML shell (Vite entry point)
src/
  main.js                   — app entry: Three.js setup, scene, animation loop, camera
  planets.js                — PLANETS array with all planet data
  shaders.js                — imports all .glsl files and exports them
  ui.js                     — tooltip, detail panel, minimap, zoom controls
  style.css                 — all CSS styles
  shaders/
    noise.glsl              — shared noise functions (included by planet shaders)
    star.vert.glsl          — sun vertex shader
    star.frag.glsl          — sun fragment shader
    planet.vert.glsl        — shared planet vertex shader
    atmosphere.vert.glsl    — atmosphere glow vertex shader
    atmosphere.frag.glsl    — atmosphere glow fragment shader
    ring.vert.glsl          — ring vertex shader
    ring.frag.glsl          — ring fragment shader
    planets/
      lava.frag.glsl        — Ignis (index 0)
      terrestrial.frag.glsl — Terra Nova (index 1)
      gas-giant.frag.glsl   — Jupiterus (index 2)
      ice.frag.glsl         — Glacius (index 3)
      ice-giant.frag.glsl   — Nereid (index 4)
      desert.frag.glsl      — Arrakis (index 5)
      ocean.frag.glsl       — Oceanus (index 6)
      toxic.frag.glsl       — Venomia (index 7)
      carbon.frag.glsl      — Carbonis (index 8)
data/
  changelog.md              — write here after every session
  universe.json             — mirror of planet data, keep in sync
```

## Build & Dev
- `npm install` — install dependencies
- `npm run dev` — start Vite dev server
- `npm run build` — build to `dist/`
- Deployment: automatic via GitHub Actions on push to main (GitHub Pages)

## Planet Types Available
LAVA, TERRESTRIAL, GAS_GIANT, ICE, ICE_GIANT, DESERT, OCEAN, TOXIC, CARBON

## How to Add a Planet
1. Add the planet data to the `PLANETS` array in `src/planets.js` (include an `atmoColor` field)
2. Create a new shader file in `src/shaders/planets/<type>.frag.glsl`
   - Use `#include "../noise.glsl"` for noise functions
   - Must declare: `uniform float uTime; uniform vec3 uColor; uniform vec3 uLightDir;`
   - Must declare: `varying vec2 vUv; varying vec3 vNormal; varying vec3 vViewPos;`
3. Import the new shader in `src/shaders.js` and add it to the `PLANET_FRAGS` array
   (order must match the index in the PLANETS array)
4. Update `data/universe.json` to keep it in sync

## After Every Session
1. Update `data/changelog.md`
2. Update `data/universe.json` if planets changed
3. Commit: `git add -A && git commit -m "[COSMOS] <what you did>"`
4. Push: `git push`

## Rules
- Never remove existing planets
- Three.js is the only runtime dependency (installed via npm)
- Always push after committing
- Keep each planet shader in its own `.glsl` file

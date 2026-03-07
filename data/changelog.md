# COSMOS Changelog

## 2025-XX-XX - Initial Commit
- Created COSMOS v1 with 7 planets: Ignis, Terra Nova, Jupiterus, Glacius, Nereid, Arrakis, Oceanus
- Full WebGL/GLSL shader system with unique procedural surfaces per planet type
- Interactive 3D solar system with orbit camera, minimap, tooltips, and detail panel
- Starfield background, sun with dynamic shader, atmosphere glow, rings, and moons

## 2026-03-07 - Two New Planets: Venomia & Carbonis
- Added Venomia (Toxic World) at orbit 110 — Venus-analog with swirling sulfuric acid clouds, yellow-green atmosphere, volcanic lightning, unique GLSL shader with dense toxic cloud bands and rim glow
- Added Carbonis (Carbon World) at orbit 116 — exotic carbon planet with dark graphite surface, diamond facet sparkle shader, hydrocarbon haze atmosphere, 1 moon
- Created data/changelog.md and data/universe.json for project bookkeeping
- Updated minimap scale to accommodate wider solar system
- Removed Google Fonts CDN dependency, switched to system monospace fonts
- Pre-allocated reusable Three.js objects in animation loop to reduce GC pressure

## 2026-03-07 - Migrate to Vite + Modular Architecture
- Migrated from single-file `src/index.html` to Vite-powered modular project
- Split into separate JS modules: `src/main.js`, `src/planets.js`, `src/shaders.js`, `src/ui.js`
- Extracted all CSS to `src/style.css`
- Put each planet shader in its own `.glsl` file under `src/shaders/planets/`
- Shared noise functions in `src/shaders/noise.glsl` with `#include` via vite-plugin-glsl
- Three.js now installed via npm instead of CDN
- Added GitHub Actions workflow for automatic deployment to GitHub Pages on push to main
- Updated CLAUDE.md to reflect new project structure and workflows

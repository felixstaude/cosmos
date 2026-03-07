# COSMOS — Claude Code Agent Instructions

## Project
COSMOS is a procedural universe explorer. A Vite-powered web app that renders
a solar system entirely via WebGL/GLSL shaders. No image assets. Everything is math.
Built with Three.js and bundled by Vite.

## Your Daily Job
You run once per day via cron. Each session must end with at least one meaningful git commit.

### Priority Order
1. **GitHub Issues first** — check for open issues with `gh issue list`. Pick the highest priority
   - open issue, work on it fully, then close it with `gh issue close <number>`.
   - If an issue is assigned, implement EXACTLY what the issue describes.
   - Do not substitute your own ideas. The issue is the specification.
2. **If no open issues** — decide yourself what improves the project most:
   - Add 1-2 new planets/ solar systems (vary types, make them scientifically interesting)
   - Improve an existing shader (more detail, better lighting, more realism)
   - Build a new UI feature (animations, panels, effects)

## Agent System (v4)
The daily pipeline (`scripts/daily_pipeline.sh`) orchestrates multiple specialized agents.
Each agent's full instructions live in `agents/<AGENT_NAME>.md`.

### Agent Pipeline Flow
```
PLANNER -> ARCHITECT -> [CODER_SHADER | CODER_LOGIC | CODER_UI] (parallel)
                                      |
                                 INTEGRATOR
                                      |
                        [TESTER | SECURITY | REVIEWER] (parallel)
                                      |
                                  VALIDATOR
                                      |
                             ISSUE_RESOLVER (if issue)
                                      |
                              SELF_IMPROVER (weekly, Sundays)
```

### Agents
| Agent | File | Role |
|-------|------|------|
| PLANNER | `agents/PLANNER.md` | Decides what to work on, produces plan |
| ARCHITECT | `agents/ARCHITECT.md` | Translates plan into implementation spec |
| CODER_SHADER | `agents/CODER_SHADER.md` | Implements .glsl shader changes only |
| CODER_LOGIC | `agents/CODER_LOGIC.md` | Implements src/main.js, src/planets.js changes only |
| CODER_UI | `agents/CODER_UI.md` | Implements src/ui.js, src/style.css changes only |
| INTEGRATOR | `agents/INTEGRATOR.md` | Merges parallel coder outputs, fixes index alignment |
| TESTER | `agents/TESTER.md` | Verifies correctness, runs build check |
| SECURITY | `agents/SECURITY.md` | Audits for security issues |
| REVIEWER | `agents/REVIEWER.md` | Reviews code quality and performance |
| VALIDATOR | `agents/VALIDATOR.md` | Final pass/fail gate based on all checks |
| ISSUE_RESOLVER | `agents/ISSUE_RESOLVER.md` | Verifies issue requirements are fully met |
| SELF_IMPROVER | `agents/SELF_IMPROVER.md` | Weekly review and improvement of agent instructions |

### Parallel Execution
- The three CODER agents (SHADER, LOGIC, UI) run simultaneously, each scoped to specific files.
- The three CHECK agents (TESTER, SECURITY, REVIEWER) also run in parallel.
- The INTEGRATOR runs after coders finish, merging their work and resolving conflicts.

### Retry Loop
If VALIDATOR fails, fix instructions are fed back to the coders for another attempt (max 4 retries).
If ISSUE_RESOLVER fails, one additional retry cycle targets the missing requirements.

### Self-Improvement Cycle
Every Sunday, the SELF_IMPROVER agent reviews all agent files, recent logs, and failure patterns,
then makes targeted improvements to agent instructions.

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
agents/
  PLANNER.md                — planning agent instructions
  ARCHITECT.md              — architecture agent instructions
  CODER_SHADER.md           — shader coder agent instructions
  CODER_LOGIC.md            — logic coder agent instructions
  CODER_UI.md               — UI coder agent instructions
  INTEGRATOR.md             — integration agent instructions
  TESTER.md                 — testing agent instructions
  SECURITY.md               — security audit agent instructions
  REVIEWER.md               — code review agent instructions
  VALIDATOR.md              — validation gate agent instructions
  ISSUE_RESOLVER.md         — issue requirement verification agent
  SELF_IMPROVER.md          — weekly self-improvement agent
scripts/
  daily_pipeline.sh         — orchestrates the full agent pipeline
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

## Naming Conventions
Planets and solar systems should have realistic, scientifically-inspired names:
- Use real astronomical naming conventions (Kepler-style designations, Greek/Latin roots, constellation references)
- Good: "Proxima Ignis b", "HD 40307 g", "Tau Ceti Crystallis", "Gliese 876 Ferrum"
- Bad: "VULCARA-7", "ZYPHOS PRIME", "COSMOTRON X"
- Names should hint at the planet's physical characteristics through etymology

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

# COSMOS — Claude Code Agent Instructions

## Project
COSMOS is a procedural universe explorer. A single-file web app (`src/index.html`) that renders
a solar system entirely via WebGL/GLSL shaders. No assets. No build step. Everything is math.

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
- `src/index.html` — the entire app, keep everything in this single file
- `data/changelog.md` — write here after every session
- `data/universe.json` — mirror of planet data, keep in sync

## Planet Types Available
LAVA, TERRESTRIAL, GAS_GIANT, ICE, ICE_GIANT, DESERT, OCEAN

## How to Add a Planet
Find the `UNIVERSE_DATA.planets` array in `src/index.html` and add an entry:
```js
{
  id: "unique_id",
  name: "NAME-N",
  type: "TYPE",
  seed: 9999,        // unique integer, don't reuse existing seeds
  orbitRadius: 38,   // keep spacing of 4-6 units between planets
  orbitSpeed: 0.15,
  orbitEcc: 0.06,
  size: 1.0,
  tilt: 0.3,
  rotSpeed: 0.5,
  moons: [{ name: "MOON", radius: 0.1, orbitR: 2.0, speed: 1.2 }],
  hasRings: false,
  discoveredYear: 2400,
  discoveredBy: "Dr. Name"
}
```

## After Every Session
1. Update `data/changelog.md`
2. Update `data/universe.json` if planets changed
3. Commit: `git add -A && git commit -m "[COSMOS] <what you did>"`
4. Push: `git push`

## Rules
- Never split into multiple files — everything stays in `src/index.html`
- Never remove existing planets
- Never add external dependencies except the existing Three.js CDN link
- Always push after committing

FIX_INSTRUCTIONS:
- Update `data/universe.json` lines 166-211: Replace the stale Vulcanis/Prisma entries (indices 7-8) with the actual Venomia (Toxic World) and Carbonis (Carbon World) planet data from `src/index.html` lines 257-278. Copy the exact names, types, seeds, orbit parameters, sizes, colors, moons, descriptions, and discovery info from the source code.
- Update `data/changelog.md`: Add a new session entry for 2026-03-07 documenting the addition of Venomia (Toxic World) and Carbonis (Carbon World) with their unique GLSL shaders. This entry should replace or follow the stale Vulcanis/Prisma entry.
- Optional: Remove the unused variable `const dt = clock.getDelta()` at `src/index.html` line 973, or use it if intended.

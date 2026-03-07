---
TASK: Add two new planets (Volcanic Moon world and Crystalline world), create missing data/changelog.md and data/universe.json files
TYPE: planet
ISSUE_NUMBER: none
DETAILS:
- Add a Volcanic Moon planet ("Vulcanis") at orbitRadius ~110 — a tidally-heated world with dramatic volcanic plumes, sulfur-yellow and dark basalt coloring, with 0 moons and unique lava-flow shader patterns distinct from Ignis
- Add a Crystalline/Exotic planet ("Prisma") at orbitRadius ~124 — a rare mineral world with refractive crystal surface, iridescent purple-teal coloring, small size, high rotation speed, with 1 moon and no rings
- Create data/changelog.md with an entry for the initial commit and today's session
- Create data/universe.json mirroring all 9 planets (existing 7 + 2 new) in structured JSON format
- Ensure new planet shaders produce visually distinct surfaces (Vulcanis: active eruption glow spots + dark crust; Prisma: faceted crystalline noise with spectral highlights)
EXPECTED_RESULT:
- Solar system grows from 7 to 9 planets with two scientifically interesting new types
- Each new planet has a unique visual identity through custom shader noise patterns
- data/ directory is populated with changelog.md and universe.json, establishing proper project bookkeeping
- All planets render correctly with proper orbit spacing and no visual overlap
---

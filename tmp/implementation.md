---
TECHNICAL IMPLEMENTATION PLAN
---

## Overview
Add two new planets (Vulcanis and Prisma) to the COSMOS solar system, plus create data/changelog.md and data/universe.json.

---

## Step 1: Add planet data entries to PLANETS array

**File:** `src/index.html`
**Location:** After Oceanus entry (line 256), before the closing `];` on line 257

Add two new planet objects (append after the Oceanus closing `}`):

```js
,
{
  name: 'Vulcanis', type: 'Volcanic Moon', color: [0.95, 0.75, 0.1],
  radius: 1.1, orbitRadius: 110, orbitSpeed: 0.055, rotationSpeed: 0.012,
  tilt: 0.15, moons: 0, hasRings: false,
  stats: {
    mass: '0.6 M\u2295', radius: '0.82 R\u2295', temp: '890 K',
    gravity: '0.72 g', day: '42.5 h', year: '3.8 yr',
    atmosphere: 'SO\u2082, S\u2082', pressure: '0.3 atm'
  },
  desc: 'A tidally-heated world wracked by constant volcanic eruptions. Sulfur-yellow plumes erupt from fractures in a dark basaltic crust, while lakes of molten sulfur glow beneath a thin toxic atmosphere. Resembling a supercharged Io, its interior is kept molten by gravitational stresses from a nearby binary companion.'
},
{
  name: 'Prisma', type: 'Crystalline World', color: [0.6, 0.3, 0.85],
  radius: 0.9, orbitRadius: 124, orbitSpeed: 0.04, rotationSpeed: 0.04,
  tilt: 0.25, moons: 1, hasRings: false,
  stats: {
    mass: '0.4 M\u2295', radius: '0.7 R\u2295', temp: '55 K',
    gravity: '0.55 g', day: '12.3 h', year: '5.1 yr',
    atmosphere: 'None', pressure: '0 atm'
  },
  desc: 'A rare mineral world whose surface is covered in vast crystalline formations of silicate and metallic oxides. Lacking an atmosphere, the crystals grow undisturbed over millennia, creating a faceted landscape that refracts starlight into iridescent purple and teal spectral displays. High rotation speed causes the surface to shimmer as crystal faces catch the light.'
}
```

This makes planets index 7 (Vulcanis) and index 8 (Prisma).

---

## Step 2: Add two new fragment shaders to makePlanetFrag

**File:** `src/index.html`
**Location:** Inside `makePlanetFrag` function (line 336), in the `frags` array. Add after the Ocean shader (index 6, ending around line 507), before the closing `];` on line 508.

Add a comma after the Ocean shader closing backtick, then add these two shaders:

### Shader 7 - Vulcanis (Volcanic Moon)

Visual goal: Dark basalt crust with bright eruption hotspots and sulfur-yellow lava flows.
MUST be visually distinct from Ignis (index 0): use yellow-orange sulfur coloring (not red-orange), discrete glowing eruption spots (not crack-based), animated eruption pulses, and darker matte basalt crust.

```js
    // 7 - Volcanic Moon
    `uniform float uTime;uniform vec3 uColor;uniform vec3 uLightDir;
    varying vec2 vUv;varying vec3 vNormal;varying vec3 vViewPos;
    ${NOISE_LIB}
    void main(){
      vec3 p=vec3(vUv*6.0,uTime*0.05);
      float n=fbm(p);
      float n2=fbm(p*4.0+10.0);
      vec3 basalt=vec3(0.06,0.04,0.03);
      vec3 darkRock=vec3(0.12,0.08,0.05);
      vec3 col=mix(basalt,darkRock,n*0.8);
      float sulfur=smoothstep(0.55,0.65,n2);
      col=mix(col,vec3(0.7,0.65,0.1),sulfur*0.4);
      float spots=fbm(vec3(vUv*15.0,uTime*0.15));
      float hotspot=smoothstep(0.72,0.78,spots);
      float pulse=sin(uTime*2.0+spots*20.0)*0.5+0.5;
      float flow=fbm(vec3(vUv*10.0,uTime*0.1+5.0));
      float flowLine=smoothstep(0.48,0.52,flow)*(1.0-smoothstep(0.52,0.56,flow));
      vec3 lavaGlow=vec3(1.0,0.8,0.05)*2.0;
      vec3 hotGlow=vec3(1.0,0.5,0.0)*3.0;
      col=mix(col,lavaGlow*0.6,flowLine*0.5);
      col=mix(col,hotGlow,hotspot*pulse*0.8);
      col+=lavaGlow*hotspot*0.3;
      float diff=max(dot(vNormal,uLightDir),0.0)*0.5+0.5;
      float emissive=max(hotspot*pulse,flowLine*0.5);
      col*=mix(diff,1.0,emissive);
      float rim=1.0-max(dot(vNormal,normalize(-vViewPos)),0.0);
      col+=vec3(0.9,0.6,0.0)*pow(rim,3.0)*0.4;
      gl_FragColor=vec4(col,1.0);
    }`,
```

### Shader 8 - Prisma (Crystalline World)

Visual goal: Faceted crystalline surface with iridescent purple-teal highlights.
Uses angular/quantized noise for crystal facets, spectral color shifting based on view angle, strong specular highlights, purple-teal base palette.

```js
    // 8 - Crystalline
    `uniform float uTime;uniform vec3 uColor;uniform vec3 uLightDir;
    varying vec2 vUv;varying vec3 vNormal;varying vec3 vViewPos;
    ${NOISE_LIB}
    void main(){
      vec3 p=vec3(vUv*8.0,0.0);
      vec3 facetP=floor(p*3.0)/3.0;
      float facetN=noise(facetP*5.0);
      float smoothN=fbm(p);
      vec3 purple=vec3(0.4,0.15,0.6);
      vec3 teal=vec3(0.1,0.55,0.55);
      vec3 pale=vec3(0.7,0.6,0.85);
      vec3 dark=vec3(0.08,0.05,0.15);
      vec3 col=mix(purple,teal,facetN);
      col=mix(col,pale,smoothstep(0.6,0.8,facetN)*0.5);
      col=mix(col,dark,smoothstep(0.2,0.0,facetN)*0.4);
      float viewDot=dot(vNormal,normalize(-vViewPos));
      float iriPhase=facetN*6.28+viewDot*4.0+uTime*0.3;
      vec3 iridescent=vec3(
        sin(iriPhase)*0.5+0.5,
        sin(iriPhase+2.09)*0.5+0.5,
        sin(iriPhase+4.18)*0.5+0.5
      );
      col=mix(col,iridescent,0.25);
      vec3 fractP=fract(p*3.0);
      float edge=1.0-smoothstep(0.0,0.08,min(min(fractP.x,fractP.y),1.0-max(fractP.x,fractP.y)));
      col+=vec3(0.6,0.5,0.9)*edge*0.3;
      vec3 reflDir=reflect(-uLightDir,vNormal);
      float spec=pow(max(dot(reflDir,normalize(-vViewPos)),0.0),48.0);
      float spec2=pow(max(dot(reflDir,normalize(-vViewPos)),0.0),16.0);
      float diff=max(dot(vNormal,uLightDir),0.0)*0.6+0.4;
      col*=diff;
      col+=vec3(0.9,0.8,1.0)*spec*0.7;
      col+=iridescent*spec2*0.3;
      float rim=1.0-max(dot(vNormal,normalize(-vViewPos)),0.0);
      col+=vec3(0.5,0.2,0.8)*pow(rim,3.0)*0.4;
      gl_FragColor=vec4(col,1.0);
    }`
```

---

## Step 3: Update atmoColors array

**File:** `src/index.html`
**Location:** Lines 664-667, the `atmoColors` array inside the `PLANETS.forEach` loop

Change from 7 entries to 9 entries. Replace:
```js
const atmoColors = [
  [1.0, 0.3, 0.0], [0.3, 0.5, 0.9], [0.9, 0.7, 0.4],
  [0.5, 0.75, 1.0], [0.3, 0.5, 1.0], [0.9, 0.6, 0.2], [0.2, 0.4, 0.9]
];
```

With:
```js
const atmoColors = [
  [1.0, 0.3, 0.0], [0.3, 0.5, 0.9], [0.9, 0.7, 0.4],
  [0.5, 0.75, 1.0], [0.3, 0.5, 1.0], [0.9, 0.6, 0.2], [0.2, 0.4, 0.9],
  [0.9, 0.6, 0.0], [0.5, 0.2, 0.8]
];
```

Index 7 = Vulcanis: sulfur yellow-orange glow `[0.9, 0.6, 0.0]`
Index 8 = Prisma: purple glow `[0.5, 0.2, 0.8]`

---

## Step 4: Update minimap scale

**File:** `src/index.html`
**Location:** Line 830, inside `drawMinimap()` function

Current: `const w = 180, h = 180, cx = w/2, cy = h/2, scale = 0.82;`

Problem: Prisma at orbitRadius 124 with scale 0.82 = 101.7px, which exceeds the 88px minimap radius.

Fix: Change scale to `0.68` so that 124 * 0.68 = 84.3px (fits within 88px with margin).

```js
const w = 180, h = 180, cx = w/2, cy = h/2, scale = 0.68;
```

---

## Step 5: Create data/changelog.md

**File:** `data/changelog.md` (NEW file — ensure `data/` directory exists first)

Content:
```markdown
# COSMOS Changelog

## 2025-XX-XX - Initial Commit
- Created COSMOS v1 with 7 planets: Ignis, Terra Nova, Jupiterus, Glacius, Nereid, Arrakis, Oceanus
- Full WebGL/GLSL shader system with unique procedural surfaces per planet type
- Interactive 3D solar system with orbit camera, minimap, tooltips, and detail panel
- Starfield background, sun with dynamic shader, atmosphere glow, rings, and moons

## 2026-03-07 - Two New Planets
- Added Vulcanis (Volcanic Moon) at orbit 110 with sulfur-yellow eruption hotspots and dark basalt crust
- Added Prisma (Crystalline World) at orbit 124 with iridescent purple-teal crystal surface
- Created data/changelog.md and data/universe.json for project bookkeeping
- Updated minimap scale to accommodate wider solar system
```

---

## Step 6: Create data/universe.json

**File:** `data/universe.json` (NEW file)

Mirror ALL 9 planets from the PLANETS array as structured JSON. Include every field: name, type, color, radius, orbitRadius, orbitSpeed, rotationSpeed, tilt, moons, hasRings, ringColor (if present), stats (all sub-fields), desc.

Format as a JSON object with a `planets` array of 9 entries matching the JS PLANETS array exactly.

---

## Implementation Order (CODER must follow this sequence)

1. Edit `src/index.html` ~line 256 - Add Vulcanis and Prisma data to PLANETS array
2. Edit `src/index.html` ~line 507 - Add shaders 7 and 8 to makePlanetFrag's frags array
3. Edit `src/index.html` ~line 664 - Extend atmoColors with 2 new entries
4. Edit `src/index.html` ~line 830 - Change minimap scale from 0.82 to 0.68
5. Create `data/changelog.md` with initial + today's entries
6. Create `data/universe.json` with all 9 planets mirrored

## Verification Checklist
- [ ] PLANETS array has exactly 9 entries (indices 0-8)
- [ ] makePlanetFrag's frags array has exactly 9 shaders (indices 0-8)
- [ ] atmoColors array has exactly 9 entries
- [ ] Minimap scale fits orbit 124 within 88px radius
- [ ] No existing planets modified or removed
- [ ] No external dependencies added
- [ ] Everything remains in single file src/index.html
- [ ] data/changelog.md exists with proper entries
- [ ] data/universe.json exists and mirrors all 9 planets

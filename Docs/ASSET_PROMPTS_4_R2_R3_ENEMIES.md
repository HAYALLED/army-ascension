<!-- path: Docs/ASSET_PROMPTS_4_R2_R3_ENEMIES.md -->
# Army Ascension – Round 2 and Round 3 versions of the 5 original enemies

Missing files (10): `grunt_r2/_r3`, `scout_r2/_r3`, `brute_r2/_r3`, `gunner_r2/_r3`, `warlord_r2/_r3` (`.glb`, folder `Assets/Enemy/`).
The game picks them up by name, no code change. As soon as a file exists, that enemy also joins the round 2 / round 3 waves (`RoundDB`).

## 0. How the existing r2 / r3 enemies were made (checked on the files)
`mortar`, `blinder`, `weakener`, `breacher`, `shotgunner`, `kamikaze`, `sniper_enemy`, `medic_enemy` all have **identical geometry** in r1, r2 and r3 (same triangle count, same size, same `Muzzle` node). Only the palette texture changed:
- **Round 2 = ice / winter**: clothing and armor turn pale icy blue (#C6E6FC, #AADAFB, #6FB0E0, #5084B4), dark parts turn navy (#274778, #1E3A6B). Snow white #F2F8FF for trims.
- **Round 3 = lava / foundry**: clothing and armor turn burnt orange (#CA4C1C, #B5401D, #9A311E, #781F20), dark parts turn charcoal-maroon (#5B2226, #46242A, #32252E, #2B2630). Ember orange #FF6A1A for glowing details.
- Unchanged in every round: skin #E8B98A, glowing eyes (#FFE63B, #FF3A2A), cyan weapon glow #4DE6FF, gold trim #F2BF1A.

## 1. Option A (fastest, recommended): recolor, no new modeling
Copy the round 1 `.glb` and its `_palette.png`, rename both (`grunt.glb` -> `grunt_r2.glb`, `grunt_palette.png` -> `grunt_r2_palette.png`), replace the colors in the palette PNG with the table below, and point the copy's material at the new palette (same as the existing r2 / r3 files). Magenta #FF00FF in the palette is unused space, leave it.

| Enemy | Part (r1 hex) | Round 2 | Round 3 |
|---|---|---|---|
| grunt | uniform #D13833, #9E2A27, #7A1F25 | #6FB0E0, #5287B7, #3D6798 | #CA4C1C, #A3361D, #82231F |
| grunt | helmet #731A1F, #5E1519, #501216 | #264676, #1E3A6B, #172E5A | #46242A, #32252E, #2B2630 |
| scout | outfit #FF9E1F, #E07E10 | #BEE2FC, #76BBEB | #B5401D, #9A311E |
| scout | back fin #8C470D, #7A3E10, #4A2A12 | #3D6798, #264676, #1E3A6B | #5B2226, #46242A, #32252E |
| brute | steel body #9AA1B3, #808799, #6B7287, #4A5060 | #C6E6FC, #AADAFB, #90CFF9, #5084B4 | #5B2226, #46242A, #3A2A30, #32252E |
| brute | shield #4D618C, #2E3E63 | #5287B7, #294A7B | #CA4C1C, #781F20 |
| brute | helmet #383D47, #2B2F3A | #264676, #1E3A6B | #2B2630, #231F28 |
| gunner | outfit #8C47BF, #4A2670 | #6FB0E0, #355C8D | #B5401D, #9A311E |
| gunner | hood #401A59, #301443, #2A1038 | #274778, #1E3A6B, #172E5A | #34252E, #2B2630, #231F28 |
| warlord | crimson armor #B31420, #7A0C14 | #AADAFB, #5084B4 | #781F20, #5B2226 |
| warlord | gold horns / shoulders #E6B333 | #F2F8FF | #FF6A1A |
| warlord | cleaver steel #E4E8EF, #C5CBD6, #8A93A3 | keep | #6A6575, #4A4550, #3A3540 |

Keep untouched on all five: skin #E8B98A, eyes #FFE63B / #FF3A2A, dark mouth #4A1F1F, blaster black #2A2B33, cyan tip #4DE6FF, brute yellow stripe #F2C21A.

## 2. Option B: new models from text-to-3D
Same rules as before: put the **STYLE BLOCK** of `ASSET_PROMPTS.md` section 2 at the start of every prompt, and follow the **TECHNICAL SPEC** (section 3): `.glb`, Y-up, 1 unit = 1 m, origin at the feet, front faces +Z, one mesh, 1 material or one palette texture (max 256x256), enemy <= 2 000 triangles, no emissive maps, no transparency. Keep the **exact silhouette, pose and proportions of the round 1 model** (same file name without `_r2` / `_r3`), heights unchanged.

STYLE BLOCK reminder (paste it as the first lines):
```
Cute chibi toy-soldier style, cubic / blocky low-poly look, big square head
(head is about 40% of total height), short stocky body, chunky simple shapes
made of rounded-bevel boxes, tiny stubby arms and legs, flat cel-shaded colors,
bold saturated palette, clean readable silhouette from a high top-down-behind
camera angle, no tiny details, no thin parts, game-ready mobile asset,
single object, plain neutral background, no ground, no base, no shadow.
```

### 2.1 `grunt_r2.glb` (1.5 m)
```
[STYLE BLOCK] A cute angry blocky grunt enemy soldier, round 2 frost version.
Same pose and shape as the red grunt: both arms stretched forward like reaching
to grab, no weapon, small fangs. Icy blue uniform (#6FB0E0) with darker blue
shading (#3D6798), navy helmet (#264676) with a small white fur trim (#F2F8FF),
tan skin square head (#E8B98A) with angry eyebrows and glowing yellow dot eyes
(#FFE63B). Tiny chunky snow patches on the shoulders. Height 1.5 m.
```
### 2.2 `grunt_r3.glb` (1.5 m)
```
[STYLE BLOCK] A cute angry blocky grunt enemy soldier, round 3 lava version.
Same pose and shape as the red grunt: both arms stretched forward like reaching
to grab, no weapon, small fangs. Burnt orange uniform (#CA4C1C) with darker
shading (#82231F), charcoal-maroon helmet (#46242A) with two chunky ember
orange (#FF6A1A) flat stripes, tan skin square head (#E8B98A) with angry
eyebrows and glowing yellow dot eyes (#FFE63B). Height 1.5 m.
```
### 2.3 `scout_r2.glb` (1.2 m)
```
[STYLE BLOCK] A cute angry blocky scout enemy, round 2 frost version, smaller
and slimmer than a grunt, leaning forward as if sprinting, same pose as the
orange scout. Pale icy blue outfit (#BEE2FC) with blue shading (#76BBEB), small
spiky fin on the back made of dark blue ice (#3D6798), glowing red eyes
(#FF3A2A), long thin legs, no weapon. Height 1.2 m.
```
### 2.4 `scout_r3.glb` (1.2 m)
```
[STYLE BLOCK] A cute angry blocky scout enemy, round 3 lava version, smaller
and slimmer than a grunt, leaning forward as if sprinting, same pose as the
orange scout. Burnt orange outfit (#B5401D) with darker shading (#9A311E),
small spiky fin on the back in dark maroon (#5B2226) with ember tips (#FF6A1A),
glowing red eyes (#FF3A2A), long thin legs, no weapon. Height 1.2 m.
```
### 2.5 `brute_r2.glb` (2.2 m)
```
[STYLE BLOCK] A cute but tough blocky armored brute enemy, round 2 frost
version, very wide square body in pale ice-blue steel (#AADAFB, shading
#5084B4), navy visored helmet (#264676) with a red glowing eye slit (#FF3A2A),
big rectangular shield held in front in blue steel (#5287B7) with a yellow
stripe (#F2C21A), round shoulder pads with white fur trim (#F2F8FF), stubby
legs. Same silhouette as the gray brute. Height 2.2 m.
```
### 2.6 `brute_r3.glb` (2.2 m)
```
[STYLE BLOCK] A cute but tough blocky armored brute enemy, round 3 lava
version, very wide square body in dark maroon-charcoal steel (#46242A, shading
#32252E), black visored helmet (#2B2630) with a red glowing eye slit (#FF3A2A),
big rectangular shield held in front in burnt orange (#CA4C1C, edge #781F20)
with a yellow stripe (#F2C21A), round shoulder pads with small ember spikes
(#FF6A1A), stubby legs. Same silhouette as the gray brute. Height 2.2 m.
```
### 2.7 `gunner_r2.glb` (1.6 m)
```
[STYLE BLOCK] A cute angry blocky gunner enemy, round 2 frost version. Icy
blue outfit (#6FB0E0, shading #355C8D), navy hood (#274778) with a white fur
rim (#F2F8FF), a long black blaster rifle held forward in the right hand
(#2A2B33) with a glowing cyan tip (#4DE6FF) and an empty `Muzzle` at the tip,
sneaky grin. Same pose as the purple gunner. Height 1.6 m.
```
### 2.8 `gunner_r3.glb` (1.6 m)
```
[STYLE BLOCK] A cute angry blocky gunner enemy, round 3 lava version. Burnt
orange outfit (#B5401D, shading #9A311E), charcoal hood (#34252E) with a small
ember-orange trim (#FF6A1A), a long black blaster rifle held forward in the
right hand (#2A2B33) with a glowing cyan tip (#4DE6FF) and an empty `Muzzle`
at the tip, sneaky grin. Same pose as the purple gunner. Height 1.6 m.
```
### 2.9 `warlord_r2.glb` (3.6 m)
```
[STYLE BLOCK] A cute but menacing blocky warlord elite enemy, round 2 frost
version, big and wide, same pose as the crimson warlord. Ice-blue armor
(#AADAFB, shading #5084B4), white helmet (#F2F8FF) with two chunky ice-white
horns, round shoulder pads with white fur and small ice spikes, a huge steel
cleaver in the right hand (#C5CBD6), glowing yellow eyes (#FFE63B), angry face.
Height 3.6 m.
```
### 2.10 `warlord_r3.glb` (3.6 m)
```
[STYLE BLOCK] A cute but menacing blocky warlord elite enemy, round 3 lava
version, big and wide, same pose as the crimson warlord. Dark maroon armor
(#781F20, shading #5B2226) with a few flat ember-orange cracks (#FF6A1A), black
helmet with two chunky ember-orange horns (#FF6A1A), round shoulder pads with
small black spikes, a huge dark iron cleaver in the right hand (#6A6575) with
an orange edge, glowing yellow eyes (#FFE63B), angry face. Height 3.6 m.
```

## 3. Delivery checklist
- [ ] 10 files in `Assets/Enemy/`, exact names above (`<name>_r2.glb`, `<name>_r3.glb`), plus their `_palette.png` if you use palettes
- [ ] Same height as the round 1 model, origin at the feet, front +Z
- [ ] `gunner_r2` / `gunner_r3` keep the empty `Muzzle` node
- [ ] Each round is readable at a glance: r2 = blue / white, r3 = orange / charcoal

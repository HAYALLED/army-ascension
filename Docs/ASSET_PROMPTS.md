# Army Ascension – 3D Asset Prompts

Hand this whole file to the AI / 3D tool that makes the assets.
The game finds assets **by file name** – drop a file in the right folder with the exact name and it replaces the placeholder automatically. No code change needed.

---------------------------------------------------------------------
## 1. Workflow tip

Best quality: **(a)** generate one concept image per asset with the prompt below, **(b)** run image-to-3D (Meshy, Tripo, Rodin, Hunyuan3D…), **(c)** clean up in Blender (origin at feet, scale, rename, export GLB).
Text-to-3D directly also works; the prompts are written for both.
Generate all soldiers first (they appear 12–60 times on screen), then enemies, then props.

---------------------------------------------------------------------
## 2. STYLE BLOCK – paste at the start of EVERY prompt

```
Cute chibi toy-soldier style, cubic / blocky low-poly look, big square head
(head is about 40% of total height), short stocky body, chunky simple shapes
made of rounded-bevel boxes, tiny stubby arms and legs, flat cel-shaded colors,
bold saturated palette, clean readable silhouette from a high top-down-behind
camera angle, no tiny details, no thin parts, game-ready mobile asset,
single object, plain neutral background, no ground, no base, no shadow.
```

Mood: friendly, toy-like, "mobile crowd shooter". Enemies are cute-but-mean (angry eyebrows, small fangs), never gory or realistic.

---------------------------------------------------------------------
## 3. TECHNICAL SPEC – applies to every file

| Item | Requirement |
|---|---|
| Format | **.glb** (glTF 2.0 binary), Y-up |
| Units | 1 unit = 1 meter. Sizes in the tables below are FINAL game size |
| Origin | **Center of the feet / bottom of the model** at (0,0,0). Nothing below Y=0 |
| Facing | Model **front faces +Z** (glTF standard). The game rotates it to face the enemy |
| Transforms | Applied (scale 1, rotation 0). No hidden extra objects, cameras, lights |
| Mesh | One mesh object per model (props MUST be one single mesh object) |
| Triangles | Soldier ≤ 900 · Enemy ≤ 2 000 · Boss ≤ 8 000 · Prop ≤ 1 500 |
| Materials | **1 material per model** (max 2). Flat colors or ONE small palette texture (≤ 256×256, props ≤ 512×512). No PBR map sets, no emissive maps, no transparency |
| Lighting | No baked lighting or shadows in textures |
| Pose | Neutral standing pose, arms slightly away from the body so the silhouette reads. Gun held in the character's **right hand** pointing forward |
| Optional node | An empty named **`Muzzle`** at the tip of the gun barrel (bullets spawn there). If missing, the game uses a default position |
| Optional animation | Not required – the game already bobs / leans / squashes units in code. If you do add clips, name them: `Idle_loop`, `Run_loop`, `Shoot`, `Death` (enemies: `Idle_loop`, `Walk_loop`, `Attack`, `Death`; boss also `Slam`, `Roar`). Rig must be one skeleton in the same file |

---------------------------------------------------------------------
## 4. SOLDIERS  →  `Assets/Units/`

Final height ≈ **1.3 m**, width ≈ 0.55 m. Class colors must be obvious from far away.

### 4.1 `rifleman.glb`  (blue, the standard soldier)
```
[STYLE BLOCK] A cute blocky rifleman soldier. Bright blue uniform (#3573E6),
dark navy helmet (#1F3380) with a small chin strap, tan skin square face with
two dot eyes and a tiny smile, dark gray assault rifle held in the right hand
pointing forward, brown boots, small backpack. Height 1.3 m.
```

### 4.2 `machine_gunner.glb`  (orange, heavy)
```
[STYLE BLOCK] A cute blocky machine gunner. Orange uniform (#F28C1F), brown
helmet (#73400D), slightly wider chunkier body than the rifleman, big black
machine gun with a short thick barrel and a yellow ammo box on the side,
yellow ammo belt crossed over the chest, determined face. Height 1.3 m.
```

### 4.3 `sniper.glb`  (dark green, slim, long rifle)
```
[STYLE BLOCK] A cute blocky sniper. Dark green uniform (#386638), dark green
hood / ghillie cap (#1E3D1E) covering the head with only the square face
visible, very long thin black sniper rifle with a round scope, slightly
slimmer body than other soldiers, calm face. Height 1.3 m, rifle length 1.0 m.
```

### 4.4 `rocket_soldier.glb`  (red, rocket launcher on shoulder)
```
[STYLE BLOCK] A cute blocky rocket soldier. Red uniform (#CC3330), dark red
helmet (#591414), big olive-green rocket launcher tube resting on the right
shoulder pointing forward with an orange rocket tip visible at the front,
sturdy body, excited face. Height 1.3 m.
```

### 4.5 `medic.glb`  (white + green cross)
```
[STYLE BLOCK] A cute blocky field medic. White uniform (#F2F2F2), green helmet
(#40B359) with a white cross, big red cross on the chest and on a white
backpack, small pistol in the right hand, friendly smiling face.
Height 1.3 m.
```

---------------------------------------------------------------------
## 5. ENEMIES  →  `Assets/Enemy/`

Same style, but cute-and-angry: angry eyebrows, glowing yellow/red eyes, small fangs, darker colors. Final sizes are listed per model.

### 5.1 `grunt.glb`  – basic enemy, **1.5 m**
```
[STYLE BLOCK] A cute angry blocky grunt enemy soldier. Red uniform (#D13833),
dark maroon helmet (#731A1F), tan skin square head with angry eyebrows and
glowing yellow dot eyes, both arms stretched forward like reaching to grab,
no weapon, small fangs. Height 1.5 m.
```

### 5.2 `scout.glb`  – fast enemy, small, **1.2 m**
```
[STYLE BLOCK] A cute angry blocky scout enemy, smaller and slimmer than a
grunt, leaning forward as if sprinting. Orange-yellow outfit (#FF9E1F), small
spiky fin on the back (#8C470D), glowing red eyes, long thin legs, no weapon.
Height 1.2 m.
```

### 5.3 `brute.glb`  – armored enemy, **2.2 m**
```
[STYLE BLOCK] A cute but tough blocky armored brute enemy, very wide square
body in steel gray (#808799), dark gray visored helmet (#383D47) with a red
glowing eye slit, big rectangular blue-steel shield held in front (#4D618C)
with a yellow stripe, round shoulder pads, stubby legs. Height 2.2 m.
```

### 5.4 `gunner.glb`  – ranged enemy, **1.6 m**
```
[STYLE BLOCK] A cute angry blocky gunner enemy. Purple outfit (#8C47BF), dark
purple hood (#401A59), a long black blaster rifle held forward in the right
hand with a glowing cyan tip (#4DE6FF), sneaky grin. Height 1.6 m.
```

### 5.5 `warlord.glb`  – elite enemy, **3.6 m**
```
[STYLE BLOCK] A cute but menacing blocky warlord elite enemy, big and wide.
Crimson armor (#B31420), black helmet with two golden horns (#E6B333), golden
round shoulder pads with small black spikes, a huge steel cleaver in the right
hand, glowing yellow eyes, angry face. Height 3.6 m.
```

### 5.6 `boss_colossus.glb`  – final boss, **6.8 m tall, ~5 m wide**
```
[STYLE BLOCK] A giant cute-but-terrifying blocky iron robot boss called Iron
Colossus. Dark steel body (#454857) made of big chunky boxes, huge shoulder
armor with two small cones, two thick arms ending in big round fists, a glowing
orange energy core in the chest (#FF8C1A), square head with two glowing red
slit eyes (#FF4019) and two curved horns, two short thick legs, two cannon
barrels on the shoulders pointing forward. Strong symmetrical silhouette.
Height 6.8 m. Facing forward.
```
Optional boss clips: `Idle_loop`, `Walk_loop`, `Shoot` (fan attack), `Slam`, `Roar`, `Death`.

---------------------------------------------------------------------
## 6. ENVIRONMENT PROPS  →  `Assets/Ingame/`

**Each prop = ONE single mesh object** (the game scatters them hundreds of times). Same style: blocky, flat colors, cute. Origin at the bottom center.

| File | What | Size (W×H×D m) |
|---|---|---|
| `tree_a.glb` | Round blocky tree: brown box trunk + big green cube-ish canopy | 2.5 × 3.5 × 2.5 |
| `tree_b.glb` | Blocky pine: 3 stacked shrinking green cubes on a brown trunk | 2.2 × 4.5 × 2.2 |
| `rock_a.glb` | Gray angular rock cluster (3 chunky boxes), light gray tops | 1.4 × 1.0 × 1.2 |
| `rock_b.glb` | Single gray boulder, chunky and faceted | 0.9 × 0.7 × 0.9 |
| `building_a.glb` | Ruined blocky house: beige walls, broken roof corner, dark window squares | 6 × 7 × 6 |
| `building_b.glb` | Tall broken tower block, gray-brown, missing top corner | 5 × 11 × 5 |
| `building_c.glb` | Low wide warehouse, rusty orange-brown roof | 9 × 5 × 6 |
| `barrier_a.glb` | Concrete jersey barrier block, white with a red stripe, cute rounded edges. Long side along **Z** | 0.7 × 0.85 × 2.0 |
| `barrier_b.glb` | *(optional)* stack of sandbags, tan, long side along **Z** | 0.8 × 0.8 × 2.0 |
| `spike_wall.glb` | **One 3.5 m segment** of a spike trap wall: red-black base with yellow warning stripe, 6 chunky steel spikes pointing up. Tiles side by side, must be exactly 3.5 m wide, front faces +Z | 3.5 × 1.3 × 0.9 |
| `gate_pillar.glb` | Chunky dark-blue metal pillar with a yellow band at top and bottom, symmetric | 0.5 × 3.4 × 0.5 |

Prompt pattern for props:
```
[STYLE BLOCK] A cute blocky low-poly <PROP DESCRIPTION>, single mesh, flat
colors, size <W x H x D> meters, origin at bottom center.
```

---------------------------------------------------------------------
## 7. NEGATIVE PROMPT (if the tool supports it)

```
realistic, photorealistic, gore, blood, scary, horror, thin parts, tiny
details, text, logo, watermark, copyrighted character, multiple characters,
ground plane, pedestal, base, background scene, transparency, glass,
high-poly smooth surfaces, baked shadows
```

---------------------------------------------------------------------
## 8. DELIVERY CHECKLIST (per file)

- [ ] File name exactly as in this document, in the right folder
- [ ] Origin at the feet, model front faces +Z, scale 1, Y-up
- [ ] Real-world size matches the table (soldier 1.3 m tall, boss 6.8 m…)
- [ ] One mesh (props) / ≤ 2 materials, no transparency
- [ ] Under the triangle budget
- [ ] Class color matches the hex in the prompt (soldiers are told apart by color from far away)
- [ ] Optional: `Muzzle` empty on shooters, animation clips named as in section 3

Test in Godot: copy the file into its folder, run the game (F5). A wrong size can be corrected without re-exporting via `model_scale` in `SoldierDB.gd` / `EnemyDB.gd`.

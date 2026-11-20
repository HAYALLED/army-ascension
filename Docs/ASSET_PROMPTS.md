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
## 6. ROAD, BOSS ARENA, BUFF GATES, TRAPS  →  `Assets/Ingame/`

Current focus: units, traps, road, walls. Environment dressing (trees, rocks, buildings) is **deferred** – not needed yet.
All pieces below are **tileable or symmetric**, one mesh object each, origin at the **bottom center**, front faces **+Z** (the side the player sees first), final size in meters.

| File | What | Size (W × H × D m) |
|---|---|---|
| `road_tile.glb` | One road segment, **tiles seamlessly along Z** (front and back edges identical) | 14.4 × 0.12 × 10 |
| `arena_floor_tile.glb` | Boss arena floor segment, seamless along Z | 14.4 × 0.16 × 10 |
| `arena_wall_side.glb` | Boss arena side wall segment, seamless along Z. **Inner face (toward the road) is the +X side** (the game mirrors it for the other side) | 1.4 × 5 × 10 |
| `arena_wall_back.glb` | Boss arena back wall with the boss door. Front face +Z | 24 × 10 × 2 |
| `arena_entrance.glb` | Archway the army walks through to enter the boss zone. **Open underneath**: clear opening 14.4 wide × 5 high. Front face +Z | 17 × 7.5 × 1.5 |
| `gate_pillar.glb` | Buff gate pillar (3 per gate) | 0.5 × 3.6 × 0.5 |
| `gate_beam.glb` | Top beam that holds the buff signs | 14.4 × 0.4 × 0.5 |
| `gate_panel.glb` | Hanging buff sign (the game writes "+6", "x2", "+25% DAMAGE" on it). Soldiers walk UNDER it: model bottom edge = 0, the game hangs it at 1.6 m | 6.2 × 1.7 × 0.25 |
| `spike_wall.glb` | Trap, one 3.5 m segment (already requested earlier) | 3.5 × 1.3 × 0.9 |

**Special rule for `gate_panel.glb` (2 materials):**
- material `Frame` – dark navy metal frame with yellow corner bolts (fixed colors)
- material **`Tint`** – the big flat screen area in the middle, **plain white, no texture, no emissive**. The game recolors it per buff (blue = soldiers, orange = damage, yellow = fire rate, red = penalty). Keep it a flat rectangle with nothing drawn on it.

### 6.1 `road_tile.glb`
```
[STYLE BLOCK] A cute blocky low-poly road segment for a mobile army shooter,
seamlessly tileable along its length. Flat sandy-tan paving made of large
chunky square stone blocks in two slightly different warm tan shades (#C7B58F
and #B9A67E), very low contrast, thin darker grooves between blocks, two
dashed white lane lines near the left and right edges, slightly darker worn
strip in the middle, rounded bevel on the side edges. Plain and calm so
colorful soldiers stand out. Size 14.4 m wide, 10 m long, 0.12 m thick. Top
view readable. Front and back edges must match perfectly for tiling.
```

### 6.2 `arena_floor_tile.glb`
```
[STYLE BLOCK] A cute blocky metal arena floor segment, seamlessly tileable
along its length. Dark steel plates (#3D4050) with chunky bevels and square
rivets, a yellow-and-black hazard stripe band across the front and back edge
(#F2BF1A and #1A1A1F), subtle red glow lines between plates (flat color, not
emissive). Size 14.4 m wide, 10 m long, 0.16 m thick.
```

### 6.3 `arena_wall_side.glb`
```
[STYLE BLOCK] A cute blocky fortress wall segment for a boss arena, seamlessly
tileable along its length. Dark steel and concrete blocks (#262830 and #3B3E4A),
chunky battlements on top, vertical glowing red slit windows (flat red
#FF3A2A) every 2.5 m, yellow-black hazard stripe near the bottom. The inner
face (+X side) carries the details, the outer face is plain. Size 1.4 m thick,
5 m high, 10 m long.
```

### 6.4 `arena_wall_back.glb`
```
[STYLE BLOCK] A cute blocky giant boss gate wall, symmetric. Dark steel wall
(#262830) with a huge double door in the center, the door has a big angry
robot face emblem with two red slit eyes and two horns (#FF3A2A, #454857),
thick rivets, red warning stripes along the top, chunky towers on both ends.
Front face +Z. Size 24 m wide, 10 m high, 2 m thick.
```

### 6.5 `arena_entrance.glb`
```
[STYLE BLOCK] A cute blocky boss-zone entrance archway, symmetric. Two chunky
dark steel towers (#262830) on the sides joined by a thick beam on top with a
big angry robot-skull emblem in the center (#454857 with red eyes #FF3A2A),
red-and-yellow warning light blocks on the corners, hazard stripes on the
towers. The opening underneath is completely EMPTY: 14.4 m wide and 5 m high.
Front face +Z. Size 17 m wide, 7.5 m high, 1.5 m deep.
```

### 6.6 `gate_pillar.glb`
```
[STYLE BLOCK] A cute blocky metal gate pillar, symmetric, dark navy (#1F2A47)
with a yellow band at the top and at the bottom (#F2BF1A), small square bolts,
slightly wider base. Size 0.5 x 3.6 x 0.5 m.
```

### 6.7 `gate_beam.glb`
```
[STYLE BLOCK] A cute blocky horizontal gate beam, dark navy (#1F2A47) with
yellow-black hazard stripes at both ends and small square mounting hooks
underneath every 3 m. Symmetric. Size 14.4 x 0.4 x 0.5 m.
```

### 6.8 `gate_panel.glb`
```
[STYLE BLOCK] A cute blocky hanging sign panel for a buff gate, symmetric. A
thick dark navy metal frame (#1F2A47) with yellow square corner bolts
(#F2BF1A) and two short chain links on top. The large center area is a
perfectly FLAT plain WHITE rectangle (separate material named "Tint", no
text, no pattern, no glow). Both sides identical. Bottom edge at height 0.
Size 6.2 m wide, 1.7 m high, 0.25 m thick.
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

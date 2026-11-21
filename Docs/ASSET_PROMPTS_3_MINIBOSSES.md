<!-- path: Docs/ASSET_PROMPTS_3_MINIBOSSES.md -->
# Army Ascension – Mini Boss + Mini Boss Arena Asset Prompts

Hand this file to the AI / 3D tool that makes the assets.
Same rules as `ASSET_PROMPTS.md`: **STYLE BLOCK** at the start of every prompt, **TECHNICAL SPEC** (section 3) applies. The game finds files by exact name; drop them in the folder, no code change for the model itself.

Mini bosses appear on every level that is NOT a multiple of 5 (levels 5, 10, 15... fight the Iron Colossus). They are smaller and more varied than the Colossus, and fight in a shorter, scrappier arena.

---------------------------------------------------------------------
## 0. STYLE BLOCK (paste at the start of EVERY prompt)

```
Cute chibi toy-soldier style, cubic / blocky low-poly look, big square head
(head is about 40% of total height), short stocky body, chunky simple shapes
made of rounded-bevel boxes, tiny stubby arms and legs, flat cel-shaded colors,
bold saturated palette, clean readable silhouette from a high top-down-behind
camera angle, no tiny details, no thin parts, game-ready mobile asset,
single object, plain neutral background, no ground, no base, no shadow.
```

## 0.1 Tech spec for mini bosses (differences from normal enemies)

| Item | Requirement |
|---|---|
| Folder | `Assets/Enemy/` |
| Format | `.glb`, Y-up, 1 unit = 1 m, **origin at the center of the feet**, nothing below Y=0, front faces **+Z**, transforms applied |
| Height | **3.6 – 4.6 m** (Colossus is 6.8 m, Warlord is 3.6 m). The game scales by the height listed below |
| Triangles | ≤ 4 000 each |
| Mesh / material | One mesh object, **1 material** (max 2), flat colors or ONE palette texture ≤ 256x256, no emissive maps, no transparency |
| Silhouette | Must be readable from top-down-behind. Each one must look clearly different from the others AND from the Colossus (dark steel + red) at a glance. Use the unique main color listed below |
| Optional node | Empty named `Muzzle` at the gun/cannon tip where listed |
| Optional clips | Not required. If added: `Idle_loop`, `Walk_loop`, `Attack`, `Death` (+ `Slam` / `Shoot` / `Roar` where listed) |
| Mood | Cute-but-mean (angry eyebrows, small fangs). Never gory, never realistic |

---------------------------------------------------------------------
## 1. MINI BOSSES  →  `Assets/Enemy/`

### 1.1 `miniboss_crusher.glb` – rusty orange brawler, 4.2 m tall, ~3 m wide  (ground slam)
```
[STYLE BLOCK] A cute blocky mini boss called the Crusher. A huge stocky brawler
robot with a giant square head with angry eyebrows and two small fangs, rusty
orange body (#D9722B) with dark brown armor plates (#5A3320), enormous
oversized blocky fists, one fist holding a giant square-headed sledgehammer
resting on the shoulder, yellow-black hazard stripes on the belly, small
exhaust pipes on the back, tiny stubby legs. Wide planted stance, symmetric
silhouette except the hammer. Height 4.2 m, width 3 m.
```
Optional clips: `Idle_loop`, `Walk_loop`, `Slam` (hammer smash), `Death`.

### 1.2 `miniboss_gatling.glb` – teal gunner mech, 3.8 m tall, ~2.6 m wide  (projectile fan)
```
[STYLE BLOCK] A cute blocky mini boss called the Gatling. A round-bellied
walker mech with a big square head under a dome visor with two glowing-looking
flat yellow eyes (#FFD23F), teal body (#1FA39A) with dark navy panels
(#16365A), a huge six-barrel minigun block replacing the right arm pointing
forward, a big ammo drum on the back, left arm is a small shield plate, short
sturdy stubby legs. Height 3.8 m, width 2.6 m.
```
Needs empty **`Muzzle`** at the minigun tip. Optional clips: `Idle_loop`, `Walk_loop`, `Shoot`, `Death`.

### 1.3 `miniboss_bomber.glb` – purple and yellow bomb chief, 3.6 m tall, ~2.8 m wide  (bombs + big minion waves)
```
[STYLE BLOCK] A cute blocky mini boss called the Bomber Chief. A fat jolly-mean
bomber with a huge square head wearing a dark purple aviator cap with goggles
pushed up (#5B2A86), big grin with two small fangs, round purple body, a
bandolier of chunky round black bombs with yellow fuses (#F2BF1A) across the
chest, a giant round bomb backpack with a lit fuse on top, oversized gloves,
tiny boots. Height 3.6 m, width 2.8 m.
```
Optional clips: `Idle_loop`, `Walk_loop`, `Attack` (throw), `Roar`, `Death`.

### 1.4 `miniboss_commander.glb` – green and gold warlord, 4.6 m tall, ~3 m wide  (summons minions)
```
[STYLE BLOCK] A cute blocky mini boss called the Commander. A tall stern
general with a huge square head under a tall gold-trimmed officer cap with
a small horn on each side (#E3B341), angry eyebrows, olive green armored
coat (#4C7A34) with big gold shoulder pads and gold buttons, a giant square
tower shield in the left hand with a simple skull emblem (#2F4A22 and gold),
a chunky battle banner pole in the right hand with a plain square flag (no
text), short stubby legs. Height 4.6 m, width 3 m.
```
Optional clips: `Idle_loop`, `Walk_loop`, `Roar` (raise banner), `Death`.

---------------------------------------------------------------------
## 2. MINI BOSS ARENA  →  `Assets/Ingame/`

Smaller and scrappier than the steel boss fortress: a rusty **scrap-yard fighting pit**. Same dimensions and rules as the boss arena so the game can reuse the same placement code. Same tech rules as `ASSET_PROMPTS.md` section 3 (one mesh, 1 material, flat colors or one small palette, ≤ 1 500 tris, origin rules below).

| File | Purpose | Final size (W × H × L, m) |
|---|---|---|
| `miniarena_floor_tile.glb` | Arena floor segment, seamless along Z. Origin at top-center of the tile's middle | 14.4 × 0.16 × 10 |
| `miniarena_wall_side.glb` | Side wall segment, seamless along Z. **Inner face (toward the road) is the +X side** (the game mirrors it for the other side) | 1.4 × 4 × 10 |
| `miniarena_wall_back.glb` | Back wall behind the mini boss. Front face +Z | 24 × 8 × 2 |
| `miniarena_entrance.glb` | Archway the army walks through. **Open underneath**: clear opening 14.4 wide × 5 high. Front face +Z | 17 × 6.5 × 1.5 |

### 2.1 `miniarena_floor_tile.glb`
```
[STYLE BLOCK] A cute blocky scrap-yard fighting pit floor segment, seamlessly
tileable along its length. Rusty brown-orange metal plates (#7A4A2E and
#8C5A38, very low contrast) with chunky bevels, square rivets, a few flat dark
oil-stain patches, a faded white-and-orange hazard stripe band across the front
and back edge (#E8E2D0 and #D9722B). Plain and calm so colorful soldiers stand
out. Size 14.4 m wide, 10 m long, 0.16 m thick. Front and back edges must
match perfectly for tiling.
```

### 2.2 `miniarena_wall_side.glb`
```
[STYLE BLOCK] A cute blocky scrap-yard wall segment for a mini boss pit,
seamlessly tileable along its length. Stacked crushed-car blocks and corrugated
rust-orange metal sheets (#8C4A2B and #5E3A28), a chain-link fence section on
top with chunky square posts, a few round tire stacks stuck in the wall, a
yellow-black hazard stripe near the bottom. The inner face (+X side) carries
the details, the outer face is plain. Size 1.4 m thick, 4 m high, 10 m long.
```

### 2.3 `miniarena_wall_back.glb`
```
[STYLE BLOCK] A cute blocky scrap-yard back wall for a mini boss pit,
symmetric. A huge rusty garage-shutter door in the center with a chunky
cartoon skull-and-wrench emblem above it (#D9722B and #3A2A22), walls made of
stacked crushed cars and corrugated sheets (#8C4A2B), tall rusty smokestacks
on both ends, warning-light blocks on top, thick rivets. Front face +Z.
Size 24 m wide, 8 m high, 2 m thick.
```

### 2.4 `miniarena_entrance.glb`
```
[STYLE BLOCK] A cute blocky scrap-yard entrance archway, symmetric. Two chunky
towers of stacked crushed cars (#8C4A2B) on the sides joined by a thick rusty
girder on top, a big chunky skull-and-wrench emblem in the center, a hanging
tire on a chain on each side, orange warning-light blocks on the corners,
yellow-black hazard stripes on the towers. The opening underneath is completely
EMPTY: 14.4 m wide and 5 m high. Front face +Z. Size 17 m wide, 6.5 m high,
1.5 m deep.
```

---------------------------------------------------------------------
## Delivery checklist
- [ ] 4 mini bosses in `Assets/Enemy/`, exact file names, height as listed
- [ ] Each mini boss has a clearly different main color and silhouette
- [ ] `Muzzle` empty on `miniboss_gatling.glb`
- [ ] 4 arena files in `Assets/Ingame/`, exact file names, entrance opening 14.4 × 5 m
- [ ] One mesh, 1 material (max 2), no emissive maps, no transparency, origin and facing as listed

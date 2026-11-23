<!-- path: Docs/ASSET_PROMPTS_5_CHEST_OPENING.md -->
# Army Ascension – Chest opening assets (wooden, silver, gold)

The home page already has 4 empty chest slots, and `chest_wood.png`, `chest_silver.png`, `chest_gold.png` (closed, 256x256) exist in `Assets/UI/`. This document lists everything that is still needed to **open** a chest: animation frames per chest, shared light / burst effects and sounds. The game code that plays them comes later.

All art is **2D UI art** in the same chunky toy-block style as the existing chest icons. Put new files in `Assets/UI/Chests/`. The existing closed icons stay as they are and are frame 1 of each animation.

## 1) How an opening looks (so the frames fit the animation)
| Time | What happens | Asset used |
|---|---|---|
| 0.0 - 0.6 s | Closed chest pops up, shakes left / right 3 times | frames 1, 2, 3 |
| 0.6 - 0.9 s | Lid cracks open, a bright slit of light shows | frame 4 |
| 0.9 - 1.1 s | Lid flies half open, light bursts out, rays spin up | frame 5 + rays + glow |
| 1.1 - 2.5 s | Chest fully open, coins and shards jump out and fly to the reward row | frame 6 + particles |
| 2.5 s + | Reward list shown over a soft glow | glow |

## 2) UI STYLE BLOCK (paste first in every prompt)
```
Cute chunky mobile game UI in the same toy-block style as the 3D units:
rounded-SQUARE shapes (not pills, not circles unless asked), thick dark navy
outline (#1B2340), flat cel-shaded colors with a bright top highlight strip and
a darker bottom bevel, soft and friendly, bold saturated palette, high
contrast, readable at small size, no gradients noise, no photo textures, no
text or letters unless the prompt says so, transparent background, centered,
clean edges, game-ready mobile asset.
```

## 3) The three chests (colors taken from the existing icons)
| Chest | Body | Highlight / dark | Straps and rivets | Lock |
|---|---|---|---|---|
| **Wooden** | #A56A33 | #C98B4B / #7A4E26 | gray steel #6B7280, white rivets | gold #F2BF1A |
| **Silver** | #7C86A0 | #B7C0D4 / #5C6376 | dark steel #4A5270, white rivets | gold #F2BF1A |
| **Gold** | #D9A20F | #F7D14A / #8F6606 | dark gold #A1780B, white rivets | blue #3573E6 |

Glow color when open: wooden = warm orange `#FFB14A`, silver = ice white-blue `#CFE8FF`, gold = bright yellow `#FFE45C`.

## 4) Technical spec
| Item | Requirement |
|---|---|
| Format | **PNG, transparent background**, sRGB, no text |
| Frame size | **256 x 256** each, same canvas for every frame of a chest |
| Alignment | Chest bottom edge on the same line and chest centered horizontally in every frame, so frames can be swapped without jumping. The closed frame must match the existing `chest_<name>.png` exactly |
| Margin | 4 px transparent margin, nothing cut (frame 5 and 6: the lid and light may use the upper margin, scale the chest down a little so everything fits) |
| Sheet | One PNG per chest, **768 x 512**, 3 columns x 2 rows, frames in reading order 1-6 |
| Light inside | Flat bright color (the glow color above) with a few small star sparkles, no soft gradient |

## 5) Animation frames – one prompt per chest
Use the existing closed icon as a **reference image** (image-to-image) so the chest stays identical. If your generator has no reference input, describe it with the table in section 3.

### 5.1 `chest_wood_sheet.png` (768 x 512)
```
[UI STYLE BLOCK] A sprite sheet of 6 frames in a 3 by 2 grid, each cell 256x256,
the SAME wooden treasure chest in every frame (brown wood body #A56A33 with
gray steel straps #6B7280, white rivets, gold lock #F2BF1A), front view, chest
bottom on the same line in every cell, transparent background, no text.
Frame 1: closed chest, exactly like the reference.
Frame 2: closed chest tilted slightly to the left (about 6 degrees), tiny motion marks.
Frame 3: closed chest tilted slightly to the right (about 6 degrees), tiny motion marks.
Frame 4: lid opened a tiny crack, a thin bright orange-yellow (#FFB14A) slit of light between lid and body, lock still in place.
Frame 5: lid half open and tilted back, flat orange-yellow light (#FFB14A) pouring out of the chest, 3 small white four-point sparkles, lock hanging open.
Frame 6: lid fully open and tilted back, the chest filled with glowing orange-yellow light (#FFB14A) and a small pile of gold coins and one cyan crystal shard on top, 5 small white four-point sparkles.
```
### 5.2 `chest_silver_sheet.png` (768 x 512)
```
[UI STYLE BLOCK] A sprite sheet of 6 frames in a 3 by 2 grid, each cell 256x256,
the SAME silver treasure chest in every frame (blue-gray metal body #7C86A0
with dark steel straps #4A5270, white rivets, gold lock #F2BF1A), front view,
chest bottom on the same line in every cell, transparent background, no text.
Frame 1: closed chest, exactly like the reference.
Frame 2: closed chest tilted slightly to the left (about 6 degrees), tiny motion marks.
Frame 3: closed chest tilted slightly to the right (about 6 degrees), tiny motion marks.
Frame 4: lid opened a tiny crack, a thin bright ice-white (#CFE8FF) slit of light between lid and body.
Frame 5: lid half open and tilted back, flat ice-white-blue light (#CFE8FF) pouring out, 3 small white four-point sparkles, lock hanging open.
Frame 6: lid fully open and tilted back, the chest filled with glowing ice-white-blue light (#CFE8FF) and a pile of gold coins with two cyan crystal shards on top, 6 small white four-point sparkles.
```
### 5.3 `chest_gold_sheet.png` (768 x 512)
```
[UI STYLE BLOCK] A sprite sheet of 6 frames in a 3 by 2 grid, each cell 256x256,
the SAME golden treasure chest in every frame (shiny yellow-gold body #D9A20F
with dark gold straps #A1780B, white rivets, blue lock #3573E6), front view,
chest bottom on the same line in every cell, transparent background, no text.
Frame 1: closed chest, exactly like the reference.
Frame 2: closed chest tilted slightly to the left (about 6 degrees), tiny motion marks.
Frame 3: closed chest tilted slightly to the right (about 6 degrees), tiny motion marks.
Frame 4: lid opened a tiny crack, a thin very bright yellow (#FFE45C) slit of light between lid and body.
Frame 5: lid half open and tilted back, flat bright yellow light (#FFE45C) pouring out, 4 small white four-point sparkles, lock hanging open.
Frame 6: lid fully open and tilted back, the chest overflowing with glowing yellow light (#FFE45C), a heap of gold coins, three cyan crystal shards and one purple gem (#8C47BF) on top, 8 small white four-point sparkles.
```
Tip: if frames drift, generate frame 1 and frame 6 first, then the in-between frames from frame 1 as reference, and cut the cells afterwards. Each frame can also be delivered as its own file: `chest_<name>_1.png` ... `chest_<name>_6.png`.

## 6) Optional: separate layers (smoother lid animation)
If you prefer the game to rotate the lid itself instead of swapping frames, deliver three 256 x 256 layers per chest, aligned to each other (stacked they must look like the closed chest):
- `chest_<name>_back.png`: inside of the chest and the back rim (flat glow color inside)
- `chest_<name>_body.png`: front part of the body with lock and straps, **no lid**
- `chest_<name>_lid.png`: the lid only, drawn closed. Hinge is the **top back edge**; mark it with a one-pixel dot at the pivot in a separate guide file `chest_<name>_lid_pivot.png`

## 7) Shared effects (all tint-able, so one file serves all chests)
| File | Size | Prompt |
|---|---|---|
| `fx_chest_rays.png` | 512 x 512 | `[UI STYLE BLOCK] Radial sun-ray burst, 12 flat triangular rays around the center, white, rays fade to transparent at the tips, soft center glow, no outline, 512x512, transparent background.` (game rotates and tints it) |
| `fx_chest_glow.png` | 512 x 512 | `Soft round white glow, brightest in the center, fading smoothly to fully transparent at the edge, no outline, 512x512, transparent background.` |
| `fx_sparkle.png` | 64 x 64 | `[UI STYLE BLOCK] A single white four-point star sparkle with a tiny thick navy outline, 64x64.` |
| `fx_ring.png` | 256 x 256 | `A thin white shockwave ring, soft edge, no fill, transparent center, 256x256, transparent background.` |
| `fx_coin.png` | 64 x 64 | `[UI STYLE BLOCK] A single chunky gold coin seen from the front, 64x64.` (flying particle) |
| `fx_shard.png` | 64 x 64 | `[UI STYLE BLOCK] A single cyan crystal shard (#4DE6FF), 64x64.` (flying particle) |
| `fx_gem.png` | 64 x 64 | `[UI STYLE BLOCK] A single purple gem (#8C47BF), 64x64.` (gold chest only) |
| `fx_confetti.png` | 128 x 32 | `Four tiny flat confetti pieces in a row (red, blue, green, yellow) with no outline, 128x32, transparent background.` |

## 8) Optional: slot states for the home page
| File | Size | Prompt |
|---|---|---|
| `chest_slot_empty.png` | 256 x 256 | `[UI STYLE BLOCK] An empty dark navy rounded-square slot with a dashed lighter-navy outline and a faint chest silhouette in the center, 256x256.` |
| `chest_slot_ready_glow.png` | 256 x 256 | `[UI STYLE BLOCK] A hollow rounded-square glow frame, bright yellow (#F2BF1A), center transparent, soft outer glow, 256x256.` (pulses behind a chest that can be opened) |

## 9) Sounds (short, 44.1 kHz, `.ogg`)
| File | Length | Prompt |
|---|---|---|
| `sfx_chest_shake.ogg` | 0.6 s | `Wooden treasure chest rattling and shaking, three quick thumps with a metal chain clink, cartoon style` |
| `sfx_chest_unlock.ogg` | 0.3 s | `Cartoon lock click and a short metallic ping` |
| `sfx_chest_open_wood.ogg` | 0.8 s | `Wooden chest lid creaking open with a warm magical whoosh and a few coins jingling` |
| `sfx_chest_open_silver.ogg` | 0.9 s | `Metal chest lid opening with a bright shimmering whoosh and coins jingling` |
| `sfx_chest_open_gold.ogg` | 1.2 s | `Golden chest opening with a big sparkling magical burst, choir-like shimmer and lots of coins pouring` |
| `sfx_reward_pop.ogg` | 0.25 s | `Short happy pop for a reward item appearing, bubbly` |

## 10) Delivery checklist (all in `Assets/UI/Chests/`)
- [ ] `chest_wood_sheet.png`, `chest_silver_sheet.png`, `chest_gold_sheet.png` (768 x 512, 6 frames), or the 18 single frames
- [ ] Frame 1 of each sheet is identical to the existing `chest_<name>.png`
- [ ] `fx_chest_rays.png`, `fx_chest_glow.png`, `fx_sparkle.png`, `fx_ring.png`, `fx_coin.png`, `fx_shard.png`, `fx_gem.png`, `fx_confetti.png`
- [ ] Optional: layers (section 6), slot states (section 8)
- [ ] Sounds from section 9 in `Assets/Audio/` (same folder as the other sound effects)
- [ ] Nothing contains text

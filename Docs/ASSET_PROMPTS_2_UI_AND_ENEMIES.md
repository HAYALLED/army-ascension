# Army Ascension – Asset Prompts Part 2
## A) 3 new 3D enemies   B) 2D UI kit

Same rules as `ASSET_PROMPTS.md` (sections 2 and 3): paste the **3D STYLE BLOCK** first, `.glb`, origin at the feet, front faces +Z, 1 unit = 1 m, one mesh, ≤ 2 materials, optional `Muzzle` node, optional clips (`Idle_loop`, `Walk_loop`, `Attack`, `Death`).

---------------------------------------------------------------------
# A) NEW 3D ENEMIES  →  `Assets/Enemy/`

| File | Role in game (so the look matches) | Final height |
|---|---|---|
| `kamikaze.glb` | Fragile runner. Rushes the army and explodes on contact for heavy damage | 1.1 m |
| `sniper_enemy.glb` | Stays far away, shoots the player's BACK rows. Slow, high damage | 1.7 m |
| `medic_enemy.glb` | Heals other enemies, 3x slower than the player medic. Priority target | 1.5 m |

Colors are chosen so they do NOT look like existing units (player medic = white/green, player sniper = dark green, grunt = red, scout = orange).

### A1) `kamikaze.glb`
```
[3D STYLE BLOCK] A cute blocky kamikaze bomb enemy: a small round-cube black
bomb body (#2B2B33) with a screaming angry face (two big white eyes with tiny
black pupils, wide open mouth), tiny stubby legs running pose, both arms thrown
up in the air, a red-and-white striped dynamite bundle strapped to the chest
(#D13833 and #F2F2F2), a short fuse on top of the head with a small glowing
yellow-orange spark cube (#FFC21A). Looks fragile and panicked, thin little
limbs. Height 1.1 m, width 0.8 m.
```
Optional clips: `Walk_loop` (fast scared run), `Death`.

### A2) `sniper_enemy.glb`
```
[3D STYLE BLOCK] A cute blocky enemy sniper, tall and lanky (taller and
slimmer than normal soldiers). Dark navy-black cloak with a hood (#1B2030),
gray-blue scarf (#6C7A99), only a square face with one glowing red eye
visible, a very long black sniper rifle held in the right hand pointing
forward with a round red scope lens (#FF3A2A) and a small red laser-dot
cube at the barrel tip, calm sneaky stance. Height 1.7 m, rifle length 1.3 m.
```
Needs a `Muzzle` empty at the barrel tip. Optional clips: `Idle_loop`, `Attack` (shot recoil), `Death`.

### A3) `medic_enemy.glb`
```
[3D STYLE BLOCK] A cute but creepy blocky enemy medic. Dark purple coat
(#4A2A6E), black round goggles with glowing purple lenses (#C77DFF), a big
glowing purple cross on the chest and on the back (#C77DFF), a big
syringe-shaped backpack tank filled with glowing purple liquid on the back,
holding a small purple healing wand with a glowing orb in the right hand,
slightly hunched. Height 1.5 m.
```
Optional clips: `Idle_loop`, `Walk_loop`, `Attack` (raise wand = heal pulse), `Death`.

---------------------------------------------------------------------
# B) 2D UI KIT  →  `Assets/UI/`

## B0) UI STYLE BLOCK – paste at the start of EVERY 2D prompt
```
Cute chunky mobile game UI in the same toy-block style as the 3D units:
rounded-SQUARE shapes (not pills, not circles unless asked), thick dark navy
outline (#1B2340), flat cel-shaded colors with a bright top highlight strip and
a darker bottom bevel, soft and friendly, bold saturated palette, high
contrast, readable at small size, no gradients noise, no photo textures, no
text or letters unless the prompt says so, transparent background, centered,
clean edges, game-ready mobile asset.
```
Palette (use consistently):
navy `#1F2A47` · green `#3DBB5A` · blue `#3573E6` · orange `#F28C1F` · red `#D13833` · gold `#F2BF1A` · purple `#8C47BF` · cyan (shards) `#4DE6FF` · white `#F2F2F2` · gray `#8A93A8`

## B1) Technical spec
| Item | Requirement |
|---|---|
| Format | **PNG, transparent background**, sRGB |
| Reference screen | 720 × 1280 portrait (design size). Sizes below are in pixels at that size |
| **No text** | All words are written by the game (localization). Buttons, panels, banners are EMPTY. Only the logo contains text |
| 9-slice panels | Stretchable: uniform corner/border, flat center, no details that break when stretched. Corner size given per asset |
| Icons | Centered with 8 px padding, single object, silhouette readable at 64 px |
| Safe | Nothing cut at the edges, 4 px transparent margin |

## B2) File list

### Buttons (empty, no text)
| File | Size | Look |
|---|---|---|
| `btn_primary.png` | 512×160 | Green, main action (PLAY, UPGRADE) |
| `btn_secondary.png` | 512×160 | Blue |
| `btn_gold.png` | 512×160 | Gold/yellow (BUY, WATCH AD) |
| `btn_danger.png` | 512×160 | Red |
| `btn_disabled.png` | 512×160 | Gray, flat, locked look |
| `btn_round.png` | 160×160 | Rounded square icon button, navy, empty center (pause, back, close, settings) |

Prompt pattern: `[UI STYLE BLOCK] An empty wide rounded-square button, <COLOR>, no text, no icon, 512x160 px, 9-slice friendly with 48 px corners.`

### Panels & bars
| File | Size | Look |
|---|---|---|
| `panel_popup.png` | 512×512 (corner 64) | Big popup / menu panel, light navy-blue body, thick dark outline, subtle inner border |
| `panel_card.png` | 320×420 (corner 40) | Soldier / shop item card base, cream-white body |
| `panel_dark.png` | 256×256 (corner 32) | Dark semi-transparent navy panel for HUD stats |
| `panel_header.png` | 640×140 | Title ribbon / banner, empty, yellow-gold with folded ends |
| `topbar_currency.png` | 260×80 (corner 28) | Small currency pill-box, dark navy, empty |
| `tabbar.png` | 720×180 | Bottom navigation bar, 5 empty slots, dark navy with top highlight |
| `tab_active.png` | 150×150 | Highlighted tab slot (bright, raised) |
| `tab_inactive.png` | 150×150 | Normal tab slot |
| `bar_frame.png` | 512×48 (corner 20) | Empty progress bar frame, dark navy, inner shadow |
| `bar_fill_green.png` / `red` / `yellow` / `cyan` | 512×48 (corner 20) | Fill part, glossy highlight strip on top (green = army hp, red = boss, yellow = level progress, cyan = shards) |
| `popup_overlay_glow.png` | 512×512 | Soft radial yellow light burst for rewards (victory, chest open) |

### Rarity card frames (hollow center, 9-slice, corner 40, size 320×420)
`frame_common.png` (gray `#8A93A8`), `frame_rare.png` (blue `#3573E6`), `frame_epic.png` (purple `#8C47BF`), `frame_legendary.png` (gold `#F2BF1A`, with small sparkle corners).
Prompt: `[UI STYLE BLOCK] A hollow card frame, <COLOR>, thick border with small corner studs, center completely transparent, 320x420 px.`

### Icons (128×128 each, one object, no text)
- **Currency:** `icon_gold` (stack of 3 chunky gold coins), `icon_shard` (cyan crystal shard), `icon_gem` (purple premium gem)
- **Menu / nav:** `icon_play`, `icon_soldiers` (soldier helmet), `icon_upgrade` (up arrow on a block), `icon_missions` (clipboard with check), `icon_shop` (shopping bag), `icon_settings` (gear), `icon_home`, `icon_back`, `icon_close`, `icon_pause`
- **State:** `icon_lock`, `icon_check`, `icon_star`, `icon_new` (small red dot badge), `icon_ad_video` (play triangle in a TV), `icon_noads` (crossed-out TV), `icon_calendar_gift`, `icon_trophy`
- **Settings:** `icon_sound_on/off`, `icon_music_on/off`, `icon_vibration_on/off`
- **Stats:** `icon_damage` (bullet), `icon_health` (heart block), `icon_firerate` (3 bullets / lightning), `icon_range` (target), `icon_armor` (shield)
- **Soldier classes:** `class_rifleman` (blue rifle), `class_machinegunner` (orange gun with belt), `class_sniper` (green scope), `class_rocket` (red rocket), `class_medic` (green cross)
- **Chests:** `chest_wood`, `chest_silver`, `chest_gold` (closed, front view, 256×256)

Icon prompt pattern: `[UI STYLE BLOCK] A single chunky icon of <OBJECT>, <MAIN COLOR>, centered on a transparent background, 128x128 px.`
Tip: generate icons as a **sheet (4×4 grid, equal cells)** for consistent style, then cut.

### Shop art (256×256 each, no text, no price tags)
`shop_gold_s`, `shop_gold_m`, `shop_gold_l` (small pile → big chest of gold coins), `shop_shards_s/m/l` (small → big pile of cyan crystal shards), `shop_bundle_starter` (gift box with a helmet, coins and shard peeking out), `shop_season_pass` (golden ticket with a star), `shop_no_ads` (shield with a crossed-out TV).

### Backgrounds & logo
| File | Size | Look |
|---|---|---|
| `bg_main_menu.png` | 720×1280 | Key art, see prompt B4 |
| `bg_menu_generic.png` | 720×1280 | Calmer blurred version of the same scene, used behind Soldiers / Upgrade / Shop / Missions |
| `bg_loading.png` | 720×1280 | Loading screen, see prompt B4 |
| `logo.png` | 1024×512, transparent | Game logo, the ONLY asset with text |

## B3) Layout reference screens (NOT shipped – I use them to lay out the menus)
Generate one mockup image per screen with the UI style block + the line below. Portrait 9:16 (720×1280). Real readable English text is fine here.

1. **Main menu:** `[UI STYLE BLOCK] Mobile game main menu screen, portrait. Top: gold and shard counters and a settings button. Center: big game logo "ARMY RUSH: EVOLUTION" over a colorful toy-soldier battlefield. A huge green PLAY button in the lower middle. Bottom navigation bar with 5 tabs: Soldiers, Upgrades, PLAY (center, larger), Missions, Shop.`
2. **Soldiers (collection):** `... A scrolling grid of 2-column soldier cards with rarity frames (gray, blue, purple, gold), each card shows a chunky toy soldier, level badge, shard progress bar and a small UPGRADE or LOCKED button. Header ribbon "Soldiers". Same top bar and bottom tabs.`
3. **Soldier detail / upgrade:** `... A popup with a large 3D-looking toy soldier in the middle, stats rows (damage, health, fire rate, range) with icons and small green "+" values, a cost line with gold and shard icons, a big green UPGRADE button and a close button.`
4. **Shop:** `... Header "Shop". Sections: a gold "Watch Ad - Free Shards" card, a Starter Bundle card, a row of 3 gold packs, a row of 3 shard packs, a "Remove Ads" card, a "Season Pass" card. Price buttons in gold.`
5. **Missions:** `... A list of mission rows, each with an icon, short title, progress bar and a CLAIM button, tabs Daily / Weekly / Achievements, a daily login reward strip of 7 days at the top.`
6. **Settings:** `... A centered popup with toggles for Sound, Music, Vibration, Graphics quality (Low / High) and a Language selector.`
7. **Victory / Defeat:** `... Big gold ribbon "VICTORY" with stars, reward rows (gold, shards, chest), buttons "Double Reward (watch ad)" in gold and "Continue" in green.` and a red-themed `DEFEAT` version with "Try Again".
8. **Pause:** small popup with Resume, Restart, Home.

## B4) Backgrounds & logo prompts
**`bg_main_menu.png`**
```
Cute blocky toy-soldier battlefield key art, portrait 720x1280, flat cel-shaded
colors, warm sunset sky (#FFB86B to #7FB2F0), a sandy road leading to the
horizon with a small group of cute blue blocky toy soldiers marching in
formation in the lower third, a giant blocky iron robot boss silhouette far
away at the top, a few red enemy toy soldiers, chunky clouds, simple low-poly
hills, empty space in the upper-middle for a logo and in the lower area for
buttons, no text, no UI.
```
**`bg_menu_generic.png`**
```
The same cute blocky toy-soldier battlefield, portrait 720x1280, heavily
blurred and darkened by 40 percent, very low contrast, calm navy-blue tint so
UI panels on top stay readable, no characters in focus, no text.
```
**`bg_loading.png`**
```
Cute blocky toy-soldier army marching toward the viewer on a sandy road,
portrait 720x1280, flat cel-shaded, dramatic sunset sky, chunky clouds, a blank
horizontal strip near the bottom for a loading bar, no text, no UI.
```
**`logo.png`**
```
Game logo text "ARMY RUSH: EVOLUTION" (two lines: ARMY RUSH big, EVOLUTION
smaller under it), chunky blocky 3D letters in gold-yellow (#F2BF1A) with a thick
dark navy outline and a bottom bevel, a small cute blue toy-soldier helmet on
top of the first letter, tiny star sparkles, transparent background, 1024x512.
```
(Title is a placeholder – tell me the final name and I will tell you what to put.)

---------------------------------------------------------------------
## Delivery checklist (2D)
- [ ] File name exactly as listed, PNG, transparent, correct size
- [ ] NO text on buttons, panels, banners (logo only)
- [ ] 9-slice assets stretch cleanly (flat center, even corners)
- [ ] Same outline thickness (≈ 6 px at 512 wide), same palette, same corner radius across the whole kit
- [ ] Icons readable at 64 px

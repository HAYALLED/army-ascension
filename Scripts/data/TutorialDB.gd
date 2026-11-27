class_name TutorialDB
extends RefCounted
## All tutorial data: balance numbers, texts, the step table, home coach marks and HOW TO PLAY slides.
## Every player-facing string lives here only, so it can be translated later.
## Art lives in Assets/UI/Tutorial/, Assets/Units/ and Assets/Ingame/ (see Docs/ASSET_PROMPTS_7_TUTORIAL.md).
## Every art file is optional: the tutorial draws a placeholder when it is missing.

# ---- reward and safety net ---------------------------------------------------------
## Paid once, on the first tutorial completion (plus one already-unlocked wooden chest).
const REWARD_GOLD := 150
## The army is refilled to this many soldiers when it drops below it (the tutorial can not be lost).
const MIN_ARMY := 6
## Seconds the guide's finish card shows before the TRAINING COMPLETE popup opens.
const FINISH_DELAY := 3.0
## Minimum seconds between two "I've got your back" lines.
const RESCUE_COOLDOWN := 8.0

# ---- trigger distances (the layout itself is Scene/Ingame/Levels/LevelTutorial.tscn) ----
## Meters before a gate / the spike wall at which its step starts.
const GATE_LEAD := 35.0
const SPIKE_LEAD := 30.0
## Meters before the arena stop marker at which the boss step starts.
const BOSS_LEAD := 15.0
## Meters the army must move to each side in the drag step.
const DRAG_NEED := 3.0
## How far ahead of the army the guide runs, and where he stands (behind the army) during the boss fight.
const GUIDE_LEAD := 7.0
const GUIDE_RETREAT := -4.0

# ---- boss: 30% health and a slow, gentle fight ---------------------------------------------
const BOSS_HP_FACTOR := 0.3
## Values written over Boss.cfg of the level 1 mini boss.
const BOSS_CFG := {"wake": 28.0, "slam_damage": 12.0, "slam_time": 1.9, "recover": 3.2, "recover_enraged": 2.4, "summon_min": 3, "summon_max": 4}

# ---- overlay layout (720x1280) -------------------------------------------------------------
## Top of the guide card as a fraction of the screen height (below the HUD, above the fight).
const CARD_TOP_RATIO := 0.27
## A card of a non-holding step hides itself after this many seconds.
const CARD_AUTO_HIDE := 6.0

# ---- art paths ---------------------------------------------------------------------------------
const ART := "res://Assets/UI/Tutorial/"
const GUIDE_MODEL := "res://Assets/Units/tutorial_guide"
const FLAG_MODEL := "res://Assets/Ingame/tutorial_flag"
const ARROW_TEXTURE := ART + "arrow_pointer.png"

# ---- guide lines outside the step table ----------------------------------------------------------
const OUCH_LINE := "Ouch. Next time, dodge the red ones."
const RESCUE_LINE := "I've got your back, recruit."
const RING_ARMY_CAPTION := "Keep your army alive"
const SKIP_TEXT := "SKIP"
const RIBBON_TEXT := "TRAINING"

# ---- victory popup ----------------------------------------------------------------------------------
const TITLE_DONE := "TRAINING COMPLETE"
const BUTTON_BASE := "TO BASE"
const RESULT_REWARD := "Reward\n+%d gold"
const RESULT_CHEST := "\nWooden Chest  (ready, tap it on Home)"
const RESULT_REPLAY := "Replay finished.\nNo reward this time."

## Step table. hold = the army stops until the step is done. hint = what the overlay / world shows:
## hand_drag, arrows_gate (both gate panels), arrow_red (the bad panel), ring_army, arrow_gap, ring_loot, ring_boss.
## Triggers and completion are in TutorialDirector (one function per id).
const STEPS := [
	{"id": &"welcome", "portrait": &"talk", "hold": true, "button": "CONTINUE", "hint": &"",
		"text": "Recruit! I'm Sgt. Tatter.\nThis flag has seen forty battles. Follow it."},
	{"id": &"drag", "portrait": &"talk", "hold": true, "button": "", "hint": &"hand_drag",
		"text": "Drag your finger left and right\nto steer the army."},
	{"id": &"gates", "portrait": &"talk", "hold": false, "button": "", "hint": &"arrows_gate",
		"text": "Gates power you up.\nSteer into the one you want!"},
	{"id": &"red_gate", "portrait": &"warn", "hold": false, "button": "", "hint": &"arrow_red",
		"text": "Red gate takes soldiers away.\nSteer around it!"},
	{"id": &"shoot", "portrait": &"talk", "hold": false, "button": "", "hint": &"ring_army",
		"text": "Your soldiers shoot on their own.\nYou just steer."},
	{"id": &"spikes", "portrait": &"warn", "hold": false, "button": "", "hint": &"arrow_gap",
		"text": "Spikes hurt.\nSlip through the gap!"},
	{"id": &"loot", "portrait": &"talk", "hold": false, "button": "", "hint": &"ring_loot",
		"text": "Fallen enemies drop gold and shards.\nSpend them on upgrades."},
	{"id": &"boss", "portrait": &"warn", "hold": false, "button": "", "hint": &"ring_boss",
		"text": "A mini boss! Watch its health bar\nand keep shooting."},
	{"id": &"finish", "portrait": &"cheer", "hold": false, "button": "", "hint": &"",
		"text": "That's it, recruit.\nYou're ready for the front line."},
]

## Home screen coach marks. A target is "home:Name" (unique name inside HomePage) or "menu:Name" (unique name in MainMenu).
## Several targets share one hole. A target that does not exist is skipped.
const COACH := [
	{"targets": ["home:PlayButton", "home:LevelBanner"], "text": "Every level is a new battle.\nWin to unlock the next one."},
	{"targets": ["home:ChestSlots"], "text": "Winning drops a chest. Tap it to see what is inside. It needs time to unlock; watch a video or use gems to hurry."},
	{"targets": ["menu:TabSoldiers"], "text": "Collect shards from chests. Spend gold and shards to level your soldiers up."},
	{"targets": ["menu:TabUpgrades"], "text": "Army-wide upgrades for all your soldiers."},
	{"targets": ["menu:TabMissions"], "text": "Daily and weekly missions and the daily login. Free rewards."},
	{"targets": ["menu:TabShop"], "text": "Gems, free chests and offers."},
	{"targets": ["menu:SettingsButton"], "text": "Forgot something? HOW TO PLAY is in Settings."},
]
const COACH_NEXT := "NEXT"
const COACH_DONE := "GOT IT"

## HOW TO PLAY slides: art file (Assets/UI/Tutorial/), title, text, placeholder color.
const HOWTO := [
	{"art": "howto_1_drag.png", "title": "DRAG TO MOVE", "color": Color(0.30, 0.55, 0.95),
		"text": "Drag left and right to steer your army. It marches forward by itself."},
	{"art": "howto_2_gates.png", "title": "PICK A GATE", "color": Color(0.95, 0.60, 0.20),
		"text": "Gates add soldiers, damage or fire rate. Red gates cost soldiers."},
	{"art": "howto_3_shoot.png", "title": "AUTO FIRE", "color": Color(0.35, 0.75, 0.40),
		"text": "Your soldiers shoot on their own. Keep your army big and healthy."},
	{"art": "howto_4_boss.png", "title": "BEAT THE BOSS", "color": Color(0.85, 0.30, 0.30),
		"text": "Every level ends with a boss. Win to unlock the next level."},
	{"art": "howto_5_chest.png", "title": "OPEN CHESTS", "color": Color(0.80, 0.60, 0.25),
		"text": "Winning drops chests with soldier shards. Chests need time to unlock."},
	{"art": "howto_6_upgrade.png", "title": "LEVEL UP", "color": Color(0.60, 0.45, 0.90),
		"text": "Spend gold and shards to upgrade your soldiers and grow stronger."},
]
const HOWTO_TITLE := "HOW TO PLAY"
const HOWTO_NEXT := "NEXT"
const HOWTO_BACK := "BACK"
const HOWTO_DONE := "DONE"
const HOWTO_TOUR := "MENU TOUR"


static func art(file: String) -> String:
	return ART + file


## Gives a guide card the cream bubble art (bubble_9slice.png, 48 px corners) and dark text.
## Without the art the theme's PanelPopup and the white outlined text stay.
static func style_card(panel: PanelContainer, label: Label) -> void:
	var path := ART + "bubble_9slice.png"
	if not ResourceLoader.exists(path):
		return
	var tex := load(path) as Texture2D
	if tex == null:
		return
	var sb := StyleBoxTexture.new()
	sb.texture = tex
	sb.set_texture_margin_all(48.0)
	sb.set_content_margin_all(30.0)
	panel.add_theme_stylebox_override("panel", sb)
	label.theme_type_variation = &"LabelDark"

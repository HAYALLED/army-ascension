class_name ChestPopup
extends Control
## Modal that shows what a chest holds before the player opens it. Units the player does not
## own yet show as "???" (opening the chest unlocks them). A chest that is still locked shows its
## countdown with WATCH AD (-15 min) and OPEN NOW (gems, 1 gem per 6 min). Emits answered(true) for
## OPEN and answered(false) for CLOSE. Built in code with the shared UI theme.
## Use: if await ChestPopup.ask(host, slot_index): ...PlayerData.open_chest(slot_index).

signal answered(open: bool)

const THEME := preload("res://Resources/UI/ui_theme.tres")

var _chest: Dictionary = {}
var _slot: int = 0
var _actions: VBoxContainer
var _tick := 0.0
var _locked := false
var _ad_running := false


## Opens the preview of the chest in `slot` under `host` and waits for the answer (true = open it now).
static func ask(host: Node, slot: int) -> bool:
	var p := ChestPopup.new()
	p._slot = slot
	p._chest = PlayerData.chest_slots[slot]
	host.add_child(p)
	return await p.answered


func _ready() -> void:
	theme = THEME
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.78)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"PanelPopup"
	panel.custom_minimum_size = Vector2(580, 0)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	panel.add_child(box)
	var tier := int(_chest["tier"])
	var title := Label.new()
	title.theme_type_variation = &"LabelBig"
	title.text = ChestDB.name_of(tier).to_upper()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	if ResourceLoader.exists(ChestDB.icon_of(tier)):
		var hero := TextureRect.new()
		hero.texture = load(ChestDB.icon_of(tier))
		hero.custom_minimum_size = Vector2(0, 200)
		hero.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		hero.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		box.add_child(hero)
	for line in ChestDB.preview_lines(_chest):
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 14)
		var icon := TextureRect.new()
		icon.texture = load(String(line["icon"]))
		icon.custom_minimum_size = Vector2(56, 56)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(icon)
		var label := Label.new()
		label.text = String(line["text"])
		label.add_theme_font_size_override("font_size", 36)
		row.add_child(label)
		box.add_child(row)
	if ChestDB.has_unknown_unit(_chest):
		var note := Label.new()
		note.theme_type_variation = &"LabelSmall"
		note.text = "??? = a new unit for your army"
		note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(note)
	_actions = VBoxContainer.new()
	_actions.add_theme_constant_override("separation", 18)
	box.add_child(_actions)
	_locked = PlayerData.chest_left(_slot) > 0
	_rebuild_actions()


## Once a second: refresh the countdown, and swap to OPEN when the wait is over.
func _process(delta: float) -> void:
	_tick -= delta
	if _tick > 0.0:
		return
	_tick = 1.0
	if _locked and not _ad_running:
		_locked = PlayerData.chest_left(_slot) > 0
		_rebuild_actions()


## Buttons for the current state: locked = timer + WATCH AD + OPEN NOW (gems), ready = OPEN. Always CLOSE.
func _rebuild_actions() -> void:
	for c in _actions.get_children():
		c.queue_free()
	if _locked:
		var left := PlayerData.chest_left(_slot)
		var timer := Label.new()
		timer.theme_type_variation = &"LabelBig"
		timer.text = "OPENS IN  %s" % ChestSlot.clock(left)
		timer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_actions.add_child(timer)
		var ad := _button("WATCH AD  (-%d MIN)" % (ChestDB.AD_SKIP_SECONDS / 60), &"ButtonPrimary")
		ad.pressed.connect(_watch_ad)
		_actions.add_child(ad)
		var cost := ChestDB.skip_gems(left)
		var gems := _button("OPEN NOW  (%d GEMS)" % cost, &"ButtonGold")
		gems.disabled = PlayerData.gems < cost
		gems.pressed.connect(func() -> void:
			if PlayerData.skip_chest_with_gems(_slot):
				SaveManager.save_now()
				_finish(true))
		_actions.add_child(gems)
	else:
		var open := _button("OPEN", &"ButtonGold")
		open.pressed.connect(func() -> void: _finish(true))
		_actions.add_child(open)
	var close := _button("CLOSE", &"ButtonSecondary")
	close.pressed.connect(func() -> void: _finish(false))
	_actions.add_child(close)


## Plays one rewarded ad; earned = 15 minutes off the wait.
func _watch_ad() -> void:
	if _ad_running:
		return
	_ad_running = true
	var earned := await AdService.show_rewarded("chest_speedup")
	_ad_running = false
	if earned:
		PlayerData.speed_up_chest(_slot, ChestDB.AD_SKIP_SECONDS)
		SaveManager.save_now()
	_locked = PlayerData.chest_left(_slot) > 0
	_rebuild_actions()


func _finish(open: bool) -> void:
	answered.emit(open)
	queue_free()


func _button(text: String, variation: StringName) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 88)
	b.focus_mode = Control.FOCUS_NONE
	b.theme_type_variation = variation
	b.add_theme_font_size_override("font_size", 32)
	b.pressed.connect(func() -> void: AudioManager.play("ui_click"))
	return b

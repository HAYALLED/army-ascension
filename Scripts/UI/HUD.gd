class_name HUD
extends CanvasLayer
## Battle HUD built in code: resources, army status, level progress, boss
## bar, banners, pause / victory / defeat overlay. Listens to Game signals.

enum Mode { NONE, PAUSE, WIN, LOSE }

var _gold: Label
var _shards: Label
var _kills: Label
var _army_label: Label
var _army_bar: ProgressBar
var _buffs: Label
var _progress: ProgressBar
var _boss_panel: PanelContainer
var _boss_name: Label
var _boss_bar: ProgressBar
var _boss_target: float = 0.0
var _banner: Label
var _banner_tween: Tween
var _overlay: ColorRect
var _title: Label
var _stats: Label
var _btn_primary: Button
var _btn_secondary: Button
var _mode: int = Mode.NONE


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	Game.army_changed.connect(_on_army_changed)
	Game.gold_changed.connect(func(v: int) -> void: _gold.text = "GOLD  %d" % v)
	Game.shards_changed.connect(func(v: int) -> void: _shards.text = "SHARDS  %d" % v)
	Game.kills_changed.connect(func(v: int) -> void: _kills.text = "KILLS  %d" % v)
	Game.buffs_changed.connect(_on_buffs_changed)
	Game.progress_changed.connect(func(r: float) -> void: _progress.value = r * 100.0)
	Game.banner_requested.connect(show_banner)
	Game.boss_spawned.connect(_on_boss_spawned)
	Game.boss_hp_changed.connect(func(hp: float, mx: float) -> void:
		_boss_bar.max_value = mx
		_boss_target = hp)
	Game.boss_defeated.connect(func() -> void: _boss_panel.visible = false)
	Game.battle_won.connect(_on_won)
	Game.battle_lost.connect(_on_lost)


func _process(delta: float) -> void:
	if _boss_panel.visible:
		_boss_bar.value = move_toward(_boss_bar.value, _boss_target, _boss_bar.max_value * delta * 1.2)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_toggle_pause()


# ---------------------------------------------------------------- building

static func _flat(color: Color, radius: int = 16, margin: int = 10) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(margin)
	return sb


func _label(text: String, size: int, color: Color = Color.WHITE) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", maxi(size / 6, 3))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _bar(fill: Color, height: float) -> ProgressBar:
	var b := ProgressBar.new()
	b.show_percentage = false
	b.custom_minimum_size = Vector2(0, height)
	b.min_value = 0.0
	b.max_value = 100.0
	b.value = 100.0
	b.add_theme_stylebox_override("background", _flat(Color(0, 0, 0, 0.55), 8, 0))
	b.add_theme_stylebox_override("fill", _flat(fill, 8, 0))
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return b


func _button(text: String, color: Color, size: Vector2, font: int) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = size
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", font)
	for st in ["normal", "hover", "pressed", "focus"]:
		var c := color
		if st == "pressed":
			c = color.darkened(0.25)
		elif st == "hover":
			c = color.lightened(0.1)
		b.add_theme_stylebox_override(st, _flat(c, 18, 8))
	b.pressed.connect(func() -> void: AudioManager.play("ui_click"))
	return b


func _safe_top() -> int:
	var win := DisplayServer.window_get_size()
	if win.y <= 0:
		return 0
	var safe := DisplayServer.get_display_safe_area()
	var vp := get_viewport().get_visible_rect().size
	return int(float(safe.position.y) * vp.y / float(win.y))


func _build() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 14 + _safe_top())
	margin.add_theme_constant_override("margin_bottom", 16)
	root.add_child(margin)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(col)

	# Top row: resources | army | pause
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(top)

	var res_panel := PanelContainer.new()
	res_panel.add_theme_stylebox_override("panel", _flat(Color(0, 0, 0, 0.45)))
	res_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(res_panel)
	var res := VBoxContainer.new()
	res.mouse_filter = Control.MOUSE_FILTER_IGNORE
	res_panel.add_child(res)
	_gold = _label("GOLD  0", 28, Color(1.0, 0.85, 0.25))
	_shards = _label("SHARDS  0", 24, Color(0.5, 0.9, 1.0))
	_kills = _label("KILLS  0", 24, Color(0.9, 0.9, 0.9))
	res.add_child(_gold)
	res.add_child(_shards)
	res.add_child(_kills)

	var army_box := VBoxContainer.new()
	army_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	army_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(army_box)
	_army_label = _label("ARMY  0", 40)
	_army_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	army_box.add_child(_army_label)
	_army_bar = _bar(Color(0.25, 0.8, 0.35), 22)
	army_box.add_child(_army_bar)
	_buffs = _label("DMG +0%   RATE +0%", 22, Color(1.0, 0.8, 0.4))
	_buffs.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	army_box.add_child(_buffs)

	var pause := _button("II", Color(0, 0, 0, 0.5), Vector2(84, 84), 38)
	pause.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	pause.pressed.connect(_toggle_pause)
	top.add_child(pause)

	_progress = _bar(Color(1.0, 0.8, 0.2), 12)
	_progress.value = 0.0
	col.add_child(_progress)

	_boss_panel = PanelContainer.new()
	_boss_panel.add_theme_stylebox_override("panel", _flat(Color(0, 0, 0, 0.55)))
	_boss_panel.visible = false
	_boss_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(_boss_panel)
	var bv := VBoxContainer.new()
	bv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boss_panel.add_child(bv)
	_boss_name = _label("BOSS", 34, Color(1.0, 0.35, 0.3))
	_boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bv.add_child(_boss_name)
	_boss_bar = _bar(Color(0.9, 0.15, 0.15), 28)
	bv.add_child(_boss_bar)

	# Banner
	_banner = _label("", 84)
	_banner.anchor_left = 0.0
	_banner.anchor_right = 1.0
	_banner.anchor_top = 0.24
	_banner.anchor_bottom = 0.36
	_banner.offset_left = 0
	_banner.offset_right = 0
	_banner.offset_top = 0
	_banner.offset_bottom = 0
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_banner.modulate.a = 0.0
	root.add_child(_banner)

	# Overlay (pause / win / lose)
	_overlay = ColorRect.new()
	_overlay.color = Color(0, 0, 0, 0.72)
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.visible = false
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(_overlay)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 22)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(box)
	_title = _label("PAUSED", 100)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_title)
	_stats = _label("", 36, Color(0.9, 0.9, 0.9))
	_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_stats)
	_btn_primary = _button("RESUME", Color(0.2, 0.65, 0.3), Vector2(520, 110), 44)
	_btn_primary.pressed.connect(_on_primary)
	box.add_child(_btn_primary)
	_btn_secondary = _button("RESTART", Color(0.25, 0.3, 0.45), Vector2(520, 96), 38)
	_btn_secondary.pressed.connect(_on_secondary)
	box.add_child(_btn_secondary)


# ---------------------------------------------------------------- handlers

func _on_army_changed(count: int, hp: float, max_hp: float) -> void:
	_army_label.text = "ARMY  %d" % count
	_army_bar.max_value = maxf(max_hp, 1.0)
	_army_bar.value = hp


func _on_buffs_changed(dmg: float, rate: float) -> void:
	_buffs.text = "DMG +%d%%   RATE +%d%%" % [int(round((dmg - 1.0) * 100.0)), int(round((rate - 1.0) * 100.0))]


func _on_boss_spawned(boss_name: String, max_hp: float) -> void:
	_boss_name.text = boss_name
	_boss_bar.max_value = max_hp
	_boss_bar.value = max_hp
	_boss_target = max_hp
	_boss_panel.visible = true


func show_banner(text: String, color: Color) -> void:
	_banner.text = text
	_banner.add_theme_color_override("font_color", color)
	_banner.pivot_offset = _banner.size * 0.5
	if _banner_tween != null:
		_banner_tween.kill()
	_banner.modulate.a = 0.0
	_banner.scale = Vector2(1.5, 1.5)
	_banner_tween = create_tween()
	_banner_tween.set_parallel(true)
	_banner_tween.tween_property(_banner, "modulate:a", 1.0, 0.12)
	_banner_tween.tween_property(_banner, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_banner_tween.chain().tween_interval(1.0)
	_banner_tween.chain().tween_property(_banner, "modulate:a", 0.0, 0.4)


func _toggle_pause() -> void:
	if Game.state == Game.State.PLAYING:
		Game.set_paused(true)
		_open(Mode.PAUSE, "PAUSED", Color(1, 1, 1), "", "RESUME", "RESTART")
	elif Game.state == Game.State.PAUSED:
		_close()
		Game.set_paused(false)


func _on_won() -> void:
	AudioManager.play("victory")
	_open(Mode.WIN, "VICTORY!", Color(1.0, 0.85, 0.2), _result_text(), "PLAY AGAIN", "")


func _on_lost() -> void:
	AudioManager.play("defeat")
	_open(Mode.LOSE, "DEFEAT", Color(1.0, 0.3, 0.25), _result_text(), "TRY AGAIN", "")


func _result_text() -> String:
	var t := int(Game.elapsed)
	return "Kills  %d\nGold  %d\nShards  %d\nSurvivors  %d\nTime  %d:%02d" % [
		Game.kills, Game.gold, Game.shards, Game.soldiers.size(), t / 60, t % 60]


func _open(mode: int, title: String, color: Color, stats: String, primary: String, secondary: String) -> void:
	_mode = mode
	_title.text = title
	_title.add_theme_color_override("font_color", color)
	_stats.text = stats
	_stats.visible = stats != ""
	_btn_primary.text = primary
	_btn_secondary.text = secondary
	_btn_secondary.visible = secondary != ""
	_overlay.modulate.a = 0.0
	_overlay.visible = true
	create_tween().tween_property(_overlay, "modulate:a", 1.0, 0.25)


func _close() -> void:
	_overlay.visible = false
	_mode = Mode.NONE


func _on_primary() -> void:
	match _mode:
		Mode.PAUSE:
			_close()
			Game.set_paused(false)
		Mode.WIN, Mode.LOSE:
			Game.restart()


func _on_secondary() -> void:
	if _mode == Mode.PAUSE:
		Game.restart()

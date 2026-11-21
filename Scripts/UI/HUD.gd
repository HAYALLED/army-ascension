class_name HUD
extends CanvasLayer
## Battle HUD (scene: Scene/UI/HUD.tscn): resources, army status, level
## progress, boss bar, banners and the pause / victory / defeat popup.
## Listens to Game signals; contains no layout code.

enum Mode { NONE, PAUSE, WIN, LOSE }

@onready var _gold: Label = %GoldLabel
@onready var _shards: Label = %ShardLabel
@onready var _kills: Label = %KillsLabel
@onready var _army_label: Label = %ArmyLabel
@onready var _army_bar: TextureProgressBar = %ArmyBar
@onready var _buffs: Label = %BuffsLabel
@onready var _progress: TextureProgressBar = %ProgressBar
@onready var _boss_panel: Control = %BossPanel
@onready var _boss_name: Label = %BossName
@onready var _boss_bar: TextureProgressBar = %BossBar
@onready var _banner: Label = %Banner
@onready var _pause: Button = %PauseButton
@onready var _overlay: Control = %Overlay
@onready var _title: Label = %Title
@onready var _stats: Label = %Stats
@onready var _primary: Button = %PrimaryButton
@onready var _secondary: Button = %SecondaryButton
@onready var _tertiary: Button = %TertiaryButton
@onready var _top_margin: MarginContainer = %TopMargin

var _boss_target: float = 0.0
var _banner_tween: Tween = null
var _mode: int = Mode.NONE


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	_top_margin.add_theme_constant_override("margin_top", 14 + _safe_top())
	_overlay.visible = false
	_boss_panel.visible = false
	_banner.modulate.a = 0.0
	_pause.pressed.connect(_toggle_pause)
	_primary.pressed.connect(_on_primary)
	_secondary.pressed.connect(_on_secondary)
	_tertiary.pressed.connect(_on_tertiary)
	Game.army_changed.connect(_on_army_changed)
	Game.gold_changed.connect(func(v: int) -> void: _gold.text = str(v))
	Game.shards_changed.connect(func(v: int) -> void: _shards.text = str(v))
	Game.kills_changed.connect(func(v: int) -> void: _kills.text = str(v))
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


func _safe_top() -> int:
	var win := DisplayServer.window_get_size()
	if win.y <= 0:
		return 0
	var safe := DisplayServer.get_display_safe_area()
	var vp := get_viewport().get_visible_rect().size
	return int(float(safe.position.y) * vp.y / float(win.y))


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
	AudioManager.play("ui_click")
	if Game.state == Game.State.PLAYING:
		Game.set_paused(true)
		_open(Mode.PAUSE, "PAUSED", Color.WHITE, "", "RESUME", "RESTART", "HOME")
	elif Game.state == Game.State.PAUSED:
		_close()
		Game.set_paused(false)


func _on_won() -> void:
	AudioManager.play("victory")
	_open(Mode.WIN, "VICTORY!", Color(1.0, 0.85, 0.2), _result_text(), "CONTINUE", "PLAY AGAIN", "")


func _on_lost() -> void:
	AudioManager.play("defeat")
	_open(Mode.LOSE, "DEFEAT", Color(1.0, 0.3, 0.25), _result_text(), "TRY AGAIN", "HOME", "")


func _result_text() -> String:
	var t := int(Game.elapsed)
	return "Kills  %d\nGold  +%d\nShards  +%d\nSurvivors  %d\nTime  %d:%02d" % [
		Game.kills, Game.gold, Game.shards, Game.soldiers.size(), floori(t / 60.0), t % 60]


func _open(mode: int, title: String, color: Color, stats: String, primary: String, secondary: String, tertiary: String) -> void:
	_mode = mode
	_title.text = title
	_title.add_theme_color_override("font_color", color)
	_stats.text = stats
	_stats.visible = stats != ""
	_primary.text = primary
	_secondary.text = secondary
	_secondary.visible = secondary != ""
	_tertiary.text = tertiary
	_tertiary.visible = tertiary != ""
	_overlay.modulate.a = 0.0
	_overlay.visible = true
	create_tween().tween_property(_overlay, "modulate:a", 1.0, 0.25)


func _close() -> void:
	_overlay.visible = false
	_mode = Mode.NONE


func _on_primary() -> void:
	AudioManager.play("ui_click")
	match _mode:
		Mode.PAUSE:
			_close()
			Game.set_paused(false)
		Mode.WIN:
			Game.next_level()
			Game.goto_menu()
		Mode.LOSE:
			Game.restart()


func _on_secondary() -> void:
	AudioManager.play("ui_click")
	match _mode:
		Mode.PAUSE, Mode.WIN:
			Game.restart()
		Mode.LOSE:
			Game.goto_menu()


func _on_tertiary() -> void:
	AudioManager.play("ui_click")
	if _mode == Mode.PAUSE:
		get_tree().paused = false
		Game.goto_menu()

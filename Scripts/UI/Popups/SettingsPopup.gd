class_name SettingsPopup
extends Control
## Settings: sound, music, vibration, day cycle, graphics quality, HOW TO PLAY, replay tutorial.

const HOW_TO_POPUP := preload("res://Scene/Menus/Popups/HowToPlayPopup.tscn")

@onready var _sound: Button = %SoundToggle
@onready var _music: Button = %MusicToggle
@onready var _vibration: Button = %VibrationToggle
@onready var _day_cycle: Button = %DayCycleToggle
@onready var _gfx_low: Button = %GfxLow
@onready var _gfx_high: Button = %GfxHigh
@onready var _close: Button = %CloseButton
@onready var _how_to: Button = %HowToButton
@onready var _replay: Button = %ReplayButton


func _ready() -> void:
	_sound.button_pressed = AudioManager.sfx_enabled
	_music.button_pressed = AudioManager.music_enabled
	_vibration.button_pressed = PlayerData.settings["vibration"]
	_day_cycle.button_pressed = PlayerData.settings["day_cycle"]
	_gfx_high.button_pressed = PlayerData.settings["graphics_high"]
	_gfx_low.button_pressed = not PlayerData.settings["graphics_high"]
	for b in [_sound, _music, _vibration, _day_cycle, _gfx_low, _gfx_high]:
		(b as Button).toggled.connect(func(_on: bool) -> void: _apply())
	_sound.toggled.connect(func(on: bool) -> void:
		AudioManager.sfx_enabled = on
		PlayerData.set_setting("sfx", on))
	_music.toggled.connect(func(on: bool) -> void:
		AudioManager.music_enabled = on
		if on:
			AudioManager.play_music()
		else:
			AudioManager.stop_music()
		PlayerData.set_setting("music", on))
	_vibration.toggled.connect(func(on: bool) -> void: PlayerData.set_setting("vibration", on))
	_day_cycle.toggled.connect(func(on: bool) -> void: PlayerData.set_setting("day_cycle", on))
	_gfx_high.toggled.connect(func(on: bool) -> void:
		if on:
			PlayerData.set_setting("graphics_high", true))
	_gfx_low.toggled.connect(func(on: bool) -> void:
		if on:
			PlayerData.set_setting("graphics_high", false))
	_close.pressed.connect(func() -> void:
		AudioManager.play("ui_click")
		SaveManager.save_now()
		queue_free())
	_how_to.pressed.connect(_open_how_to)
	_replay.pressed.connect(_replay_tutorial)
	_apply()


## HOW TO PLAY slides open on top of the settings (a sibling in the popup layer).
func _open_how_to() -> void:
	AudioManager.play("ui_click")
	var popup := HOW_TO_POPUP.instantiate() as HowToPlayPopup
	popup.tour_requested.connect(_on_tour_requested)
	get_parent().add_child(popup)


## MENU TOUR button of the slides: close the settings and start the home coach marks.
func _on_tour_requested() -> void:
	var menu := get_tree().current_scene as MainMenu
	queue_free()
	if menu != null:
		menu.start_coach()


## Plays the tutorial level again. A replay pays no reward.
func _replay_tutorial() -> void:
	AudioManager.play("ui_click")
	SaveManager.save_now()
	Game.start_tutorial(true)


## Toggle look: green + "ON" when pressed, gray otherwise.
func _apply() -> void:
	for b in [_sound, _music, _vibration, _day_cycle]:
		var btn := b as Button
		btn.text = "ON" if btn.button_pressed else "OFF"
		btn.theme_type_variation = &"ButtonPrimary" if btn.button_pressed else &"ButtonDisabled"
	for b in [_gfx_low, _gfx_high]:
		var btn := b as Button
		btn.theme_type_variation = &"ButtonPrimary" if btn.button_pressed else &"ButtonDisabled"

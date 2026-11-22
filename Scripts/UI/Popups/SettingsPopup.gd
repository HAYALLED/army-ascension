class_name SettingsPopup
extends Control
## Settings: sound, music, vibration, graphics quality.

@onready var _sound: Button = %SoundToggle
@onready var _music: Button = %MusicToggle
@onready var _vibration: Button = %VibrationToggle
@onready var _gfx_low: Button = %GfxLow
@onready var _gfx_high: Button = %GfxHigh
@onready var _close: Button = %CloseButton


func _ready() -> void:
	_sound.button_pressed = AudioManager.sfx_enabled
	_music.button_pressed = AudioManager.music_enabled
	_vibration.button_pressed = PlayerData.settings["vibration"]
	_gfx_high.button_pressed = PlayerData.settings["graphics_high"]
	_gfx_low.button_pressed = not PlayerData.settings["graphics_high"]
	for b in [_sound, _music, _vibration, _gfx_low, _gfx_high]:
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
	_apply()


## Toggle look: green + "ON" when pressed, gray otherwise.
func _apply() -> void:
	for b in [_sound, _music, _vibration]:
		var btn := b as Button
		btn.text = "ON" if btn.button_pressed else "OFF"
		btn.theme_type_variation = &"ButtonPrimary" if btn.button_pressed else &"ButtonDisabled"
	for b in [_gfx_low, _gfx_high]:
		var btn := b as Button
		btn.theme_type_variation = &"ButtonPrimary" if btn.button_pressed else &"ButtonDisabled"

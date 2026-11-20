class_name HomePage
extends Control
## Main menu home: logo, PLAY, daily reward and free chest buttons.

signal play_pressed()
signal toast_requested(text: String)

@onready var _play: Button = %PlayButton
@onready var _daily: Button = %DailyButton
@onready var _chest: Button = %ChestButton
@onready var _level: Label = %LevelLabel


func _ready() -> void:
	_level.text = "LEVEL %d" % Game.level_index
	_play.pressed.connect(func() -> void:
		AudioManager.play("ui_click")
		play_pressed.emit())
	_daily.pressed.connect(func() -> void: toast_requested.emit("Daily rewards come with the missions phase"))
	_chest.pressed.connect(func() -> void: toast_requested.emit("Free chest (rewarded ad) is mocked in dev"))

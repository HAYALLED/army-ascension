class_name HomePage
extends Control
## Main menu home: logo, level banner (tap to pick a beaten level), PLAY, PREPARE YOUR ARMY, daily reward
## and the 4 chest slots (chests dropped by beaten levels wait 30 min / 1 h / 2 h: tap one to see
## what is inside, speed it up with an ad or gems, and open it). The free ad chest lives in the Shop.

signal play_pressed()
signal toast_requested(text: String)

const FORMATION_POPUP := preload("res://Scene/Menus/Popups/FormationPopup.tscn")

@onready var _play: Button = %PlayButton
@onready var _daily: Button = %DailyButton
@onready var _prepare: Button = %PrepareButton
@onready var _level: Label = %LevelLabel
@onready var _level_banner: Control = %LevelBanner
@onready var _chest_slots: HBoxContainer = %ChestSlots


func _ready() -> void:
	_refresh_level()
	_level_banner.mouse_filter = Control.MOUSE_FILTER_STOP
	_level_banner.gui_input.connect(_on_banner_input)
	for i in ChestDB.SLOTS:
		var slot := ChestSlot.new()
		slot.setup(i)
		slot.pressed.connect(_on_slot_pressed)
		_chest_slots.add_child(slot)
	_play.pressed.connect(func() -> void:
		AudioManager.play("ui_click")
		play_pressed.emit())
	_prepare.pressed.connect(_open_formation)
	_daily.pressed.connect(_claim_daily)
	MissionManager.changed.connect(_refresh_daily)
	_refresh_daily()


## "LEVEL n - MINI BOSS" / "BOSS" for the level the next battle plays.
func _refresh_level() -> void:
	_level.text = "LEVEL %d  -  %s" % [Game.level_index, "BOSS" if LevelDB.is_boss_level(Game.level_index) else "MINI BOSS"]


func _on_banner_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_open_level_select()


## Level list: beaten levels + the current unbeaten one can be picked.
func _open_level_select() -> void:
	AudioManager.play("ui_click")
	var level := await LevelSelectPopup.pick(get_tree().current_scene, Game.level_index)
	if level > 0 and Game.select_level(level):
		_refresh_level()


## Prepare your army: pick the (1..5) unit classes that go to battle.
func _open_formation() -> void:
	AudioManager.play("ui_click")
	get_tree().current_scene.add_child(FORMATION_POPUP.instantiate())


## "DAILY !" while today's login reward is waiting.
func _refresh_daily() -> void:
	_daily.text = "DAILY !" if MissionManager.login_next_day() > 0 else "DAILY"


## Claims today's login reward (7-day strip on the Missions page).
func _claim_daily() -> void:
	AudioManager.play("ui_click")
	var day := MissionManager.login_next_day()
	var reward := MissionManager.claim_login(RandomNumberGenerator.new())
	if reward.is_empty():
		toast_requested.emit("Daily reward already claimed. Come back tomorrow")
		return
	await RewardPopup.show_reward(get_tree().current_scene, "DAILY LOGIN  -  DAY %d" % day, reward)


## Tap on a chest slot: show what is inside (unknown units as ???), then open it on request.
func _on_slot_pressed(index: int) -> void:
	AudioManager.play("ui_click")
	var chest: Dictionary = PlayerData.chest_slots[index]
	if chest.is_empty():
		toast_requested.emit("Empty slot. Beat a level to get a chest")
		return
	var host := get_tree().current_scene
	if not await ChestPopup.ask(host, index):
		return
	var reward := PlayerData.open_chest(index)
	if reward.is_empty():
		return
	SaveManager.save_now()
	var tier := int(chest["tier"])
	await RewardPopup.show_reward(host, ChestDB.name_of(tier).to_upper(), reward, "", ChestDB.icon_of(tier))

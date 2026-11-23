class_name HomePage
extends Control
## Main menu home: logo, level banner (tap to pick a beaten level), PLAY, daily reward,
## the free chest (rewarded ad, 30 min cooldown) and the 4 chest slots (chests dropped by beaten levels:
## tap one to see what is inside and open it).

signal play_pressed()
signal toast_requested(text: String)

@onready var _play: Button = %PlayButton
@onready var _daily: Button = %DailyButton
@onready var _chest: Button = %ChestButton
@onready var _level: Label = %LevelLabel
@onready var _level_banner: Control = %LevelBanner
@onready var _chest_slots: HBoxContainer = %ChestSlots

var _chest_tick: float = 0.0


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
	_daily.pressed.connect(_claim_daily)
	MissionManager.changed.connect(_refresh_daily)
	_refresh_daily()
	_chest.pressed.connect(_open_chest)
	PlayerData.shop_changed.connect(_refresh_chest)
	_refresh_chest()


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


func _process(delta: float) -> void:
	_chest_tick -= delta
	if _chest_tick <= 0.0:
		_chest_tick = 1.0
		_refresh_chest()


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


## "FREE CHEST" when ready, otherwise the time left, disabled.
func _refresh_chest() -> void:
	var left := PlayerData.chest_seconds_left()
	_chest.disabled = left > 0
	_chest.text = "FREE CHEST" if left == 0 else "CHEST  %d:%02d" % [floori(left / 60.0), left % 60]


## Watch one ad, then roll and grant the wooden chest.
func _open_chest() -> void:
	AudioManager.play("ui_click")
	if PlayerData.chest_seconds_left() > 0:
		return
	if not AdService.is_available():
		toast_requested.emit("No ad available right now")
		return
	_chest.disabled = true
	var earned := await AdService.show_rewarded("chest")
	if not earned:
		_refresh_chest()
		toast_requested.emit("Ad not completed, no chest")
		return
	var reward := RewardDB.roll_chest(RandomNumberGenerator.new())
	PlayerData.grant(reward)
	PlayerData.start_chest_cooldown()
	SaveManager.save_now()
	_refresh_chest()
	await RewardPopup.show_reward(get_tree().current_scene, "WOODEN CHEST", reward, "", RewardDB.ICON_CHEST)


## Tap on a chest slot: show what is inside (unknown units as ???), then open it on request.
func _on_slot_pressed(index: int) -> void:
	AudioManager.play("ui_click")
	var chest: Dictionary = PlayerData.chest_slots[index]
	if chest.is_empty():
		toast_requested.emit("Empty slot. Beat a level to get a chest")
		return
	var host := get_tree().current_scene
	if not await ChestPopup.ask(host, chest):
		return
	var reward := PlayerData.open_chest(index)
	if reward.is_empty():
		return
	SaveManager.save_now()
	var tier := int(chest["tier"])
	await RewardPopup.show_reward(host, ChestDB.name_of(tier).to_upper(), reward, "", ChestDB.icon_of(tier))

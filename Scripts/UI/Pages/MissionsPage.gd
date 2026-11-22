class_name MissionsPage
extends Control
## Missions page: 7-day login strip, then daily / weekly missions and achievements (MissionManager).

signal toast_requested(text: String)

const ROW := preload("res://Scene/UI/Components/MissionRow.tscn")

@onready var _list: VBoxContainer = %List
@onready var _tab_daily: Button = %TabDaily
@onready var _tab_weekly: Button = %TabWeekly
@onready var _tab_ach: Button = %TabAchievements
@onready var _days: HBoxContainer = $Content/StripMargin/DailyLogin/Box/Days
@onready var _claim_login: Button = %ClaimLogin

var _tab := "daily"


func _ready() -> void:
	_tab_daily.pressed.connect(_select.bind("daily"))
	_tab_weekly.pressed.connect(_select.bind("weekly"))
	_tab_ach.pressed.connect(_select.bind("achievements"))
	_claim_login.pressed.connect(claim_login)
	MissionManager.changed.connect(_refresh)
	_refresh()


## Claims today's login reward and shows it. Also used by the Home page DAILY button.
func claim_login() -> void:
	AudioManager.play("ui_click")
	var day := MissionManager.login_next_day()
	var reward := MissionManager.claim_login(RandomNumberGenerator.new())
	if reward.is_empty():
		toast_requested.emit("Daily reward already claimed. Come back tomorrow")
		return
	await RewardPopup.show_reward(get_tree().current_scene, "DAILY LOGIN  -  DAY %d" % day, reward)


func _select(tab: String) -> void:
	AudioManager.play("ui_click")
	_tab = tab
	_refresh()


func _refresh() -> void:
	_refresh_login()
	for c in _list.get_children():
		c.queue_free()
	for m in MissionManager.list(_tab):
		var row := ROW.instantiate() as MissionRow
		_list.add_child(row)
		var reward: Dictionary = m["reward"]
		var gems := int(reward["gems"]) > 0
		row.setup({
			"title": m["title"], "goal": m["goal"], "progress": m["progress"], "claimed": m["claimed"],
			"reward_icon": RewardDB.ICON_GEM if gems else RewardDB.ICON_GOLD,
			"reward": int(reward["gems"]) if gems else int(reward["gold"]),
		})
		var id: String = m["id"]
		row.get_node("%ClaimButton").pressed.connect(_claim.bind(id))


func _refresh_login() -> void:
	var claimed := MissionManager.login_claimed_days()
	var next := MissionManager.login_next_day()
	for i in MissionDB.LOGIN.size():
		var spec: Dictionary = MissionDB.LOGIN[i]
		var day := _days.get_node("Day%d" % (i + 1)) as Control
		var amount := "BOX" if bool(spec.get("box", false)) else str(int(spec.get("gold", spec.get("shards", 0))))
		(day.get_node("Amount") as Label).text = amount
		day.modulate.a = 0.4 if i < claimed else 1.0
	_claim_login.disabled = next == 0
	_claim_login.text = "CLAIM DAY %d" % next if next > 0 else "CLAIMED - COME BACK TOMORROW"
	_claim_login.theme_type_variation = &"ButtonGold" if next > 0 else &"ButtonDisabled"


func _claim(id: String) -> void:
	AudioManager.play("ui_click")
	var reward := MissionManager.claim(_tab, id)
	if reward.is_empty():
		return
	await RewardPopup.show_reward(get_tree().current_scene, "MISSION COMPLETE", reward)

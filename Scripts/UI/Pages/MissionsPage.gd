class_name MissionsPage
extends Control
## Missions page with static placeholder data (real missions: progression phase).

signal toast_requested(text: String)

const ROW := preload("res://Scene/UI/Components/MissionRow.tscn")
const GOLD := "res://Assets/UI/icon_gold.png"
const SHARD := "res://Assets/UI/icon_shard.png"
const GEM := "res://Assets/UI/icon_gem.png"

const DATA := {
	"daily": [
		{"title": "Defeat 100 enemies", "goal": 100, "progress": 100, "reward_icon": GOLD, "reward": 300},
		{"title": "Complete 3 battles", "goal": 3, "progress": 1, "reward_icon": SHARD, "reward": 5},
		{"title": "Defeat one boss", "goal": 1, "progress": 0, "reward_icon": GOLD, "reward": 500},
	],
	"weekly": [
		{"title": "Defeat 1000 enemies", "goal": 1000, "progress": 340, "reward_icon": GOLD, "reward": 2000},
		{"title": "Collect 50 soldier shards", "goal": 50, "progress": 12, "reward_icon": GEM, "reward": 20},
		{"title": "Upgrade 3 soldiers", "goal": 3, "progress": 0, "reward_icon": SHARD, "reward": 25},
	],
	"achievements": [
		{"title": "Reach level 5", "goal": 5, "progress": 1, "reward_icon": GEM, "reward": 50},
		{"title": "Own every soldier class", "goal": 5, "progress": 5, "reward_icon": GEM, "reward": 30},
		{"title": "Defeat the Iron Colossus", "goal": 1, "progress": 0, "reward_icon": GEM, "reward": 100},
	],
}

@onready var _list: VBoxContainer = %List
@onready var _tab_daily: Button = %TabDaily
@onready var _tab_weekly: Button = %TabWeekly
@onready var _tab_ach: Button = %TabAchievements


func _ready() -> void:
	_tab_daily.pressed.connect(_show.bind("daily"))
	_tab_weekly.pressed.connect(_show.bind("weekly"))
	_tab_ach.pressed.connect(_show.bind("achievements"))
	_show("daily")


func _show(tab: String) -> void:
	for c in _list.get_children():
		c.queue_free()
	for m in DATA[tab]:
		var row := ROW.instantiate() as MissionRow
		_list.add_child(row)
		row.setup(m)
		row.get_node("%ClaimButton").pressed.connect(func() -> void: toast_requested.emit("Mission rewards come with the progression phase"))

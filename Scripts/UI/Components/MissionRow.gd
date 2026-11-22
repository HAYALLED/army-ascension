class_name MissionRow
extends PanelContainer
## One mission / achievement line: title, progress bar, reward and a CLAIM button.

@onready var _title: Label = %TitleLabel
@onready var _bar: TextureProgressBar = %Bar
@onready var _progress: Label = %ProgressLabel
@onready var _reward_icon: TextureRect = %RewardIcon
@onready var _reward: Label = %RewardLabel
@onready var _claim: Button = %ClaimButton


## m = { title, goal, progress, reward_icon, reward, claimed }
func setup(m: Dictionary) -> void:
	if not is_node_ready():
		await ready
	var goal: int = m["goal"]
	var done: int = m["progress"]
	var claimed: bool = m.get("claimed", false)
	_title.text = m["title"]
	_bar.max_value = goal
	_bar.value = mini(done, goal)
	_progress.text = "%d/%d" % [mini(done, goal), goal]
	_reward_icon.texture = load(m["reward_icon"])
	_reward.text = str(m["reward"])
	var complete := done >= goal and not claimed
	_claim.text = "DONE" if claimed else ("CLAIM" if complete else "GO")
	_claim.theme_type_variation = &"ButtonGold" if complete else &"ButtonDisabled"
	_claim.disabled = not complete
	modulate.a = 0.6 if claimed else 1.0

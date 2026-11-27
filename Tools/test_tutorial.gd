extends Node
## Headless test of the tutorial: save flag, reward rules, a scripted run through all nine steps in a
## real battle, the army safety net, the victory popup, HOW TO PLAY and the home coach marks. Run:
## godot --headless --path . res://Tools/test_tutorial.tscn
## Never writes a save file.

const STEP_ORDER: Array[StringName] = [&"welcome", &"drag", &"gates", &"red_gate", &"shoot", &"spikes", &"loot", &"boss", &"finish"]
const TIME_SCALE := 5.0
const MAX_FRAMES := 9000

var _failed := 0
var _battle: Node = null
var _hud: HUD = null
var _director: TutorialDirector = null
var _overlay: TutorialOverlay = null
var _step_frames := 0
var _last_id: StringName = &""


func _check(name: String, ok: bool) -> void:
	print("%s  %s" % ["PASS" if ok else "FAIL", name])
	if not ok:
		_failed += 1


func _ready() -> void:
	SaveManager.enabled = false
	_test_data()
	_test_icon_placeholder()
	await _test_battle()
	await _test_how_to_play()
	await _test_coach()
	Engine.time_scale = 1.0
	Game.tutorial = false
	Game.tutorial_replay = false
	get_tree().quit(0 if _failed == 0 else 1)


# ---------------------------------------------------------------- data and save

func _test_data() -> void:
	PlayerData.reset_to_defaults()
	_check("1a fresh profile starts the tutorial", PlayerData.should_start_tutorial())
	var gold_before := PlayerData.gold
	var reward := PlayerData.finish_tutorial(true)
	_check("1b first completion pays %d gold" % TutorialDB.REWARD_GOLD, int(reward.get("gold", 0)) == TutorialDB.REWARD_GOLD and PlayerData.gold == gold_before + TutorialDB.REWARD_GOLD)
	_check("1c reward chest sits in slot 0, already unlocked", int(reward.get("slot", -1)) == 0 and not PlayerData.chest_slots[0].is_empty() and PlayerData.chest_left(0) == 0)
	_check("1d tutorial is done, never starts again", PlayerData.tutorial_done and not PlayerData.should_start_tutorial())
	var again := PlayerData.finish_tutorial(true)
	_check("1e the reward is paid only once", again.is_empty() and PlayerData.gold == gold_before + TutorialDB.REWARD_GOLD)
	var saved := PlayerData.to_save()
	_check("1f tutorial_done is saved", saved.get("tutorial_done") == true)
	PlayerData.apply_save(saved)
	_check("1g tutorial_done survives a reload", PlayerData.tutorial_done)
	var old_save := saved.duplicate(true)
	old_save.erase("tutorial_done")
	PlayerData.apply_save(old_save)
	_check("1h an old save without the key loads as not done", not PlayerData.tutorial_done)
	var bad_save := saved.duplicate(true)
	bad_save["tutorial_done"] = "yes"
	PlayerData.apply_save(bad_save)
	_check("1i a wrong-typed value is ignored", not PlayerData.tutorial_done)
	PlayerData.reset_to_defaults()
	var gold_skip := PlayerData.gold
	PlayerData.finish_tutorial(false)
	_check("1j skipping marks it done without gold or chest", PlayerData.tutorial_done and PlayerData.gold == gold_skip and PlayerData.chest_slots[0].is_empty())
	PlayerData.reset_to_defaults()
	PlayerData.highest_level = 3
	_check("1k a player who already won a level is never forced into it", not PlayerData.should_start_tutorial())
	PlayerData.reset_to_defaults()
	Game.tutorial = false
	Game._begin_tutorial(false)
	_check("1l first run pays a reward (not a replay)", Game.tutorial and not Game.tutorial_replay and Game.level_index == 1)
	PlayerData.tutorial_done = true
	Game.tutorial = false
	Game._begin_tutorial(false)
	_check("1m a finished tutorial is a replay (no reward)", Game.tutorial_replay)
	Game.tutorial = false
	PlayerData.reset_to_defaults()


func _test_icon_placeholder() -> void:
	var icon := TutorialIcon.new()
	icon.kind = &"portrait"
	icon.texture_path = "res://Assets/UI/Tutorial/this_file_does_not_exist.png"
	add_child(icon)
	_check("2a a missing png falls back to the placeholder", not icon.has_art())
	icon.queue_free()
	var files: Array[String] = [
		"res://Assets/Units/tutorial_guide.glb", "res://Assets/Ingame/tutorial_flag.glb",
		TutorialDB.ARROW_TEXTURE, TutorialDB.art("highlight_ring.png"), TutorialDB.art("bubble_9slice.png"),
		TutorialDB.art("hand_drag.png"), TutorialDB.art("hand_tap.png"), TutorialDB.art("ribbon_training.png"),
		TutorialDB.art("guide_portrait_talk.png"), TutorialDB.art("guide_portrait_warn.png"), TutorialDB.art("guide_portrait_cheer.png")]
	for f in TutorialDB.HOWTO:
		files.append(TutorialDB.art(String(f["art"])))
	for path in files:
		_check("2a art file exists: %s" % path.get_file(), FileAccess.file_exists(path))
	for f in TutorialDB.HOWTO:
		_check("2b slide art name ends in .png (%s)" % f["art"], String(f["art"]).ends_with(".png"))


# ---------------------------------------------------------------- the battle

func _fresh_battle() -> void:
	get_tree().paused = false
	PlayerData.reset_to_defaults()
	Game.level_index = 1
	Game.tutorial = true
	Game.tutorial_replay = false
	Game.reset_run()
	_battle = load("res://Scene/Ingame/Battle.tscn").instantiate()
	add_child(_battle)
	await _wait(0.5)
	_hud = _battle.get_node("HUD") as HUD
	_director = _battle.get_node_or_null("TutorialDirector") as TutorialDirector
	_overlay = _battle.get_node_or_null("TutorialOverlay") as TutorialOverlay


func _test_battle() -> void:
	await _fresh_battle()
	var level := _battle.get_node("Level")
	_check("3a the tutorial level replaced Level01", level.name == "Level" and level.get_node_or_null("Markers/MiniBossSpawn") != null and Game.level_index == 1)
	_check("3b two gates, one spike wall, two waves", Game.gates.size() == 2 and Game.walls.size() == 1 and level.get_node("Waves").get_child_count() == 2)
	_check("3c guide, overlay and director exist", _battle.get_node_or_null("TutorialGuide") != null and _overlay != null and _director != null)
	var boss := (_battle as Battle).boss
	_check("3d boss has 30%% of its normal health", boss != null and boss.hp < EnemyDB.DATA[boss.kind]["health"] * 0.31)
	_check("3e first step is the welcome card and the army is held", _director.current_id() == &"welcome" and Game.army.forward_speed == 0.0 and _overlay.is_card_visible())

	# safety net: wipe the army, the battle must go on
	for s: Soldier in Game.soldiers.duplicate():
		s.take_damage(999999.0)
	await _wait(0.6)
	_check("4a army wiped -> battle goes on", Game.state == Game.State.PLAYING)
	_check("4b army was refilled to the minimum", Game.soldiers.size() >= TutorialDB.MIN_ARMY)

	# scripted run
	Engine.time_scale = TIME_SCALE
	var gold_before := PlayerData.gold
	for i in MAX_FRAMES:
		await get_tree().process_frame
		if Game.state != Game.State.PLAYING:
			break
		_pilot()
	Engine.time_scale = 1.0
	_check("5a battle ended in a win", Game.state == Game.State.WON)
	_check("5b steps ran in order: %s" % [_director.step_log], _director.step_log == STEP_ORDER)
	_check("5c no run gold credited, only the reward", Game.credited_gold == 0 and PlayerData.gold == gold_before + TutorialDB.REWARD_GOLD)
	_check("5d tutorial done, no level progress", PlayerData.tutorial_done and PlayerData.highest_level == 0)
	_check("5e reward chest is in slot 0", not PlayerData.chest_slots[0].is_empty())
	_check("5f home coach marks are queued", Game.coach_pending)
	_check("5g the army was released again", Game.army.forward_speed > 0.0)
	await _wait(TutorialDB.FINISH_DELAY / TIME_SCALE + 1.0)
	_check("6a TRAINING COMPLETE popup is open", _hud._overlay.visible and _hud._mode == HUD.Mode.WIN and _hud._title.text == TutorialDB.TITLE_DONE)
	_check("6b popup shows the reward", _hud._stats.text.contains(str(TutorialDB.REWARD_GOLD)))
	_check("6c only one button (TO BASE)", _hud._primary.visible and not _hud._secondary.visible and not _hud._tertiary.visible)
	_battle.queue_free()
	await get_tree().process_frame
	Game.coach_pending = false


## Steers like a player: left into gate 1, right into gate 2, then the free left side past the spikes.
func _pilot() -> void:
	var army := Game.army
	var id := _director.current_id()
	if id != _last_id:
		_last_id = id
		_step_frames = 0
	_step_frames += 1
	match id:
		&"welcome":
			_overlay.continue_pressed.emit()
		&"drag":
			army.target_x = -3.5 if _step_frames < 40 else 3.5
		_:
			var z := army.position.z
			if z > -3.0:
				return
			army.target_x = -3.5 if z > -42.0 else (3.5 if z > -85.0 else -2.5)


# ---------------------------------------------------------------- explainer and coach

func _test_how_to_play() -> void:
	var popup := load("res://Scene/Menus/Popups/HowToPlayPopup.tscn").instantiate() as HowToPlayPopup
	add_child(popup)
	await get_tree().process_frame
	_check("7a one dot per slide", popup._dot_nodes.size() == TutorialDB.HOWTO.size())
	_check("7b first slide: BACK disabled, NEXT", popup._back.disabled and popup._next.text == TutorialDB.HOWTO_NEXT)
	for i in TutorialDB.HOWTO.size() - 1:
		popup._on_next()
	_check("7c last slide: button reads DONE", popup._next.text == TutorialDB.HOWTO_DONE and popup._title.text == String(TutorialDB.HOWTO[TutorialDB.HOWTO.size() - 1]["title"]))
	popup._on_next()
	await get_tree().process_frame
	_check("7d DONE closes the popup", not is_instance_valid(popup))


func _test_coach() -> void:
	PlayerData.reset_to_defaults()
	Game.coach_pending = true
	var menu := load("res://Scene/Menus/MainMenu.tscn").instantiate()
	add_child(menu)
	await _wait(0.5)
	var coach: TutorialCoach = null
	for c in menu.get_children():
		if c is TutorialCoach:
			coach = c
	_check("8a the coach starts after the first tutorial", coach != null and not Game.coach_pending)
	if coach == null:
		menu.queue_free()
		return
	_check("8b every coach target exists (%d of %d)" % [coach._steps.size(), TutorialDB.COACH.size()], coach._steps.size() == TutorialDB.COACH.size())
	var n := coach._steps.size()
	for i in n:
		coach._on_next()
	await get_tree().process_frame
	_check("8c NEXT through all marks closes the coach", not is_instance_valid(coach))
	menu.queue_free()
	await get_tree().process_frame


## Waits real frames (the tree may be paused, so this does not use timers).
func _wait(seconds: float) -> void:
	var frames := int(seconds * 60.0)
	for i in frames:
		await get_tree().process_frame

class_name TutorialDirector
extends Node
## Runs the tutorial level (added by Battle when Game.tutorial is true). Walks TutorialDB.STEPS in order:
## a step starts when its trigger is true (a distance, a wave), shows the guide card and a hint, optionally
## holds the army, and ends when its condition is met. The tutorial can not be lost: the army is refilled
## to TutorialDB.MIN_ARMY. Every trigger and condition tolerates a missing level node (the step is skipped).

var guide: TutorialGuide = null
var overlay: TutorialOverlay = null
var hud: HUD = null
var level: Level = null
## Ids of the steps that have started, in order (read by Tools/test_tutorial.gd).
var step_log: Array[StringName] = []

var _idx: int = 0
var _active: bool = false
var _held: bool = false
var _saved_speed: float = 6.0
var _continue: bool = false
var _drag_start: float = 0.0
var _drag_min: float = 0.0
var _drag_max: float = 0.0
var _waves_seen: Dictionary = {}
var _wave_grace: Dictionary = {}
var _gates: Array[GatePair] = []
var _arrows: Array[TutorialArrow] = []
var _ring_targets: Array[Control] = []
var _ring_caption: String = ""
var _rescue_cd: float = 0.0
var _finished: bool = false


func setup(p_guide: TutorialGuide, p_overlay: TutorialOverlay, p_hud: HUD, p_level: Level) -> void:
	guide = p_guide
	overlay = p_overlay
	hud = p_hud
	level = p_level
	_gates = Game.gates.duplicate()
	_gates.sort_custom(func(a: GatePair, b: GatePair) -> bool: return a.position.z > b.position.z)
	Game.wave_started.connect(_on_wave_started)
	Game.battle_won.connect(_on_battle_won)
	Game.tutorial_rescued.connect(_on_rescued)
	overlay.continue_pressed.connect(_on_continue)
	overlay.skip_pressed.connect(Game.skip_tutorial)


## Id of the running step ("" when none).
func current_id() -> StringName:
	if _active and _idx < TutorialDB.STEPS.size():
		return TutorialDB.STEPS[_idx]["id"]
	return &""


func _exit_tree() -> void:
	_set_hold(false)
	_clear_arrows()


func _process(delta: float) -> void:
	if Game.state != Game.State.PLAYING or Game.army == null or _finished:
		return
	_rescue_cd = maxf(_rescue_cd - delta, 0.0)
	Game.rescue_tutorial_army()
	for k in _wave_grace.keys():
		_wave_grace[k] = float(_wave_grace[k]) - delta
	# The finish step is started by the victory signal, not by this loop.
	if _idx >= TutorialDB.STEPS.size() - 1:
		return
	var step: Dictionary = TutorialDB.STEPS[_idx]
	var id: StringName = step["id"]
	if not _active:
		if _can_start(id):
			_begin(step)
		return
	_update_drag(id)
	_update_ring()
	if _is_done(id):
		_end(step)


# ---------------------------------------------------------------- step flow

func _begin(step: Dictionary) -> void:
	_active = true
	_continue = false
	var id: StringName = step["id"]
	step_log.append(id)
	var hold: bool = step["hold"]
	var button: String = step["button"]
	var auto_hide := 0.0 if (hold or button != "") else TutorialDB.CARD_AUTO_HIDE
	overlay.show_card(step["text"], step["portrait"], button, auto_hide)
	if hold:
		_set_hold(true)
	_show_hint(step["hint"])
	if step["portrait"] == &"warn":
		guide.warn()
	if id == &"drag":
		_drag_start = Game.army.target_x
		_drag_min = _drag_start
		_drag_max = _drag_start
	elif id == &"boss":
		guide.lead = TutorialDB.GUIDE_RETREAT


func _end(step: Dictionary) -> void:
	var id: StringName = step["id"]
	_active = false
	overlay.hide_card()
	if id == &"red_gate" and _took_red_gate():
		overlay.show_card(TutorialDB.OUCH_LINE, &"warn", "", 4.0)
	overlay.hide_hand()
	overlay.hide_ring()
	_ring_targets.clear()
	_clear_arrows()
	_set_hold(false)
	if id == &"drag" or id == &"gates" or id == &"loot":
		guide.cheer()
	_idx += 1


func _can_start(id: StringName) -> bool:
	var z := Game.army.position.z
	match id:
		&"welcome", &"drag":
			return true
		&"gates":
			return _gate(0) == null or z <= _gate(0).position.z + TutorialDB.GATE_LEAD
		&"red_gate":
			return _gate(1) == null or z <= _gate(1).position.z + TutorialDB.GATE_LEAD
		&"shoot":
			return _waves_seen.has(1)
		&"spikes":
			return _wall_z() == INF or z <= _wall_z() + TutorialDB.SPIKE_LEAD
		&"loot":
			return _waves_seen.has(2)
		&"boss":
			return z <= level.arena_stop.position.z + TutorialDB.BOSS_LEAD
	return false


func _is_done(id: StringName) -> bool:
	match id:
		&"welcome":
			return _continue
		&"drag":
			return _drag_start - _drag_min >= TutorialDB.DRAG_NEED and _drag_max - _drag_start >= TutorialDB.DRAG_NEED
		&"gates":
			return _gate(0) == null or _gate(0).used
		&"red_gate":
			return _gate(1) == null or _gate(1).used
		&"shoot":
			return _wave_cleared(1)
		&"spikes":
			return _wall_z() == INF or Game.army.position.z < _wall_z() - 2.0
		&"loot":
			return _wave_cleared(2)
		&"boss":
			return _boss_dead()
	return false


# ---------------------------------------------------------------- helpers

func _gate(i: int) -> GatePair:
	return _gates[i] if i < _gates.size() else null


## Z of the first spike wall (INF when the level has none).
func _wall_z() -> float:
	if Game.walls.is_empty():
		return INF
	return float(Game.walls[0]["z"])


## True when the army went through the soldier-losing side of the second gate.
func _took_red_gate() -> bool:
	var g := _gate(1)
	if g == null or not g.used:
		return false
	return int(g.left_def.get("effect", -1)) == GatePair.Effect.SUBTRACT and Game.army.position.x < g.position.x


func _wave_cleared(index: int) -> bool:
	if not _waves_seen.has(index) or float(_wave_grace.get(index, 0.0)) > 0.0:
		return false
	for e in Game.enemies:
		if is_instance_valid(e) and not (e is Boss) and not e.dead:
			return false
	return true


func _boss_dead() -> bool:
	for e in Game.enemies:
		if is_instance_valid(e) and e is Boss and not e.dead:
			return false
	return true


func _update_drag(id: StringName) -> void:
	if id != &"drag":
		return
	var x := Game.army.target_x
	_drag_min = minf(_drag_min, x)
	_drag_max = maxf(_drag_max, x)


## Holds / releases the army. Safe to call repeatedly.
func _set_hold(on: bool) -> void:
	var army := Game.army
	if not is_instance_valid(army) or on == _held:
		return
	_held = on
	if on:
		_saved_speed = army.forward_speed
		army.forward_speed = 0.0
	else:
		army.forward_speed = _saved_speed


# ---------------------------------------------------------------- hints

func _show_hint(hint: StringName) -> void:
	match hint:
		&"hand_drag":
			overlay.show_hand(&"drag")
		&"arrows_gate":
			var g := _gate(0)
			if g != null:
				_arrows.append(TutorialArrow.make(_world(), Vector3(g.position.x - 3.5, 3.6, g.position.z)))
				_arrows.append(TutorialArrow.make(_world(), Vector3(g.position.x + 3.5, 3.6, g.position.z)))
		&"arrow_red":
			var g := _gate(1)
			if g != null:
				_arrows.append(TutorialArrow.make(_world(), Vector3(g.position.x - 3.5, 3.6, g.position.z), Color(1.0, 0.35, 0.3)))
		&"arrow_gap":
			if not Game.walls.is_empty():
				var w: Dictionary = Game.walls[0]
				var gap_x := -2.6 if float(w["x"]) > 0.0 else 2.6
				_arrows.append(TutorialArrow.make(_world(), Vector3(gap_x, 3.0, float(w["z"]))))
		&"ring_army":
			_set_ring([hud.get_node_or_null("%ArmyLabel"), hud.get_node_or_null("%ArmyBar")], TutorialDB.RING_ARMY_CAPTION)
		&"ring_loot":
			_set_ring([hud.get_node_or_null("%GoldLabel"), hud.get_node_or_null("%ShardLabel"), _icon_of("%GoldLabel")], "")
		&"ring_boss":
			_set_ring([hud.get_node_or_null("%BossPanel")], "")


## 3D arrows and the planted flag live in the battle scene (our parent).
func _world() -> Node3D:
	return get_parent() as Node3D


func _icon_of(unique: String) -> Control:
	var label := hud.get_node_or_null(unique) as Control
	if label == null:
		return null
	var icon := label.get_parent().get_node_or_null("Icon") as Control
	return icon


func _set_ring(targets: Array, caption: String) -> void:
	_ring_targets.clear()
	for t in targets:
		if t is Control:
			_ring_targets.append(t)
	_ring_caption = caption
	_update_ring()


## Keeps the ring on the union of its visible targets (the boss panel only appears when the boss wakes).
func _update_ring() -> void:
	var rect := Rect2()
	var any := false
	for c in _ring_targets:
		if not is_instance_valid(c) or not c.is_visible_in_tree():
			continue
		var r := c.get_global_rect()
		rect = r if not any else rect.merge(r)
		any = true
	if any:
		overlay.show_ring(rect, _ring_caption)
	else:
		overlay.hide_ring()


func _clear_arrows() -> void:
	for a in _arrows:
		if is_instance_valid(a):
			a.queue_free()
	_arrows.clear()


# ---------------------------------------------------------------- signals

func _on_continue() -> void:
	_continue = true


func _on_wave_started(index: int, _total: int) -> void:
	_waves_seen[index] = true
	# wave_started fires before the enemies exist; give them a moment to spawn
	_wave_grace[index] = 0.4


func _on_rescued() -> void:
	if _rescue_cd > 0.0 or (_active and TutorialDB.STEPS[_idx]["hold"]):
		return
	_rescue_cd = TutorialDB.RESCUE_COOLDOWN
	overlay.show_card(TutorialDB.RESCUE_LINE, &"talk", "", 3.0)
	guide.cheer()


## Boss dead and the victory popup is about to open: the guide plants his flag first.
func _on_battle_won() -> void:
	if _finished:
		return
	_finished = true
	_active = false
	_set_hold(false)
	overlay.hide_hand()
	overlay.hide_ring()
	_clear_arrows()
	var step: Dictionary = TutorialDB.STEPS[TutorialDB.STEPS.size() - 1]
	step_log.append(step["id"])
	_idx = TutorialDB.STEPS.size()
	var army := Game.army
	var pos := Vector3(0.0, 0.0, army.position.z - 4.0) if army != null else Vector3.ZERO
	guide.plant_flag(_world(), pos)
	overlay.show_card(step["text"], step["portrait"], "", TutorialDB.FINISH_DELAY)

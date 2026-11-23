class_name LevelRandomizer
extends RefCounted
## Re-rolls the gates (buffs) and spike traps (obstacles) of a level scene on every
## battle start, so a replayed level never looks the same. Used for every level
## except level 1, which keeps its hand-placed layout. Waves and arenas are untouched.
##
## plan() is a pure function (no nodes) so it can be tested; apply() builds the nodes.
##
## Layout rules:
##  - Buffs come right before the fights: 2 gate pairs before the first wave, 1 before every other
##    wave, always 10-14 m (the near gate) before the wave trigger, so the buff is in the army when
##    the enemies arrive. The second gate of the first wave is 28-32 m before it.
##  - Obstacles come in rows (1-2 spike blocks at the same z) in the quiet stretch between two
##    waves (the fight is over, the next gate is still ahead). Every row leaves one free corridor at
##    least MIN_GAP wide: a full 7-column army (4.7 m) plus margin fits through.
##  - Every gate pair and spike row is at least MIN_CLEAR apart in z, so a gate choice never overlaps
##    a trap and the army has time to strafe to the next corridor.
##  - At most MAX_MULTIPLY "x soldiers" gates per level, so the army does not explode to the cap.

const GATE_SCENE := preload("res://Scene/Ingame/GatePair.tscn")
const TRAP_SCENE := preload("res://Scene/Ingame/SpikeWall.tscn")

const MIN_CLEAR := 14.0
const MIN_GAP := 6.5
const MAX_MULTIPLY := 2
const GATES_BEFORE_FIRST_WAVE := 2
## Gate distance before its wave trigger: [min, max].
const LEAD_NEAR := Vector2(10.0, 14.0)
const LEAD_FAR := Vector2(28.0, 32.0)
## Spike rows start this far past a wave trigger (the fight is mostly over).
const ROW_AFTER_WAVE := 38.0
const MAX_ROWS_PER_GAP := 2

const E := GatePair.Effect
## [effect, weight]
const KIND_WEIGHTS := [[E.ADD, 4], [E.MULTIPLY, 2], [E.DAMAGE, 3], [E.RATE, 3]]
const DAMAGE_VALUES := [0.15, 0.2, 0.25, 0.3]
const RATE_VALUES := [0.15, 0.2, 0.25]


## Replaces the Gates / Traps children of `level` with a fresh random layout.
## Call before the children enter the tree (Level._enter_tree): old ones are freed at once,
## so they never register in Game.gates / Game.walls. seed_value 0 = random.
static func apply(level: Node3D, level_index: int, seed_value: int = 0) -> void:
	var rng := RandomNumberGenerator.new()
	if seed_value == 0:
		rng.randomize()
	else:
		rng.seed = seed_value
	var wave_zs: Array = []
	for w in level.get_node("Waves").get_children():
		wave_zs.append((w as Node3D).position.z)
	var layout := plan(level_index, rng, wave_zs)
	var gates := level.get_node("Gates") as Node3D
	var traps := level.get_node("Traps") as Node3D
	for parent: Node3D in [gates, traps]:
		for child in parent.get_children():
			parent.remove_child(child)
			child.free()

	for g: Dictionary in layout["gates"]:
		var gate := GATE_SCENE.instantiate() as GatePair
		gate.position = Vector3(0.0, 0.0, g["z"])
		var l: Dictionary = g["left"]
		var r: Dictionary = g["right"]
		gate.left_effect = l["effect"]
		gate.left_value = l["value"]
		gate.left_risky = l["risky"]
		gate.right_effect = r["effect"]
		gate.right_value = r["value"]
		gate.right_risky = r["risky"]
		gates.add_child(gate)

	for t: Dictionary in layout["traps"]:
		var trap := TRAP_SCENE.instantiate() as SpikeWall
		trap.position = Vector3(t["x"], 0.0, t["z"])
		trap.segments = t["segments"]
		traps.add_child(trap)


## Random layout for waves triggering at `wave_zs`:
## {"gates": [{z, left, right}], "traps": [{z, x, segments}], "rows": [[trap, ...]]}.
## left / right = {effect, value, risky}. Same data the nodes are built from.
static func plan(_level_index: int, rng: RandomNumberGenerator, wave_zs: Array) -> Dictionary:
	var waves: Array = wave_zs.duplicate()
	waves.sort()
	waves.reverse()  # nearest to the army start first (z counts down)

	var gates: Array = []
	var gate_zs: Array = []
	var multiply_left := MAX_MULTIPLY
	for i in waves.size():
		var leads: Array = [rng.randf_range(LEAD_NEAR.x, LEAD_NEAR.y)]
		if i == 0 and GATES_BEFORE_FIRST_WAVE > 1:
			leads.push_front(rng.randf_range(LEAD_FAR.x, LEAD_FAR.y))
		for lead: float in leads:
			var gate := _gate(float(waves[i]) + lead, rng, multiply_left > 0)
			for side in ["left", "right"]:
				if int(gate[side]["effect"]) == E.MULTIPLY:
					multiply_left -= 1
			gates.append(gate)
		gate_zs.append(float(waves[i]) + float(leads[-1]))

	var traps: Array = []
	var rows: Array = []
	for i in range(waves.size() - 1):
		var top := float(waves[i]) - ROW_AFTER_WAVE
		var span := top - (float(gate_zs[i + 1]) + MIN_CLEAR)
		if span < 0.0:
			continue
		var count := rng.randi_range(1, mini(MAX_ROWS_PER_GAP, floori(span / MIN_CLEAR) + 1))
		var slack := span - MIN_CLEAR * float(count - 1)
		var offsets: Array = []
		for k in count:
			offsets.append(rng.randf_range(0.0, slack))
		offsets.sort()
		for k in count:
			var z := top - (float(offsets[k]) + MIN_CLEAR * float(k))
			var row: Array = []
			for b in _row(rng):
				var trap := {"z": z, "x": b["x"], "segments": b["segments"]}
				traps.append(trap)
				row.append(trap)
			rows.append(row)
	return {"gates": gates, "traps": traps, "rows": rows}


## Widest free stretch (m) of the road left by a row of blocks [{x, segments}].
static func widest_gap(blocks: Array) -> float:
	var spans: Array = []
	for b in blocks:
		var half := float(b["segments"]) * SpikeWall.SEGMENT_WIDTH * 0.5
		spans.append([float(b["x"]) - half, float(b["x"]) + half])
	spans.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	var best := 0.0
	var cursor := -Army.FIELD_HALF
	for s: Array in spans:
		best = maxf(best, s[0] - cursor)
		cursor = maxf(cursor, s[1])
	return maxf(best, Army.FIELD_HALF - cursor)


## 1-2 spike blocks inside the road with a free corridor of at least MIN_GAP.
static func _row(rng: RandomNumberGenerator) -> Array:
	for attempt in 40:
		var blocks: Array = []
		for i in rng.randi_range(1, 2):
			var segs := rng.randi_range(1, 2)
			var reach := Army.FIELD_HALF - float(segs) * SpikeWall.SEGMENT_WIDTH * 0.5
			blocks.append({"segments": segs, "x": rng.randf_range(-reach, reach)})
		if widest_gap(blocks) >= MIN_GAP:
			return blocks
	# Always valid: one 7 m wall on a random side leaves a 7 m corridor.
	return [{"segments": 2, "x": -3.5 if rng.randf() < 0.5 else 3.5}]


static func _gate(z: float, rng: RandomNumberGenerator, allow_multiply: bool) -> Dictionary:
	var first := _pick_kind(rng, -1, allow_multiply)
	var second := _pick_kind(rng, first, allow_multiply and first != E.MULTIPLY)
	var sides := [_side(first, rng), _side(second, rng)]
	_shuffle(sides, rng)
	return {"z": z, "left": sides[0], "right": sides[1]}


## Array.shuffle() ignores our RNG, so a seeded layout would not repeat.
static func _shuffle(list: Array, rng: RandomNumberGenerator) -> void:
	for i in range(list.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = list[i]
		list[i] = list[j]
		list[j] = tmp


## Weighted effect pick; never `exclude` (so the two sides are a real choice).
static func _pick_kind(rng: RandomNumberGenerator, exclude: int, allow_multiply: bool) -> int:
	var total := 0
	for k: Array in KIND_WEIGHTS:
		if k[0] != exclude and (allow_multiply or k[0] != E.MULTIPLY):
			total += int(k[1])
	var roll := rng.randi_range(1, total)
	for k: Array in KIND_WEIGHTS:
		if k[0] == exclude or (not allow_multiply and k[0] == E.MULTIPLY):
			continue
		roll -= int(k[1])
		if roll <= 0:
			return k[0]
	return E.ADD


static func _side(effect: int, rng: RandomNumberGenerator) -> Dictionary:
	match effect:
		E.ADD:
			return {"effect": effect, "value": float(rng.randi_range(4, 8)), "risky": false}
		E.MULTIPLY:
			var three := rng.randf() < 0.25
			return {"effect": effect, "value": 3.0 if three else 2.0, "risky": three}
		E.DAMAGE:
			return {"effect": effect, "value": DAMAGE_VALUES[rng.randi() % DAMAGE_VALUES.size()], "risky": false}
	return {"effect": E.RATE, "value": RATE_VALUES[rng.randi() % RATE_VALUES.size()], "risky": false}

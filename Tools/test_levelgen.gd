extends Node
## Headless random-level tests. Run: godot --headless --path . res://Tools/test_levelgen.tscn

const SEEDS := 300

var _failed := 0


func _check(name: String, ok: bool) -> void:
	print("%s  %s" % ["PASS" if ok else "FAIL", name])
	if not ok:
		_failed += 1


func _ready() -> void:
	SaveManager.enabled = false
	_test_plans()
	await _test_battle_levels()
	print("LEVELGEN %s" % ("OK" if _failed == 0 else "FAILED (%d)" % _failed))
	get_tree().quit(1 if _failed > 0 else 0)


## Pure layout rules over many seeds.
func _test_plans() -> void:
	var waves := [-52.0, -140.0, -228.0]
	var gap_ok := true
	var inside_ok := true
	var clear_ok := true
	var gates_ok := true
	var rows_ok := true
	var choice_ok := true
	var multiply_ok := true
	var shift_ok := true
	var signatures := {}
	var worst_gap := 99.0
	for s in SEEDS:
		var rng := RandomNumberGenerator.new()
		rng.seed = s + 1
		var p := LevelRandomizer.plan(2 + s % 14, rng, waves)
		signatures[str(p)] = true
		var gates: Array = p["gates"]
		var rows: Array = p["rows"]
		gates_ok = gates_ok and gates.size() == 4
		# 2 gates before wave 1, 1 before each other wave, each 10-14 m (near) / 28-32 m (far) before its trigger
		var before := [0, 0, 0]
		for g: Dictionary in gates:
			for i in waves.size():
				var lead: float = float(g["z"]) - float(waves[i])
				if lead >= LevelRandomizer.LEAD_NEAR.x - 0.001 and lead <= LevelRandomizer.LEAD_NEAR.y + 0.001:
					before[i] += 1
				elif i == 0 and lead >= LevelRandomizer.LEAD_FAR.x - 0.001 and lead <= LevelRandomizer.LEAD_FAR.y + 0.001:
					before[i] += 1
		gates_ok = gates_ok and before == [2, 1, 1]
		rows_ok = rows_ok and rows.size() >= 2 and rows.size() <= 2 * LevelRandomizer.MAX_ROWS_PER_GAP
		var zs: Array = []
		var multiplies := 0
		for g: Dictionary in gates:
			zs.append(float(g["z"]))
			choice_ok = choice_ok and g["left"]["effect"] != g["right"]["effect"]
			for side in ["left", "right"]:
				if int(g[side]["effect"]) == GatePair.Effect.MULTIPLY:
					multiplies += 1
		multiply_ok = multiply_ok and multiplies <= LevelRandomizer.MAX_MULTIPLY
		var row_centers: Array = []
		for row: Array in rows:
			zs.append(float(row[0]["z"]))
			# rows sit between two waves, never inside a fight window
			var in_gap := false
			for i in range(waves.size() - 1):
				in_gap = in_gap or (float(row[0]["z"]) <= float(waves[i]) - LevelRandomizer.ROW_AFTER_WAVE + 0.001 and float(row[0]["z"]) > float(waves[i + 1]))
			rows_ok = rows_ok and in_gap
			var g := LevelRandomizer.widest_gap(row)
			worst_gap = minf(worst_gap, g)
			gap_ok = gap_ok and g >= LevelRandomizer.MIN_GAP
			for b: Dictionary in row:
				var half := float(b["segments"]) * SpikeWall.SEGMENT_WIDTH * 0.5
				inside_ok = inside_ok and absf(float(b["x"])) + half <= Army.FIELD_HALF + 0.001
			row_centers.append([float(row[0]["z"]), _gap_center(row)])
		zs.sort()
		for i in range(1, zs.size()):
			clear_ok = clear_ok and zs[i] - zs[i - 1] >= LevelRandomizer.MIN_CLEAR - 0.001
		# corridor shift between neighbouring rows must be doable at <= 8 m/s while the army walks 6 m/s
		row_centers.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
		for i in range(1, row_centers.size()):
			var dz: float = absf(float(row_centers[i][0]) - float(row_centers[i - 1][0]))
			var dx: float = absf(float(row_centers[i][1]) - float(row_centers[i - 1][1]))
			shift_ok = shift_ok and dx / (dz / 6.0) <= 8.0
	_check("4 gates: 2 before wave 1, 1 before wave 2, 1 before wave 3, close to the trigger", gates_ok)
	_check("2-4 spike rows, all between two waves", rows_ok)
	_check("every row leaves a corridor >= MIN_GAP (worst %.2f m)" % worst_gap, gap_ok)
	_check("spike blocks stay inside the road", inside_ok)
	_check("events >= MIN_CLEAR apart in z", clear_ok)
	_check("gate sides are different effects", choice_ok)
	_check("x-soldiers gates capped", multiply_ok)
	_check("corridor shift between rows is doable", shift_ok)
	_check("layouts differ between seeds (%d / %d unique)" % [signatures.size(), SEEDS], signatures.size() > SEEDS * 0.95)
	var a := RandomNumberGenerator.new()
	var b := RandomNumberGenerator.new()
	a.seed = 7
	b.seed = 7
	_check("same seed = same layout", str(LevelRandomizer.plan(3, a, waves)) == str(LevelRandomizer.plan(3, b, waves)))

	# other wave setups must not break the rules (waves close together = no rows, no crash)
	var odd_ok := true
	for set: Array in [[-60.0], [-50.0, -100.0, -150.0, -200.0, -250.0], [-40.0, -300.0], []]:
		for s in 50:
			var rng := RandomNumberGenerator.new()
			rng.seed = s + 1
			var p := LevelRandomizer.plan(3, rng, set)
			var zs: Array = []
			for g: Dictionary in p["gates"]:
				zs.append(float(g["z"]))
			for row: Array in p["rows"]:
				zs.append(float(row[0]["z"]))
				odd_ok = odd_ok and LevelRandomizer.widest_gap(row) >= LevelRandomizer.MIN_GAP
			zs.sort()
			for i in range(1, zs.size()):
				odd_ok = odd_ok and zs[i] - zs[i - 1] >= LevelRandomizer.MIN_CLEAR - 0.001
			odd_ok = odd_ok and p["gates"].size() == (set.size() + (LevelRandomizer.GATES_BEFORE_FIRST_WAVE - 1 if set.size() > 0 else 0))
	_check("other wave setups: gates per wave, spacing and gaps hold", odd_ok)


func _gap_center(row: Array) -> float:
	var spans: Array = []
	for b: Dictionary in row:
		var half := float(b["segments"]) * SpikeWall.SEGMENT_WIDTH * 0.5
		spans.append([float(b["x"]) - half, float(b["x"]) + half])
	spans.sort_custom(func(p: Array, q: Array) -> bool: return p[0] < q[0])
	var best := -1.0
	var best_c := 0.0
	var cursor := -Army.FIELD_HALF
	for sp: Array in spans:
		if sp[0] - cursor > best:
			best = sp[0] - cursor
			best_c = (sp[0] + cursor) * 0.5
		cursor = maxf(cursor, sp[1])
	if Army.FIELD_HALF - cursor > best:
		best_c = (Army.FIELD_HALF + cursor) * 0.5
	return best_c


## Real Battle scene: level 1 keeps the hand-made layout, later levels are re-rolled each time.
func _test_battle_levels() -> void:
	var l1 := await _load_battle(1)
	_check("level 1: hand-made layout kept (4 gates, 6 spike walls)", l1["gates"] == 4 and l1["walls"] == 6)
	var l1b := await _load_battle(1)
	_check("level 1: identical every time", l1["sig"] == l1b["sig"])

	var sigs := {}
	var ok := true
	for lv in [2, 5, 6, 10, 15]:
		for i in 3:
			var r := await _load_battle(lv)
			sigs[r["sig"]] = true
			ok = ok and r["gates"] == 4 and r["walls"] >= 2
	_check("levels 2+: node counts sane, gates + walls registered", ok)
	_check("levels 2+: layout differs between runs (%d / 15 unique)" % sigs.size(), sigs.size() >= 14)
	Game.level_index = 1


func _load_battle(level: int) -> Dictionary:
	Game.level_index = level
	var battle: Node = load("res://Scene/Ingame/Battle.tscn").instantiate()
	add_child(battle)
	await get_tree().process_frame
	var sig := []
	for g in Game.gates:
		sig.append([g.position.z, g.left_def["label"], g.left_def["sub"], g.right_def["label"], g.right_def["sub"]])
	for w in Game.walls:
		sig.append([w["z"], w["x"], w["hw"]])
	var out := {"gates": Game.gates.size(), "walls": Game.walls.size(), "sig": str(sig)}
	remove_child(battle)
	battle.free()
	await get_tree().process_frame
	return out

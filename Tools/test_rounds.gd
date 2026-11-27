extends Node
## Headless tests for rounds (16 rounds of 5 levels = 80 levels): enemy rosters, round models,
## the new enemy kinds and the Blinder / Weakener debuffs on soldiers.
## Run: godot --headless --path . res://Tools/test_rounds.tscn
## Never writes a save file.

const K := EnemyDB.Kind

var _failed := 0


func _check(name: String, ok: bool) -> void:
	print("%s  %s" % ["PASS" if ok else "FAIL", name])
	if not ok:
		_failed += 1


## Same shape as WaveTrigger.composition(); numbers of the level scene's third wave.
func _template() -> Array:
	return [[K.BASIC, 20], [K.FAST, 8], [K.ARMORED, 8], [K.RANGED, 6], [K.ELITE, 4],
		[K.KAMIKAZE, 6], [K.SNIPER, 3], [K.MEDIC, 2]]


func _count_of(comp: Array, kind: int) -> int:
	for e in comp:
		if int(e[0]) == kind:
			return int(e[1])
	return 0


func _total(comp: Array) -> int:
	var n := 0
	for e in comp:
		n += int(e[1])
	return n


func _ready() -> void:
	SaveManager.enabled = false
	_test_levels()
	_test_round1()
	_test_round23()
	await _test_models()
	_test_minions()
	_test_debuffs()
	_test_bosses()
	PlayerData.reset_to_defaults()
	Game.level_index = 1
	get_tree().quit(0 if _failed == 0 else 1)


func _test_levels() -> void:
	_check("80 levels in 16 rounds", LevelDB.TOTAL_LEVELS == 80 and LevelDB.CHAPTER_COUNT == 16 and RoundDB.round_of(1) == 1 and RoundDB.round_of(5) == 1
		and RoundDB.round_of(6) == 2 and RoundDB.round_of(10) == 2 and RoundDB.round_of(11) == 3 and RoundDB.round_of(15) == 3
		and RoundDB.round_of(16) == 4 and RoundDB.round_of(75) == 15 and RoundDB.round_of(76) == 16 and RoundDB.round_of(80) == 16)
	_check("boss levels 5, 10, 15 ... 80; others mini boss", LevelDB.is_boss_level(5) and LevelDB.is_boss_level(10) and LevelDB.is_boss_level(15)
		and LevelDB.is_boss_level(80) and LevelDB.is_mini_level(11) and LevelDB.is_mini_level(14) and LevelDB.is_mini_level(79))
	var prev := 0.0
	var steady := true
	for level in range(1, LevelDB.TOTAL_LEVELS + 1):
		Game.level_index = level
		var scale := Game.difficulty_scale()
		steady = steady and scale > prev
		prev = scale
	Game.level_index = 15
	var at_15 := Game.difficulty_scale()
	Game.level_index = 80
	var at_80 := Game.difficulty_scale()
	Game.level_index = 1
	_check("difficulty rises every level: x3.8 at 15, x10.3 at 80", steady and is_equal_approx(at_15, 3.8) and is_equal_approx(at_80, 10.3))
	_check("new kinds are not boss kinds", not EnemyDB.is_boss_kind(K.MORTAR) and not EnemyDB.is_boss_kind(K.SHOTGUNNER)
		and EnemyDB.is_boss_kind(K.MINI_COMMANDER) and EnemyDB.is_boss_kind(K.BOSS))


func _test_round1() -> void:
	var t := _template()
	var l1 := RoundDB.wave_composition(1, 2, t)
	_check("level 1 wave unchanged", _total(l1) == _total(t) and _count_of(l1, K.MORTAR) == 0)
	_check("mortar from level 2", _count_of(RoundDB.wave_composition(2, 2, t), K.MORTAR) > 0 and _count_of(RoundDB.wave_composition(2, 2, t), K.BLINDER) == 0)
	_check("blinder from level 3", _count_of(RoundDB.wave_composition(3, 2, t), K.BLINDER) > 0 and _count_of(RoundDB.wave_composition(3, 2, t), K.WEAKENER) == 0)
	_check("weakener from level 4", _count_of(RoundDB.wave_composition(4, 2, t), K.WEAKENER) > 0)
	var l5 := RoundDB.wave_composition(5, 2, t)
	_check("level 5 has mortar, blinder and weakener", _count_of(l5, K.MORTAR) > 0 and _count_of(l5, K.BLINDER) > 0 and _count_of(l5, K.WEAKENER) > 0)
	_check("round 1 has no breacher or shotgunner", _count_of(l5, K.BREACHER) == 0 and _count_of(l5, K.SHOTGUNNER) == 0)
	_check("round 1 keeps the old enemies", _count_of(l5, K.BASIC) == 20 and _count_of(l5, K.ELITE) == 4)


func _test_round23() -> void:
	var t := _template()
	for level in [6, 8, 10, 11, 13, 15, 16, 33, 47, 62, 71, 80]:
		var roster := RoundDB.roster_for(RoundDB.round_of(level))
		for wave in 3:
			var comp := RoundDB.wave_composition(level, wave, t)
			var ok := roster.size() >= 8
			for kind in roster:
				ok = ok and _count_of(comp, int(kind)) >= 1
			for e in comp:
				ok = ok and roster.has(int(e[0]))
			ok = ok and absi(_total(comp) - _total(t)) <= 4
			_check("level %d wave %d: whole roster, nothing else, same size" % [level, wave + 1], ok)


func _test_models() -> void:
	var units := Node3D.new()
	add_child(units)
	for entry in [[1, ""], [7, "_r2.glb"], [12, "_r3.glb"], [18, "_r4.glb"], [80, "_r16.glb"]]:
		Game.level_index = int(entry[0])
		for kind in RoundDB.roster_for(2):
			var e := Enemy.spawn(units, int(kind), Vector3(0, 0, -50))
			await get_tree().process_frame
			var model := e.get_node("Body/ModelSlot/Model")
			var path := String(model.scene_file_path)
			var want: String = entry[1]
			var ok: bool = path.ends_with(want) if want != "" else (not path.contains("_r2") and not path.contains("_r3"))
			_check("level %d %s uses %s model" % [entry[0], EnemyDB.DATA[kind]["name"], want if want != "" else "round 1"], ok)
			e.queue_free()
		await get_tree().process_frame
	Game.level_index = 7
	var old_kind := Enemy.spawn(units, K.BASIC, Vector3(0, 0, -50))
	await get_tree().process_frame
	var has_art := ResourceLoader.exists("res://Assets/Enemy/grunt_r2.glb")
	var uses_r2 := String(old_kind.get_node("Body/ModelSlot/Model").scene_file_path).contains("_r2")
	_check("grunt uses its r2 model exactly when grunt_r2.glb exists", uses_r2 == has_art)
	_check("grunt joins the round 2 roster exactly when its r2 model exists", RoundDB.roster_for(2).has(K.BASIC) == has_art)
	Game.level_index = 1
	units.queue_free()
	await get_tree().process_frame


func _test_minions() -> void:
	var ok := true
	for i in 60:
		ok = ok and RoundDB.roster_for(2).has(RoundDB.random_minion_kind(8)) and RoundDB.roster_for(3).has(RoundDB.random_minion_kind(13))
		ok = ok and RoundDB.roster_for(16).has(RoundDB.random_minion_kind(80))
	_check("round 2 to 16 summons only use the roster", ok)
	var seen := {}
	for i in 300:
		seen[RoundDB.random_minion_kind(1)] = true
	_check("level 1 summons use the 8 original kinds only", seen.size() >= 6 and not seen.has(K.MORTAR))
	_check("level 5 summons can include the new kinds", RoundDB.kinds_for(5).has(K.WEAKENER) and RoundDB.kinds_for(5).has(K.BLINDER))


func _test_debuffs() -> void:
	var s := SoldierDB.scene(SoldierDB.Type.RIFLEMAN).instantiate() as Soldier
	s.setup(1)
	_check("soldier starts clean", not s.is_blinded() and not s.is_weakened())
	s.apply_blind(3.0)
	s.apply_weaken(5.0)
	_check("blind and weaken apply", s.is_blinded() and s.is_weakened())
	s.apply_weaken(1.0)
	_check("a shorter debuff never shortens a longer one", is_equal_approx(s._weak_t, 5.0))
	s.dead = true
	s.apply_blind(10.0)
	_check("dead soldiers ignore debuffs", is_equal_approx(s._blind_t, 3.0))
	s.free()


func _test_bosses() -> void:
	var expected := {
		1: K.MINI_CRUSHER, 2: K.MINI_GATLING, 3: K.MINI_BOMBER, 4: K.MINI_COMMANDER, 5: K.BOSS,
		6: K.MINI_ICEBREAKER, 7: K.MINI_BLIZZARD, 8: K.MINI_SLED, 9: K.MINI_FROST_COMMANDER, 10: K.BOSS_YETI,
		11: K.MINI_FORGE_SMASHER, 12: K.MINI_FLAMECASTER, 13: K.MINI_LAVA_MORTAR, 14: K.MINI_FOUNDRY_OVERSEER, 15: K.BOSS_DRAKE,
		16: K.MINI_GRAVEDIGGER, 17: K.MINI_COFFIN_CANNON, 18: K.MINI_PUMPKIN_BOMBER, 19: K.MINI_LICH_COMMANDER, 20: K.BOSS_BONE_REAPER,
		76: K.MINI_OBSIDIAN_CRUSHER, 77: K.MINI_ECLIPSE_GUNNER, 78: K.MINI_METEOR_BOMBER, 79: K.MINI_VOID_HERALD, 80: K.BOSS_VOID_EMPEROR,
	}
	var ok := true
	for level in expected:
		ok = ok and LevelDB.boss_kind(level) == expected[level]
	_check("boss of levels 1-20 and 76-80 as designed", ok)
	var seen := {}
	var full_ok := true
	for level in range(1, LevelDB.TOTAL_LEVELS + 1):
		var kind := LevelDB.boss_kind(level)
		seen[kind] = true
		full_ok = full_ok and EnemyDB.is_boss_kind(kind) and EnemyDB.FULL_BOSS_KINDS.has(kind) == LevelDB.is_boss_level(level)
	_check("80 levels, 80 different bosses, full boss exactly on levels 5, 10 ... 80", seen.size() == 80 and full_ok)
	_check("80 boss kinds (16 full + 64 mini), all with a scene and a config",
		EnemyDB.BOSS_KINDS.size() == 80 and EnemyDB.FULL_BOSS_KINDS.size() == 16)
	var all_ok := true
	for kind in EnemyDB.BOSS_KINDS:
		var cfg := Boss.config_of(int(kind))
		var seq: Array = cfg["sequence"]
		all_ok = all_ok and EnemyDB.DATA.has(kind) and ResourceLoader.exists(String(EnemyDB.DATA[kind]["scene"])) and not seq.is_empty()
		all_ok = all_ok and (not seq.has(Boss.Pattern.BOMBS) or int(cfg["bomb_count"]) > 0)
	_check("every boss kind has a scene, a pattern sequence and bombs when it uses them", all_ok)
	var grows := true
	for i in range(1, EnemyDB.FULL_BOSS_KINDS.size()):
		grows = grows and float(EnemyDB.DATA[EnemyDB.FULL_BOSS_KINDS[i]]["health"]) > float(EnemyDB.DATA[EnemyDB.FULL_BOSS_KINDS[i - 1]]["health"])
	_check("every round boss has more health than the one before", grows)
	var scene_ok := true
	for kind in EnemyDB.BOSS_KINDS:
		var node := EnemyDB.scene(int(kind)).instantiate() as Boss
		scene_ok = scene_ok and node != null and node.kind == int(kind) and node.get_node_or_null("Body/ModelSlot/Model") != null
		node.free()
	_check("every boss scene stores its own kind and has a model", scene_ok)

extends Node
## Headless tests for the Rare / Super Rare variants and the support units (Mortar, Weakener, Drummer,
## Blinder, Shield Knight). Run: godot --headless --path . res://Tools/test_units.tscn
## Needs the battle scene (soldiers and enemies read Game.fx etc.), so it loads Battle.tscn first.

const T := SoldierDB.Type

var _failed := 0


func _check(name: String, ok: bool) -> void:
	print("%s  %s" % ["PASS" if ok else "FAIL", name])
	if not ok:
		_failed += 1


func _ready() -> void:
	SaveManager.enabled = false
	_test_data()
	var battle: Node = load("res://Scene/Ingame/Battle.tscn").instantiate()
	add_child(battle)
	await get_tree().process_frame
	await get_tree().process_frame
	var units: Node3D = battle.get_node("Units")
	Game.state = Game.State.LOADING   # freeze soldiers / bullets; the test calls the logic itself
	await _test_taunt_and_armor(units)
	await _test_debuffs(units)
	await _test_drum()
	_test_locked_and_chests()
	print("UNITS %s" % ("OK" if _failed == 0 else "FAILED (%d)" % _failed))
	get_tree().quit(1 if _failed > 0 else 0)


func _test_data() -> void:
	_check("20 soldier types", SoldierDB.DATA.size() == 20 and SoldierDB.IDS.size() == 20)
	var ids := {}
	for t in SoldierDB.DATA:
		var d: Dictionary = SoldierDB.DATA[t]
		var scene := SoldierDB.scene(t)
		var soldier := scene.instantiate() as Soldier if scene != null else null
		var ok: bool = soldier != null and soldier.type == t
		ok = ok and ResourceLoader.exists(d["model"]) and ResourceLoader.exists(d["icon"])
		ok = ok and RankDB.has_rank(d["rank"]) and UnitClassDB.has_unit_class(d["class"])
		ok = ok and not ids.has(SoldierDB.id_of(t)) and SoldierDB.type_of(SoldierDB.id_of(t)) == t
		ids[SoldierDB.id_of(t)] = true
		if soldier != null:
			soldier.free()
		_check("%s: scene, model, icon, rank, class, save id" % d["name"], ok)
	_check("Medic Super Rare is super_rare", SoldierDB.DATA[T.MEDIC_SUPER_RARE]["rank"] == &"super_rare")
	_check("every rare variant out-stats its common unit",
		SoldierDB.DATA[T.RIFLEMAN_RARE]["damage"] > SoldierDB.DATA[T.RIFLEMAN]["damage"]
		and SoldierDB.DATA[T.SNIPER_RARE]["damage"] > SoldierDB.DATA[T.SNIPER]["damage"]
		and SoldierDB.DATA[T.MEDIC_SUPER_RARE]["heal"] > SoldierDB.DATA[T.MEDIC]["heal"])
	_check("rank scales upgrade costs (Rare x1.25 gold, x1.5 shards; Super Rare x1.5 / x2)",
		SoldierDB.upgrade_gold(1, T.RIFLEMAN) == 500 and SoldierDB.upgrade_gold(1, T.RIFLEMAN_RARE) == 625
		and SoldierDB.upgrade_shards(1, T.RIFLEMAN_RARE) == 15 and SoldierDB.upgrade_gold(1, T.MEDIC_SUPER_RARE) == 750
		and SoldierDB.upgrade_shards(1, T.MEDIC_SUPER_RARE) == 20 and SoldierDB.upgrade_gold(1) == 500)
	var kinds_ok := true
	for t in SoldierDB.DATA:
		kinds_ok = kinds_ok and int(SoldierDB.DATA[t].get("proj", int(t))) < ProjectilePool.KIND_COLOR.size()
	_check("every soldier projectile kind exists", kinds_ok)


func _test_taunt_and_armor(units: Node3D) -> void:
	var army := Game.army
	var knight := army.add_soldier(T.SHIELD_KNIGHT, 1)
	var rifle := army.add_soldier(T.RIFLEMAN, 1)
	await get_tree().process_frame
	army.position = Vector3.ZERO
	rifle.position = Vector3(0, 0, -2)
	knight.position = Vector3(3, 0, -5)
	for s in Game.soldiers:
		if s != knight and s != rifle:
			s.position = Vector3(40, 0, 40)
	var e := Enemy.spawn(units, EnemyDB.Kind.BASIC, Vector3(0, 0, -8))
	await get_tree().process_frame
	e._find_target()
	_check("enemy goes for the taunting knight, not the nearest soldier", e.target == knight)
	knight.position = Vector3(3, 0, 60)
	e._find_target()
	_check("knight out of taunt range: nearest soldier again", e.target == rifle)
	var hp0 := knight.hp
	knight.take_damage(100.0)
	_check("knight takes armor-reduced damage", is_equal_approx(hp0 - knight.hp, 100.0 * (1.0 - knight.armor)))
	_check("knight is melee and sits in the front row", knight.melee and knight.row_priority < rifle.row_priority)
	e.queue_free()
	await get_tree().process_frame


func _test_debuffs(units: Node3D) -> void:
	var e := Enemy.spawn(units, EnemyDB.Kind.BASIC, Vector3(0, 0, -300))
	await get_tree().process_frame
	_check("no debuff: x1.0, never misses", is_equal_approx(e.dmg_mult(), 1.0) and not e.miss_roll())
	e.apply_weaken(0.25, 1.0)
	e.apply_weaken(0.10, 1.0)
	_check("weaken: strongest effect wins (-25%)", is_equal_approx(e.dmg_mult(), 0.75))
	e.apply_blind(1.0, 1.0)
	_check("blind with 100% chance always misses", e.miss_roll())
	e._weak_t = 0.0
	e._blind_t = 0.0
	_check("debuffs expire", is_equal_approx(e.dmg_mult(), 1.0) and not e.miss_roll())
	e.debuff_immune = true
	e.apply_weaken(0.5, 1.0)
	e.apply_blind(1.0, 1.0)
	_check("immune enemies (bosses) ignore debuffs", is_equal_approx(e.dmg_mult(), 1.0) and not e.miss_roll())
	e.queue_free()
	await get_tree().process_frame


func _test_drum() -> void:
	var s := Game.army.add_soldier(T.RIFLEMAN, 1)
	await get_tree().process_frame
	_check("no drum buff: x1.0", is_equal_approx(s._drum_dmg_mult(), 1.0) and is_equal_approx(s._drum_rate_mult(), 1.0))
	s.apply_drum(0.12, 0.15, 1.0)
	s.apply_drum(0.20, 0.10, 1.0)
	_check("drum buff: best value of each stat wins", is_equal_approx(s._drum_dmg_mult(), 1.2) and is_equal_approx(s._drum_rate_mult(), 1.15))
	var drummer := Game.army.add_soldier(T.DRUMMER_RARE, 1)
	_check("drummer carries an aura", drummer.aura_range > 0.0 and drummer.buff_dmg > 0.0 and drummer.buff_rate > 0.0)
	var mortar := Game.army.add_soldier(T.MORTAR, 1)
	_check("mortar lobs shells and picks crowds", mortar.lob and mortar.prefer == &"cluster" and mortar.aoe > 0.0)
	var weakener := Game.army.add_soldier(T.WEAKENER, 1)
	var blinder := Game.army.add_soldier(T.BLINDER, 1)
	_check("weakener and blinder carry their aura", weakener.weaken_frac > 0.0 and blinder.blind_chance > 0.0)


func _test_locked_and_chests() -> void:
	PlayerData.reset_to_defaults()
	PlayerData.gold = 100000
	PlayerData.shards[T.MORTAR] = 1000
	_check("new units start locked", not PlayerData.owns(T.MORTAR) and not PlayerData.owns(T.SHIELD_KNIGHT_RARE))
	_check("a locked unit cannot be upgraded", not PlayerData.can_upgrade(T.MORTAR) and not PlayerData.try_upgrade(T.MORTAR))
	PlayerData.unlock(T.MORTAR)
	_check("an unlocked unit can be upgraded", PlayerData.try_upgrade(T.MORTAR) and PlayerData.level_of(T.MORTAR) == 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var common := 0
	var super_rare := 0
	for i in 4000:
		for u: Dictionary in ChestDB.roll(ChestDB.Tier.WOOD, rng)["units"]:
			var rank: StringName = SoldierDB.DATA[u["type"]]["rank"]
			if rank == &"common":
				common += 1
			elif rank == &"super_rare":
				super_rare += 1
	_check("chests drop common units more often than super rare ones (%d vs %d)" % [common, super_rare], common > super_rare * 3)
	PlayerData.reset_to_defaults()

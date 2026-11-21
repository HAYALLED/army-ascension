extends Node
## Headless enemy tests. Run: godot --headless --path . res://Tools/test_enemies.tscn
## Needs the battle scene (enemies read Game.fx etc.), so it loads Battle.tscn first.

var _failed := 0


func _check(name: String, ok: bool) -> void:
	print("%s  %s" % ["PASS" if ok else "FAIL", name])
	if not ok:
		_failed += 1


func _ready() -> void:
	SaveManager.enabled = false
	var battle: Node = load("res://Scene/Ingame/Battle.tscn").instantiate()
	add_child(battle)
	await get_tree().process_frame
	await get_tree().process_frame
	var units: Node3D = battle.get_node("Units")
	var base := Game.enemies.size()

	# every kind spawns from its scene with the right data
	for kind in EnemyDB.DATA:
		if kind == EnemyDB.Kind.BOSS:
			continue
		var e := Enemy.spawn(units, kind, Vector3(0, 0, -30))
		await get_tree().process_frame
		_check("spawn %s" % EnemyDB.DATA[kind]["name"], e.kind == kind and e.max_hp > 0.0 and e.get_script() != null)
		e.queue_free()
	await get_tree().process_frame

	# summon wave: 8..20 enemies, every time
	var ok := true
	var kinds := {}
	for i in 12:
		var before := Game.enemies.size()
		var n := Enemy.spawn_minions(units, Vector3(0, 0, -300))
		await get_tree().process_frame
		ok = ok and n >= Enemy.MINION_MIN and n <= Enemy.MINION_MAX and Game.enemies.size() == before + n
		for e in Game.enemies:
			kinds[e.kind] = true
		for e in Game.enemies.duplicate():
			if e.position.z < -250 and not (e is Boss):
				e.queue_free()
		await get_tree().process_frame
	_check("summon count always 8..20", ok)
	_check("summon uses many kinds", kinds.size() >= 6)

	# cap
	for i in Enemy.MAX_ALIVE:
		Enemy.spawn(units, EnemyDB.Kind.BASIC, Vector3(0, 0, -400))
	_check("summon blocked at MAX_ALIVE", Enemy.spawn_minions(units, Vector3(0, 0, -300)) == 0)

	# kamikaze blast hurts soldiers, no reward
	for e in Game.enemies.duplicate():
		if not (e is Boss):
			e.queue_free()
	await get_tree().process_frame
	var s: Soldier = Game.soldiers[0]
	var hp0 := s.hp
	var gold0 := Game.gold
	Game.state = Game.State.LOADING   # freeze soldiers / bullets; the test drives _think itself
	var k := Enemy.spawn(units, EnemyDB.Kind.KAMIKAZE, s.position + Vector3(0.5, 0, 0)) as Kamikaze
	await get_tree().process_frame
	k.target = s
	k._retarget_t = 99.0
	for i in 60:
		if is_instance_valid(k):
			k._think(0.016)
	await get_tree().process_frame
	_check("kamikaze explodes and damages soldiers", s.hp < hp0 or s.dead)
	_check("kamikaze gives no reward", Game.gold == gold0 and not is_instance_valid(k))

	# medic heals a wounded enemy, never the boss
	var g := Enemy.spawn(units, EnemyDB.Kind.ARMORED, Vector3(0, 0, -200))
	var m := Enemy.spawn(units, EnemyDB.Kind.MEDIC, Vector3(2, 0, -200)) as MedicEnemy
	await get_tree().process_frame
	g.hp = g.max_hp * 0.5
	var before_hp := g.hp
	m._heal_pulse()
	_check("medic heals wounded ally by 15%", is_equal_approx(g.hp, before_hp + g.max_hp * 0.15))
	var boss: Boss = battle.boss
	boss.position = Vector3(1, 0, -200)
	boss.hp = boss.max_hp * 0.5
	m._heal_pulse()
	_check("medic never heals boss", is_equal_approx(boss.hp, boss.max_hp * 0.5))

	# level rule
	_check("boss levels are 5, 10", LevelDB.is_boss_level(5) and LevelDB.is_boss_level(10) and not LevelDB.is_boss_level(1) and not LevelDB.is_boss_level(4) and not LevelDB.is_boss_level(0))

	get_tree().quit(0 if _failed == 0 else 1)

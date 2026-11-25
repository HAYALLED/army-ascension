extends Node
## Headless "Prepare your army" tests. Run: godot --headless --path . res://Tools/test_formation.tscn

const T := SoldierDB.Type

var _failed := 0


func _check(name: String, ok: bool) -> void:
	print("%s  %s" % ["PASS" if ok else "FAIL", name])
	if not ok:
		_failed += 1


func _ready() -> void:
	SaveManager.enabled = false
	_test_rules()
	_test_save()
	await _test_battle_army()
	print("FORMATION %s" % ("OK" if _failed == 0 else "FAILED (%d)" % _failed))
	get_tree().quit(1 if _failed > 0 else 0)


func _test_rules() -> void:
	PlayerData.reset_to_defaults()
	_check("default army = 5 starter units", PlayerData.equipped.size() == 5 and PlayerData.is_equipped(T.RIFLEMAN) and PlayerData.is_equipped(T.MEDIC))
	_check("cannot equip a 6th unit", not PlayerData.equip(T.SNIPER_RARE) and PlayerData.equipped.size() == 5)
	_check("cannot equip an unowned unit", PlayerData.unequip(T.MEDIC) and not PlayerData.equip(T.MEDIC_SUPER_RARE))
	PlayerData.unlock(T.MEDIC_SUPER_RARE)
	_check("owned unit can be equipped; rare and common are separate units", PlayerData.equip(T.MEDIC_SUPER_RARE) and not PlayerData.is_equipped(T.MEDIC))
	_check("cannot equip the same unit twice", not PlayerData.equip(T.MEDIC_SUPER_RARE))
	for t in [T.MACHINE_GUNNER, T.SNIPER, T.ROCKET, T.MEDIC_SUPER_RARE]:
		PlayerData.unequip(t)
	_check("last unit cannot be removed (min 1)", PlayerData.equipped == [T.RIFLEMAN] and not PlayerData.unequip(T.RIFLEMAN))


func _test_save() -> void:
	PlayerData.reset_to_defaults()
	PlayerData.unequip(T.ROCKET)
	PlayerData.unequip(T.MEDIC)
	var saved := PlayerData.to_save()
	PlayerData.reset_to_defaults()
	PlayerData.apply_save(saved)
	_check("3 equipped units survive save + load in order", PlayerData.equipped == [T.RIFLEMAN, T.MACHINE_GUNNER, T.SNIPER])
	var old := saved.duplicate(true)
	old.erase("equipped")
	PlayerData.apply_save(old)
	_check("old save without the key = default army", PlayerData.equipped.size() == 5)
	var bad := saved.duplicate(true)
	bad["equipped"] = ["sniper", "sniper", "nope", 7, "mortar", "rifleman", "medic", "rocket", "machine_gunner"]
	PlayerData.apply_save(bad)
	_check("bad data: duplicates, unknown, unowned dropped, capped at 5", PlayerData.equipped == [T.SNIPER, T.RIFLEMAN, T.MEDIC, T.ROCKET, T.MACHINE_GUNNER])
	bad["equipped"] = ["nope", "mortar"]
	PlayerData.apply_save(bad)
	_check("bad data: nothing valid = default army", PlayerData.equipped.size() == 5)


## Battle start army: same size for any team, split evenly over the equipped units.
func _test_battle_army() -> void:
	var team_sizes := {1: 12, 4: 12, 5: 12}
	for n in team_sizes:
		PlayerData.reset_to_defaults()
		while PlayerData.equipped.size() > n:
			PlayerData.unequip(PlayerData.equipped.back())
		var battle := (load("res://Scene/Ingame/Battle.tscn") as PackedScene).instantiate()
		add_child(battle)
		await get_tree().process_frame
		var counts := {}
		for s in Game.soldiers:
			counts[s.type] = int(counts.get(s.type, 0)) + 1
		var even := counts.size() == n
		for t in counts:
			even = even and absi(int(counts[t]) - roundi(float(team_sizes[n]) / n)) <= 1 and PlayerData.is_equipped(t)
		_check("%d equipped -> %d soldiers, split evenly, equipped units only" % [n, team_sizes[n]], Game.soldiers.size() == team_sizes[n] and even)
		battle.queue_free()
		await get_tree().process_frame

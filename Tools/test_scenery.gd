extends Node
## Headless tests for the themed scenery and the per-battle day phase.
## Run: godot --headless --path . res://Tools/test_scenery.tscn

const LEVEL := preload("res://Scene/Ingame/Levels/Level01.tscn")

var _failed := 0


func _check(name: String, ok: bool) -> void:
	print("%s  %s" % ["PASS" if ok else "FAIL", name])
	if not ok:
		_failed += 1


func _ready() -> void:
	SaveManager.enabled = false
	_test_scenery()
	_test_day_phase()
	print("SCENERY %s" % ("OK" if _failed == 0 else "FAILED (%d)" % _failed))
	get_tree().quit(1 if _failed > 0 else 0)


## Builds the level scene for `level_index`; returns {"scenery": Node or null, "sig": String, "min_x": float, "count": int}.
func _build(level_index: int) -> Dictionary:
	Game.level_index = level_index
	var lv: Node3D = LEVEL.instantiate()
	add_child(lv)
	var scenery := lv.get_node_or_null("Scenery")
	var sig := PackedStringArray()
	var min_x := 999.0
	var count := 0
	if scenery != null:
		# child 0 is the verge strip (its origin is the lane centre), the rest are props
		for i in range(1, scenery.get_child_count()):
			var mm := (scenery.get_child(i) as MultiMeshInstance3D).multimesh
			for k in mm.instance_count:
				var o := mm.get_instance_transform(k).origin
				min_x = minf(min_x, absf(o.x))
				sig.append("%.1f,%.1f" % [o.x, o.z])
				count += 1
	lv.free()
	return {"scenery": scenery != null, "sig": ",".join(sig), "min_x": min_x, "count": count}


func _test_scenery() -> void:
	for lv in [1, 6, 11]:
		var r := _build(lv)
		_check("level %d: scenery built (%d props)" % [lv, r["count"]], r["scenery"] and r["count"] > 50)
		_check("level %d: props stay out of the lane (min |x| %.1f)" % [lv, r["min_x"]], r["min_x"] >= 8.0)
	_check("level 16: no env art yet, no scenery", not _build(16)["scenery"])
	var a := _build(6)
	var b := _build(6)
	_check("level 6: scenery differs between plays", a["sig"] != b["sig"])


func _test_day_phase() -> void:
	PlayerData.reset_to_defaults()
	var seen: Array[int] = []
	for i in 4:
		seen.append(PlayerData.battle_day_phase())
		PlayerData.advance_day_phase()
	_check("day phase loops morning, evening, night, morning", str(seen) == "[0, 1, 2, 0]")
	PlayerData.set_setting("day_cycle", false)
	PlayerData.advance_day_phase()
	_check("day cycle off: always morning, counter frozen", PlayerData.battle_day_phase() == 0 and PlayerData.day_phase == 1)
	PlayerData.set_setting("day_cycle", true)
	var saved := PlayerData.to_save()
	PlayerData.reset_to_defaults()
	PlayerData.apply_save(saved)
	_check("day phase survives a save round trip", PlayerData.day_phase == 1 and PlayerData.settings["day_cycle"] == true)
	PlayerData.apply_save({"day_phase": 99})
	_check("invalid saved day phase is clamped", PlayerData.day_phase == 2)
	PlayerData.reset_to_defaults()

# path: Scripts/data/UnitClassDB.gd
extends Node
## Autoload "UnitClassDB" (not "ClassDB": that name is a built-in Godot singleton).

signal reloaded

const CLASS_DIR := "res://Resources/classes/"
const FALLBACK_ID := &"unique"

var _by_id: Dictionary = {}
var _sorted: Array[UnitClassData] = []
var _fallback: UnitClassData
var _warned_ids: Dictionary = {}


func _init() -> void:
	reload()


func reload() -> void:
	_by_id.clear()
	_sorted.clear()
	_warned_ids.clear()
	for path in DataFolder.list_resource_paths(CLASS_DIR):
		var unit_class := load(path) as UnitClassData
		if unit_class == null:
			push_warning("UnitClassDB: %s is not a UnitClassData, skipped." % path)
			continue
		if not unit_class.is_valid():
			push_warning("UnitClassDB: %s has empty id, skipped." % path)
			continue
		if _by_id.has(unit_class.id):
			push_warning("UnitClassDB: duplicate id '%s' in %s, skipped." % [unit_class.id, path])
			continue
		_by_id[unit_class.id] = unit_class
		_sorted.append(unit_class)
	_sorted.sort_custom(_compare_class)
	_fallback = _pick_fallback()
	reloaded.emit()


func has_unit_class(id: StringName) -> bool:
	return _by_id.has(id)


## Never returns null. Unknown id -> fallback class (warns once per id).
func get_unit_class(id: StringName) -> UnitClassData:
	var unit_class := _by_id.get(id) as UnitClassData
	if unit_class != null:
		return unit_class
	if not _warned_ids.has(id):
		_warned_ids[id] = true
		push_warning("UnitClassDB: unknown class id '%s', using '%s'." % [id, _fallback.id])
	return _fallback


func get_sorted() -> Array[UnitClassData]:
	var out: Array[UnitClassData] = []
	out.assign(_sorted)
	return out


func get_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for unit_class in _sorted:
		out.append(unit_class.id)
	return out


func _compare_class(a: UnitClassData, b: UnitClassData) -> bool:
	if a.sort_order != b.sort_order:
		return a.sort_order < b.sort_order
	return String(a.id) < String(b.id)


func _pick_fallback() -> UnitClassData:
	var found := _by_id.get(FALLBACK_ID) as UnitClassData
	if found != null:
		return found
	if not _sorted.is_empty():
		return _sorted[0]
	push_error("UnitClassDB: no classes found in %s. Using built-in emergency class." % CLASS_DIR)
	var emergency := UnitClassData.new()
	emergency.id = FALLBACK_ID
	emergency.display_name = "Unique"
	return emergency

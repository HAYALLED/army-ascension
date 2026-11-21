# path: Scripts/data/RankDB.gd
extends Node
## Autoload "RankDB". Loads every RankData .tres from RANK_DIR. No class_name on purpose.

signal reloaded
signal fire_animation_changed(enabled: bool)

const RANK_DIR := "res://Resources/ranks/"
const FALLBACK_ID := &"common"

## Low-graphics option: set false to stop fire animation on all cards.
var fire_animation_enabled: bool = true:
	set = set_fire_animation_enabled

var _by_id: Dictionary = {}
var _sorted: Array[RankData] = []
var _fallback: RankData
var _warned_ids: Dictionary = {}


func _init() -> void:
	reload()


func reload() -> void:
	_by_id.clear()
	_sorted.clear()
	_warned_ids.clear()
	for path in DataFolder.list_resource_paths(RANK_DIR):
		var rank := load(path) as RankData
		if rank == null:
			push_warning("RankDB: %s is not a RankData, skipped." % path)
			continue
		if not rank.is_valid():
			push_warning("RankDB: %s has empty id, skipped." % path)
			continue
		if _by_id.has(rank.id):
			push_warning("RankDB: duplicate id '%s' in %s, skipped." % [rank.id, path])
			continue
		_by_id[rank.id] = rank
		_sorted.append(rank)
	_sorted.sort_custom(_compare_rank)
	_fallback = _pick_fallback()
	reloaded.emit()


func has_rank(id: StringName) -> bool:
	return _by_id.has(id)


## Never returns null. Unknown id -> fallback rank (warns once per id).
func get_rank(id: StringName) -> RankData:
	var rank := _by_id.get(id) as RankData
	if rank != null:
		return rank
	if not _warned_ids.has(id):
		_warned_ids[id] = true
		push_warning("RankDB: unknown rank id '%s', using '%s'." % [id, _fallback.id])
	return _fallback


func get_sorted(descending: bool = false) -> Array[RankData]:
	var out: Array[RankData] = []
	out.assign(_sorted)
	if descending:
		out.reverse()
	return out


func get_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for rank in _sorted:
		out.append(rank.id)
	return out


## Order value of a rank id (unknown id -> fallback's order).
func get_order(id: StringName) -> int:
	return get_rank(id).order


func set_fire_animation_enabled(enabled: bool) -> void:
	if fire_animation_enabled == enabled:
		return
	fire_animation_enabled = enabled
	fire_animation_changed.emit(enabled)


func _compare_rank(a: RankData, b: RankData) -> bool:
	if a.order != b.order:
		return a.order < b.order
	return String(a.id) < String(b.id)


func _pick_fallback() -> RankData:
	var found := _by_id.get(FALLBACK_ID) as RankData
	if found != null:
		return found
	if not _sorted.is_empty():
		return _sorted[0]
	push_error("RankDB: no ranks found in %s. Using built-in emergency rank." % RANK_DIR)
	var emergency := RankData.new()
	emergency.id = FALLBACK_ID
	emergency.display_name = "Common"
	return emergency

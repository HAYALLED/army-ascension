extends Node
## Player profile (autoload "PlayerData"): wallet, soldier levels, class shards.
## In-memory for now; saving comes with the save phase.
## Every transaction is validated: balances never go negative.

signal wallet_changed()
signal soldier_changed(type: int)

## Dev starting wallet so the upgrade menu can be tried right away.
const START_GOLD := 600
const START_SHARDS := 12
const START_GEMS := 0

var gold: int = START_GOLD
var gems: int = START_GEMS
var levels: Dictionary = {}   # SoldierDB.Type -> level
var shards: Dictionary = {}   # SoldierDB.Type -> shard count
## Player settings (sound / music live in AudioManager).
var settings: Dictionary = {"vibration": true, "graphics_high": true}


func _ready() -> void:
	for t in SoldierDB.DATA:
		levels[t] = 1
		shards[t] = 0
	shards[SoldierDB.Type.RIFLEMAN] = START_SHARDS


func level_of(type: int) -> int:
	return int(levels.get(type, 1))


func shards_of(type: int) -> int:
	return int(shards.get(type, 0))


func total_shards() -> int:
	var n := 0
	for t in shards:
		n += int(shards[t])
	return n


func add_gold(amount: int) -> void:
	if amount <= 0:
		return
	gold += amount
	wallet_changed.emit()


func add_shards(type: int, amount: int) -> void:
	if amount <= 0 or not shards.has(type):
		return
	shards[type] += amount
	wallet_changed.emit()
	soldier_changed.emit(type)


func can_upgrade(type: int) -> bool:
	var lv := level_of(type)
	return lv < SoldierDB.MAX_LEVEL \
		and gold >= SoldierDB.upgrade_gold(lv) \
		and shards_of(type) >= SoldierDB.upgrade_shards(lv)


## Spends gold + class shards and raises the level. Returns false (and
## changes nothing) when the player cannot afford it.
func try_upgrade(type: int) -> bool:
	if not can_upgrade(type):
		return false
	var lv := level_of(type)
	gold -= SoldierDB.upgrade_gold(lv)
	shards[type] -= SoldierDB.upgrade_shards(lv)
	levels[type] = lv + 1
	wallet_changed.emit()
	soldier_changed.emit(type)
	return true

# path: scripts/data/RarityMigration.gd
class_name RarityMigration
extends RefCounted
## Converts old rarity values (Common/Rare/Epic/Legendary) to new rank ids.

const LEGACY_NAMES := {
	"common": &"common",
	"rare": &"rare",
	"epic": &"super_rare",
	"legendary": &"legend",
}
## Old enum order: COMMON, RARE, EPIC, LEGENDARY.
const LEGACY_INDEX: Array[StringName] = [&"common", &"rare", &"super_rare", &"legend"]


## Accepts old int index, old name (any case) or an already-new id. Unknown -> "common".
static func to_rank_id(legacy: Variant) -> StringName:
	match typeof(legacy):
		TYPE_INT, TYPE_FLOAT:
			var index := int(legacy)
			if index >= 0 and index < LEGACY_INDEX.size():
				return LEGACY_INDEX[index]
		TYPE_STRING, TYPE_STRING_NAME:
			var key := String(legacy).strip_edges().to_lower()
			if LEGACY_NAMES.has(key):
				return StringName(LEGACY_NAMES[key])
			if not key.is_empty():
				return StringName(key)
	return &"common"

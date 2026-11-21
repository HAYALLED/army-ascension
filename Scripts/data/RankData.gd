# path: scripts/data/RankData.gd
class_name RankData
extends Resource
## One card rank (Common, Rare, ...). Data only. Add a new rank = add a .tres in res://resources/ranks/.

@export var id: StringName = &""
@export var display_name: String = ""
## Lower = weaker. Defines sort order and progression of ranks.
@export var order: int = 0
## Main card color (also used for fallback frame fill).
@export var color: Color = Color.WHITE
## Accent color: borders, glow, selection outline.
@export var glow_color: Color = Color.WHITE
@export var frame_texture: Texture2D
@export var gem_texture: Texture2D
@export var has_fire: bool = false
## Static fire overlay (used if no sheet is set).
@export var fire_overlay: Texture2D
## Horizontal sprite sheet, frames laid out left to right.
@export var fire_sheet: Texture2D
@export_range(1, 64) var fire_sheet_frames: int = 6
@export_range(1.0, 60.0) var fire_fps: float = 10.0
## Economy hooks. Base costs live in the economy config; these only scale them.
@export_range(0.1, 100.0, 0.01) var shards_to_unlock_mult: float = 1.0
@export_range(0.1, 100.0, 0.01) var upgrade_cost_mult: float = 1.0


func is_valid() -> bool:
	return id != &""


## Dark text on light color, light text on dark color.
func get_contrast_color() -> Color:
	return Color(0.08, 0.08, 0.1) if color.get_luminance() > 0.45 else Color.WHITE


func scale_unlock_shards(base_shards: int) -> int:
	return maxi(1, roundi(base_shards * shards_to_unlock_mult))


func scale_upgrade_cost(base_cost: int) -> int:
	return maxi(0, roundi(base_cost * upgrade_cost_mult))

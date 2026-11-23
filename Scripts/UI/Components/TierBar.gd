class_name TierBar
extends Control
## Progress bar of an army upgrade (see GlobalUpgradeDB). It shows the progress inside the current
## tier of TIER_SIZE levels. After every full tier the bar changes color: the finished tier stays as
## the (dimmed) background and the new color fills over it again, so progress never "ends".
## set_level() animates the fill when the level goes up, including across a tier change.

const BG_COLOR := Color(0.08, 0.09, 0.14)
const TICK_COLOR := Color(0.0, 0.0, 0.0, 0.35)

var _level: int = 0
var _shown: float = 0.0
var _tween: Tween = null
var _style := StyleBoxFlat.new()


func _ready() -> void:
	custom_minimum_size.y = maxf(custom_minimum_size.y, 28.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Shows `level`. With `animate` and a higher level than before, the bar fills smoothly.
func set_level(level: int, animate: bool) -> void:
	var old := _level
	_level = maxi(level, 0)
	if _tween != null:
		_tween.kill()
		_tween = null
	if not animate or _level <= old or not is_inside_tree():
		_shown = float(_level)
		queue_redraw()
		return
	_shown = float(old)
	_tween = create_tween()
	_tween.tween_method(_set_shown, float(old), float(_level), 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


## Color of the tier the bar is in right now.
func current_color() -> Color:
	return GlobalUpgradeDB.tier_color(GlobalUpgradeDB.tier_of(float(_level)))


func _set_shown(value: float) -> void:
	_shown = value
	queue_redraw()


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	var radius := int(size.y * 0.5)
	_style.set_corner_radius_all(radius)
	_style.bg_color = BG_COLOR
	draw_style_box(_style, rect)
	var tier := GlobalUpgradeDB.tier_of(_shown)
	var fraction := GlobalUpgradeDB.tier_progress(_shown)
	if tier > 0:
		_style.bg_color = GlobalUpgradeDB.tier_color(tier - 1).darkened(0.35)
		draw_style_box(_style, rect)
	var width := size.x * fraction
	if width > 0.5:
		_style.bg_color = GlobalUpgradeDB.tier_color(tier)
		draw_style_box(_style, Rect2(0.0, 0.0, maxf(width, size.y * 0.6), size.y))
		draw_rect(Rect2(radius * 0.6, size.y * 0.16, maxf(width - radius * 1.2, 0.0), size.y * 0.18), Color(1, 1, 1, 0.22))
	for i in range(1, GlobalUpgradeDB.TIER_SIZE):
		var x := size.x * float(i) / float(GlobalUpgradeDB.TIER_SIZE)
		draw_line(Vector2(x, size.y * 0.2), Vector2(x, size.y * 0.8), TICK_COLOR, 2.0)
	var font := get_theme_default_font()
	var text := "%d/%d" % [_level % GlobalUpgradeDB.TIER_SIZE, GlobalUpgradeDB.TIER_SIZE]
	var font_size := int(size.y * 0.58)
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	var pos := Vector2((size.x - text_size.x) * 0.5, (size.y + text_size.y * 0.62) * 0.5)
	draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, 5, Color(0, 0, 0, 0.8))
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color.WHITE)

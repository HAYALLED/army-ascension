class_name TutorialIcon
extends Control
## A tutorial picture. Draws `texture_path` when that file exists, otherwise a flat, text-free
## placeholder for its `kind`, so every tutorial screen works before the final art is imported.
## Kinds: ring (9-slice, stretches around any rectangle), hand_drag, hand_tap, arrow, portrait, slide, ribbon.

const NAVY := Color(0.106, 0.137, 0.251)
const YELLOW := Color(1.0, 0.85, 0.2)

@export var kind: StringName = &"ring"
@export var texture_path: String = ""
## Placeholder fill (portrait, slide).
@export var color: Color = Color(1.0, 0.85, 0.2)

var _tex: Texture2D = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_load()


## Switches the picture (null/"" = placeholder only).
func set_texture_path(path: String) -> void:
	texture_path = path
	_load()


func has_art() -> bool:
	return _tex != null


func _load() -> void:
	_tex = null
	if texture_path != "" and ResourceLoader.exists(texture_path):
		_tex = load(texture_path) as Texture2D
	queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	if _tex != null:
		if kind == &"ring":
			draw_style_box(_ring_style(r), r)
		else:
			draw_texture_rect(_tex, _fit(r, _tex.get_size()), false)
		return
	match kind:
		&"ring":
			_draw_ring(r)
		&"hand_drag":
			_draw_hand(r, true)
		&"hand_tap":
			_draw_hand(r, false)
		&"arrow":
			_draw_arrow(r)
		&"portrait":
			_draw_portrait(r)
		&"ribbon":
			draw_style_box(_box(Color(0.22, 0.45, 0.85), 18, 6), r.grow_individual(-r.size.x * 0.06, -r.size.y * 0.12, -r.size.x * 0.06, -r.size.y * 0.12))
		_:
			_draw_slide(r)


## highlight_ring.png as a 9-slice: the frame keeps its thickness on a wide or tall rectangle.
func _ring_style(r: Rect2) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = _tex
	sb.draw_center = false
	sb.set_texture_margin_all(minf(72.0, minf(r.size.x, r.size.y) * 0.4))
	return sb


## Largest rect of the texture's aspect that fits in `r`, centered.
func _fit(r: Rect2, tex_size: Vector2) -> Rect2:
	var k := minf(r.size.x / tex_size.x, r.size.y / tex_size.y)
	var s := tex_size * k
	return Rect2(r.position + (r.size - s) * 0.5, s)


func _box(fill: Color, radius: int, border: int = 0, border_color: Color = NAVY, draw_fill: bool = true) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.draw_center = draw_fill
	sb.set_corner_radius_all(radius)
	sb.set_border_width_all(border)
	sb.border_color = border_color
	sb.anti_aliasing = true
	return sb


func _draw_ring(r: Rect2) -> void:
	draw_style_box(_box(Color.TRANSPARENT, 28, 14, NAVY, false), r)
	draw_style_box(_box(Color.TRANSPARENT, 24, 8, Color.WHITE, false), r.grow(-3.0))


func _draw_hand(r: Rect2, drag: bool) -> void:
	var c := r.get_center()
	var u := minf(r.size.x, r.size.y)
	draw_style_box(_box(Color.WHITE, int(u * 0.2), 6), Rect2(c - Vector2(u * 0.17, u * 0.2), Vector2(u * 0.34, u * 0.46)))
	draw_style_box(_box(Color.WHITE, int(u * 0.08), 6), Rect2(c + Vector2(-u * 0.05, -u * 0.38), Vector2(u * 0.1, u * 0.3)))
	if drag:
		for s in [-1.0, 1.0]:
			var tip := c + Vector2(s * u * 0.46, -u * 0.05)
			var base := c + Vector2(s * u * 0.3, -u * 0.05)
			draw_colored_polygon(PackedVector2Array([tip, base + Vector2(0, -u * 0.12), base + Vector2(0, u * 0.12)]), YELLOW)
	else:
		for i in 3:
			draw_arc(c + Vector2(0, -u * 0.38), u * (0.08 + 0.07 * i), PI * 1.1, PI * 1.9, 12, YELLOW, 5.0, true)


func _draw_arrow(r: Rect2) -> void:
	var w := r.size.x
	var h := r.size.y
	var pts := PackedVector2Array([
		Vector2(w * 0.35, 0.0), Vector2(w * 0.65, 0.0), Vector2(w * 0.65, h * 0.5),
		Vector2(w, h * 0.5), Vector2(w * 0.5, h), Vector2(0.0, h * 0.5), Vector2(w * 0.35, h * 0.5)])
	draw_colored_polygon(pts, Color.WHITE)
	var outline := pts.duplicate()
	outline.append(pts[0])
	draw_polyline(outline, NAVY, 6.0, true)


func _draw_portrait(r: Rect2) -> void:
	draw_style_box(_box(color, int(r.size.x * 0.18), 6), r)
	var u := r.size.x
	draw_style_box(_box(Color(0.35, 0.45, 0.30), int(u * 0.1), 0), Rect2(r.position + Vector2(u * 0.18, u * 0.14), Vector2(u * 0.64, u * 0.26)))
	draw_style_box(_box(Color(0.95, 0.78, 0.6), int(u * 0.1), 0), Rect2(r.position + Vector2(u * 0.24, u * 0.36), Vector2(u * 0.52, u * 0.4)))


func _draw_slide(r: Rect2) -> void:
	draw_style_box(_box(color, 36, 8), r)
	var u := minf(r.size.x, r.size.y)
	var c := r.get_center()
	draw_circle(c + Vector2(-u * 0.25, -u * 0.12), u * 0.16, Color(1, 1, 1, 0.85))
	draw_style_box(_box(Color(1, 1, 1, 0.85), 18, 0), Rect2(c + Vector2(-u * 0.02, -u * 0.26), Vector2(u * 0.5, u * 0.3)))
	draw_style_box(_box(Color(1, 1, 1, 0.55), 14, 0), Rect2(c + Vector2(-u * 0.4, u * 0.16), Vector2(u * 0.8, u * 0.12)))

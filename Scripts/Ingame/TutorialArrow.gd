class_name TutorialArrow
extends Sprite3D
## Bobbing 3D arrow that points down at a spot in the world (gate panel, spike gap).
## Uses Assets/UI/Tutorial/arrow_pointer.png when it exists, else a generated white arrow.

const SIZE := Vector2i(128, 192)

static var _fallback: Texture2D = null

var _tween: Tween = null


## Creates an arrow whose tip points at `pos`, tinted `tint` (the png is white, so it can be tinted yellow or red).
static func make(parent: Node3D, pos: Vector3, tint: Color = Color(1.0, 0.88, 0.25)) -> TutorialArrow:
	var a := TutorialArrow.new()
	a.position = pos
	a.modulate = tint
	parent.add_child(a)
	return a


func _ready() -> void:
	texture = _texture()
	pixel_size = 0.0075
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	no_depth_test = true
	shaded = false
	render_priority = 20
	offset = Vector2(0, SIZE.y * 0.5)
	_tween = create_tween().set_loops()
	_tween.tween_property(self, "position:y", position.y + 0.6, 0.45).set_trans(Tween.TRANS_SINE)
	_tween.tween_property(self, "position:y", position.y, 0.45).set_trans(Tween.TRANS_SINE)


func _exit_tree() -> void:
	if _tween != null:
		_tween.kill()


static func _texture() -> Texture2D:
	if ResourceLoader.exists(TutorialDB.ARROW_TEXTURE):
		var t := load(TutorialDB.ARROW_TEXTURE) as Texture2D
		if t != null:
			return t
	if _fallback == null:
		_fallback = _make_fallback()
	return _fallback


## White down arrow with a dark outline, drawn pixel by pixel once.
static func _make_fallback() -> Texture2D:
	var w := SIZE.x
	var h := SIZE.y
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var navy := Color(0.106, 0.137, 0.251)
	for y in h:
		for x in w:
			var inner := _inside(x, y, w, h, 0.0)
			if inner:
				img.set_pixel(x, y, Color.WHITE)
			elif _inside(x, y, w, h, 6.0):
				img.set_pixel(x, y, navy)
	return ImageTexture.create_from_image(img)


## True when (x, y) is inside the arrow grown by `grow` pixels (shaft on top, head below).
static func _inside(x: int, y: int, w: int, h: int, grow: float) -> bool:
	var shaft_l := w * 0.35 - grow
	var shaft_r := w * 0.65 + grow
	if y <= h * 0.5 and x >= shaft_l and x <= shaft_r and y >= 6.0 - grow:
		return true
	var head_top := h * 0.5 - grow
	if y < head_top or y > h - 6.0 + grow:
		return false
	var t := (float(y) - head_top) / maxf(h - 6.0 - head_top + grow, 1.0)
	var half := (w * 0.5 + grow) * (1.0 - t)
	return absf(float(x) - w * 0.5) <= half

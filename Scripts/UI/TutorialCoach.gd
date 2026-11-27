class_name TutorialCoach
extends Control
## Home screen coach marks (scene: Scene/UI/TutorialCoach.tscn, added by MainMenu.start_coach).
## Dims the screen with a hole around one target (or a group of targets) at a time, rings it and shows a
## guide bubble with NEXT / SKIP. The root blocks every touch, so nothing underneath can be pressed.
## Targets come from TutorialDB.COACH ("home:Name" = unique name inside HomePage, "menu:Name" = in MainMenu);
## a target that is missing or hidden is skipped.

signal finished()

const PAD := 14.0
const BUBBLE_MARGIN := 28.0
const SCREEN_MARGIN := 20.0

@onready var _dim_top: ColorRect = %DimTop
@onready var _dim_bottom: ColorRect = %DimBottom
@onready var _dim_left: ColorRect = %DimLeft
@onready var _dim_right: ColorRect = %DimRight
@onready var _ring: TutorialIcon = %Ring
@onready var _bubble: PanelContainer = %Bubble
@onready var _message: Label = %Message
@onready var _next: Button = %NextButton
@onready var _skip: Button = %SkipButton

var _menu: Control = null
var _steps: Array[Dictionary] = []
var _i: int = 0


func _ready() -> void:
	_next.pressed.connect(_on_next)
	_skip.pressed.connect(_finish)
	_skip.text = TutorialDB.SKIP_TEXT
	TutorialDB.style_card(_bubble, _message)


## Collects the targets that exist (after one frame, so the page is laid out) and shows the first mark.
func start(menu: Control) -> void:
	_menu = menu
	await get_tree().process_frame
	for entry: Dictionary in TutorialDB.COACH:
		var found: Array[Control] = []
		for path in entry["targets"]:
			var c := _resolve(String(path))
			if c != null and c.is_visible_in_tree():
				found.append(c)
		if not found.is_empty():
			_steps.append({"targets": found, "text": entry["text"]})
	if _steps.is_empty():
		_finish()
		return
	_show(0)


func _resolve(path: String) -> Control:
	var parts := path.split(":")
	if parts.size() != 2:
		return null
	var scope: Node = _menu if parts[0] == "menu" else _menu.get_node_or_null("%HomePage")
	if scope == null:
		return null
	return scope.get_node_or_null("%" + parts[1]) as Control


func _show(i: int) -> void:
	_i = i
	var step := _steps[i]
	var hole := Rect2()
	var first := true
	for c: Control in step["targets"]:
		if not is_instance_valid(c):
			continue
		var r := c.get_global_rect()
		hole = r if first else hole.merge(r)
		first = false
	hole = hole.grow(PAD).intersection(Rect2(Vector2.ZERO, size))
	_layout_dim(hole)
	_ring.position = hole.position
	_ring.size = hole.size
	_message.text = step["text"]
	_next.text = TutorialDB.COACH_DONE if i == _steps.size() - 1 else TutorialDB.COACH_NEXT
	_skip.visible = i < _steps.size() - 1
	_bubble.reset_size()
	var h := _bubble.size.y
	var y := hole.end.y + BUBBLE_MARGIN if hole.get_center().y < size.y * 0.5 else hole.position.y - h - BUBBLE_MARGIN
	y = clampf(y, SCREEN_MARGIN, maxf(size.y - h - SCREEN_MARGIN, SCREEN_MARGIN))
	_bubble.position = Vector2((size.x - _bubble.size.x) * 0.5, y)


## Four dim rectangles around the hole.
func _layout_dim(hole: Rect2) -> void:
	_place(_dim_top, Rect2(0.0, 0.0, size.x, hole.position.y))
	_place(_dim_bottom, Rect2(0.0, hole.end.y, size.x, size.y - hole.end.y))
	_place(_dim_left, Rect2(0.0, hole.position.y, hole.position.x, hole.size.y))
	_place(_dim_right, Rect2(hole.end.x, hole.position.y, size.x - hole.end.x, hole.size.y))


func _place(rect_node: ColorRect, r: Rect2) -> void:
	rect_node.position = r.position
	rect_node.size = Vector2(maxf(r.size.x, 0.0), maxf(r.size.y, 0.0))


func _on_next() -> void:
	AudioManager.play("ui_click")
	if _i >= _steps.size() - 1:
		_finish()
	else:
		_show(_i + 1)


func _finish() -> void:
	AudioManager.play("ui_click")
	finished.emit()
	queue_free()

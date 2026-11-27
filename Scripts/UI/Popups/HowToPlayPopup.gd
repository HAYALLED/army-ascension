class_name HowToPlayPopup
extends Control
## HOW TO PLAY: six swipeable slides (Settings > HOW TO PLAY). Texts and art names are in
## TutorialDB.HOWTO; a slide without art shows a flat placeholder. MENU TOUR starts the home coach marks.

signal tour_requested()

const SWIPE_MIN := 60.0
const DOT_SIZE := 18.0
const DOT_ON := Color(1.0, 0.85, 0.2)
const DOT_OFF := Color(1.0, 1.0, 1.0, 0.35)

@onready var _art: TutorialIcon = %Illustration
@onready var _title: Label = %SlideTitle
@onready var _text: Label = %SlideText
@onready var _dots: HBoxContainer = %Dots
@onready var _back: Button = %BackButton
@onready var _next: Button = %NextButton
@onready var _tour: Button = %TourButton
@onready var _close: Button = %CloseButton
@onready var _heading: Label = %HeadingLabel

var _index: int = 0
var _press_x: float = 0.0
var _dot_nodes: Array[Panel] = []


func _ready() -> void:
	_heading.text = TutorialDB.HOWTO_TITLE
	_tour.text = TutorialDB.HOWTO_TOUR
	_art.mouse_filter = Control.MOUSE_FILTER_STOP
	_art.gui_input.connect(_on_art_input)
	for i in TutorialDB.HOWTO.size():
		var dot := Panel.new()
		dot.custom_minimum_size = Vector2(DOT_SIZE, DOT_SIZE)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_dots.add_child(dot)
		_dot_nodes.append(dot)
	_back.pressed.connect(_go.bind(-1))
	_next.pressed.connect(_on_next)
	_tour.pressed.connect(_on_tour)
	_close.pressed.connect(_dismiss)
	_show(0)


func _show(i: int) -> void:
	_index = clampi(i, 0, TutorialDB.HOWTO.size() - 1)
	var slide: Dictionary = TutorialDB.HOWTO[_index]
	_art.color = slide["color"]
	_art.set_texture_path(TutorialDB.art(String(slide["art"])))
	_title.text = slide["title"]
	_text.text = slide["text"]
	_back.disabled = _index == 0
	_next.text = TutorialDB.HOWTO_DONE if _index == TutorialDB.HOWTO.size() - 1 else TutorialDB.HOWTO_NEXT
	for k in _dot_nodes.size():
		var sb := StyleBoxFlat.new()
		sb.bg_color = DOT_ON if k == _index else DOT_OFF
		sb.set_corner_radius_all(int(DOT_SIZE))
		_dot_nodes[k].add_theme_stylebox_override("panel", sb)


func _go(step: int) -> void:
	AudioManager.play("ui_click")
	_show(_index + step)


func _on_next() -> void:
	if _index >= TutorialDB.HOWTO.size() - 1:
		_dismiss()
	else:
		_go(1)


func _on_tour() -> void:
	AudioManager.play("ui_click")
	tour_requested.emit()
	queue_free()


func _dismiss() -> void:
	AudioManager.play("ui_click")
	queue_free()


## Swipe left = next slide, swipe right = previous (touch arrives as mouse events too).
func _on_art_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var e := event as InputEventMouseButton
		if e.pressed:
			_press_x = e.position.x
		else:
			var dx := e.position.x - _press_x
			if absf(dx) >= SWIPE_MIN:
				_go(-1 if dx > 0.0 else 1)

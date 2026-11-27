class_name TutorialOverlay
extends CanvasLayer
## Tutorial UI drawn above the HUD (scene: Scene/UI/TutorialOverlay.tscn, layer 11, runs while paused):
## the guide's speech card, a highlight ring, a swiping / tapping hand and the SKIP button.
## TutorialDirector drives it. A card without a button never blocks touches, so the player can
## keep steering while a hint is on screen.

signal continue_pressed()
signal skip_pressed()

const RING_PAD := 14.0
const HAND_SWING := 130.0
const HAND_CENTER := Vector2(360.0, 930.0)

@onready var _root: Control = %Root
@onready var _card: PanelContainer = %Card
@onready var _portrait: TutorialIcon = %Portrait
@onready var _message: Label = %Message
@onready var _continue: Button = %ContinueButton
@onready var _skip: Button = %SkipButton
@onready var _ribbon: Control = %Ribbon
@onready var _ribbon_label: Label = %RibbonLabel
@onready var _ring: TutorialIcon = %Ring
@onready var _caption: Label = %RingCaption
@onready var _hand_drag: TutorialIcon = %HandDrag
@onready var _hand_tap: TutorialIcon = %HandTap

var _hand: TutorialIcon = null
var _hand_tween: Tween = null
var _ring_tween: Tween = null
var _hide_left: float = 0.0


func _ready() -> void:
	_card.anchor_top = TutorialDB.CARD_TOP_RATIO
	_card.anchor_bottom = TutorialDB.CARD_TOP_RATIO
	_card.offset_top = 0.0
	_card.offset_bottom = 0.0
	_skip.offset_top = _safe_top() + 255.0
	_skip.offset_bottom = _skip.offset_top + 80.0
	_skip.text = TutorialDB.SKIP_TEXT
	_ribbon.offset_top = _skip.offset_top
	_ribbon.offset_bottom = _skip.offset_bottom
	_ribbon_label.text = TutorialDB.RIBBON_TEXT
	_skip.pressed.connect(_on_skip)
	_continue.pressed.connect(_on_continue)
	TutorialDB.style_card(_card, _message)
	hide_card()
	hide_hand()
	hide_ring()


func _process(delta: float) -> void:
	# The pause menu and the finished battle own the screen: hide everything that floats over it.
	_root.visible = Game.state == Game.State.PLAYING or Game.state == Game.State.WON
	_skip.visible = Game.state == Game.State.PLAYING
	_ribbon.visible = _skip.visible
	if _hide_left > 0.0:
		_hide_left -= delta
		if _hide_left <= 0.0:
			hide_card()


## Shows the guide card. `portrait` = talk / warn / cheer. With `button_text` a button blocks touches
## until pressed (continue_pressed); without it the card hides after `auto_hide` seconds (0 = stays).
func show_card(text: String, portrait: StringName = &"talk", button_text: String = "", auto_hide: float = 0.0) -> void:
	_message.text = text
	_portrait.set_texture_path(TutorialDB.art("guide_portrait_%s.png" % portrait))
	_continue.visible = button_text != ""
	_continue.text = button_text
	_card.mouse_filter = Control.MOUSE_FILTER_STOP if button_text != "" else Control.MOUSE_FILTER_IGNORE
	_card.visible = true
	_card.reset_size()
	_hide_left = auto_hide
	_card.pivot_offset = _card.size * 0.5
	_card.scale = Vector2(0.92, 0.92)
	var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_card, "scale", Vector2.ONE, 0.18)


func hide_card() -> void:
	_hide_left = 0.0
	_card.visible = false


func is_card_visible() -> bool:
	return _card.visible


## kind: &"drag" (swipes left and right) or &"tap".
func show_hand(kind: StringName) -> void:
	hide_hand()
	_hand = _hand_drag if kind == &"drag" else _hand_tap
	_hand.position = HAND_CENTER - _hand.size * 0.5
	_hand.visible = true
	_hand_tween = create_tween().set_loops()
	if kind == &"drag":
		_hand_tween.tween_property(_hand, "position:x", HAND_CENTER.x - HAND_SWING - _hand.size.x * 0.5, 0.7).set_trans(Tween.TRANS_SINE)
		_hand_tween.tween_property(_hand, "position:x", HAND_CENTER.x + HAND_SWING - _hand.size.x * 0.5, 1.2).set_trans(Tween.TRANS_SINE)
		_hand_tween.tween_property(_hand, "position:x", HAND_CENTER.x - _hand.size.x * 0.5, 0.5).set_trans(Tween.TRANS_SINE)
	else:
		_hand_tween.tween_property(_hand, "scale", Vector2(0.85, 0.85), 0.35)
		_hand_tween.tween_property(_hand, "scale", Vector2.ONE, 0.35)


func hide_hand() -> void:
	if _hand_tween != null:
		_hand_tween.kill()
		_hand_tween = null
	_hand_drag.visible = false
	_hand_tap.visible = false
	_hand = null


## Ring around `rect` (screen / canvas coordinates) with an optional caption under it.
func show_ring(rect: Rect2, caption: String = "") -> void:
	var r := rect.grow(RING_PAD)
	_ring.position = r.position
	_ring.size = r.size
	_ring.pivot_offset = r.size * 0.5
	_ring.visible = true
	_caption.text = caption
	_caption.visible = caption != ""
	_caption.position = Vector2(r.position.x, r.end.y + 6.0)
	_caption.size = Vector2(r.size.x, 0.0)
	if _ring_tween == null:
		_ring_tween = create_tween().set_loops()
		_ring_tween.tween_property(_ring, "scale", Vector2(1.05, 1.05), 0.5).set_trans(Tween.TRANS_SINE)
		_ring_tween.tween_property(_ring, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_SINE)


func hide_ring() -> void:
	if _ring_tween != null:
		_ring_tween.kill()
		_ring_tween = null
	_ring.visible = false
	_ring.scale = Vector2.ONE
	_caption.visible = false


func _on_continue() -> void:
	AudioManager.play("ui_click")
	continue_pressed.emit()


func _on_skip() -> void:
	AudioManager.play("ui_click")
	skip_pressed.emit()


func _safe_top() -> float:
	var win := DisplayServer.window_get_size()
	if win.y <= 0:
		return 0.0
	var safe := DisplayServer.get_display_safe_area()
	var vp := get_viewport().get_visible_rect().size
	return float(safe.position.y) * vp.y / float(win.y)

# path: scripts/ui/UnitCard.gd
class_name UnitCard
extends Control
## Reusable soldier card. Look comes only from RankData / UnitClassData.
## Usage: card.configure("Rifleman", &"rare", &"assault", 3, 4, 10, portrait_texture)

signal pressed(card: UnitCard)

const TAP_SLOP := 16.0
const ICON_BASE_PATH := "res://assets/ui/icons/classes/icon_base.png"

@export var icon_base_texture: Texture2D

@onready var _glow_fx: Panel = $GlowFX
@onready var _fallback_panel: Panel = $FallbackPanel
@onready var _art_backdrop: Panel = $ArtBackdrop
@onready var _art_window: TextureRect = $ArtWindow
@onready var _frame: TextureRect = $Frame
@onready var _fire_overlay: TextureRect = $FireOverlay
@onready var _icon_base: TextureRect = $IconBase
@onready var _icon_base_fallback: Panel = $IconBaseFallback
@onready var _class_icon: TextureRect = $ClassIcon
@onready var _class_icon_fallback: Label = $ClassIconFallback
@onready var _gem: TextureRect = $Gem
@onready var _gem_fallback: Panel = $GemFallback
@onready var _name_label: Label = $NameLabel
@onready var _level_label: Label = $LevelLabel
@onready var _shard_bar: ProgressBar = $ShardBar
@onready var _shard_label: Label = $ShardBar/ShardLabel
@onready var _selection_outline: Panel = $SelectionOutline

var _display_name := ""
var _rank_id: StringName = &"common"
var _class_id: StringName = &"unique"
var _level := 1
var _shards := 0
var _shards_needed := 0
var _art: Texture2D
var _selected := false

var _rank: RankData
var _fire_frames: Array[Texture2D] = []
var _fire_index := 0
var _fire_time := 0.0
var _glow_tween: Tween
var _pressing := false
var _press_pos := Vector2.ZERO


func _ready() -> void:
	_art_backdrop.add_theme_stylebox_override("panel", _make_box(Color(0, 0, 0, 0.35), Color(0, 0, 0, 0), 0, 14))
	_icon_base_fallback.add_theme_stylebox_override("panel", _make_box(Color(0.1, 0.1, 0.13, 0.9), Color(1, 1, 1, 0.25), 3, 16))
	if icon_base_texture == null and ResourceLoader.exists(ICON_BASE_PATH):
		icon_base_texture = load(ICON_BASE_PATH) as Texture2D
	_icon_base.texture = icon_base_texture
	_icon_base.visible = icon_base_texture != null
	_icon_base_fallback.visible = icon_base_texture == null
	RankDB.fire_animation_changed.connect(_on_fire_animation_changed)
	RankDB.reloaded.connect(_refresh)
	UnitClassDB.reloaded.connect(_refresh)
	visibility_changed.connect(_update_fire_processing)
	_refresh()


func configure(
	p_name: String,
	p_rank_id: StringName,
	p_class_id: StringName,
	p_level: int,
	p_shards: int,
	p_shards_needed: int,
	p_art: Texture2D = null
) -> void:
	_display_name = p_name
	_rank_id = p_rank_id
	_class_id = p_class_id
	_level = p_level
	_shards = p_shards
	_shards_needed = p_shards_needed
	_art = p_art
	_refresh()


func set_rank_id(p_rank_id: StringName) -> void:
	_rank_id = p_rank_id
	_refresh()


func set_class_id(p_class_id: StringName) -> void:
	_class_id = p_class_id
	_refresh()


func set_selected(value: bool) -> void:
	_selected = value
	if is_node_ready():
		_apply_selection()


func get_rank_id() -> StringName:
	return _rank_id


func get_class_id() -> StringName:
	return _class_id


func _process(delta: float) -> void:
	if _fire_frames.size() < 2 or _rank == null:
		return
	_fire_time += delta
	var step := 1.0 / _rank.fire_fps
	while _fire_time >= step:
		_fire_time -= step
		_fire_index = (_fire_index + 1) % _fire_frames.size()
	_fire_overlay.texture = _fire_frames[_fire_index]


func _gui_input(event: InputEvent) -> void:
	var mouse_event := event as InputEventMouseButton
	if mouse_event == null or mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return
	if mouse_event.pressed:
		_pressing = true
		_press_pos = mouse_event.position
	elif _pressing:
		_pressing = false
		if mouse_event.position.distance_to(_press_pos) <= TAP_SLOP:
			pressed.emit(self)


func _refresh() -> void:
	if not is_node_ready():
		return
	_rank = RankDB.get_rank(_rank_id)
	var unit_class := UnitClassDB.get_unit_class(_class_id)
	_apply_rank(_rank)
	_apply_class(unit_class)
	_apply_texts()
	_apply_selection()
	tooltip_text = "%s - %s" % [_rank.display_name, unit_class.display_name]


func _apply_rank(rank: RankData) -> void:
	var has_frame := rank.frame_texture != null
	_frame.texture = rank.frame_texture
	_frame.visible = has_frame
	_fallback_panel.visible = not has_frame
	if not has_frame:
		_fallback_panel.add_theme_stylebox_override("panel", _make_box(rank.color, rank.glow_color, 6, 24))

	var has_gem := rank.gem_texture != null
	_gem.texture = rank.gem_texture
	_gem.visible = has_gem
	_gem_fallback.visible = not has_gem
	if not has_gem:
		_gem_fallback.add_theme_stylebox_override("panel", _make_box(rank.color, rank.glow_color, 4, 12))

	var text_color := Color.WHITE if has_frame else rank.get_contrast_color()
	var outline_size := 6 if has_frame else 0
	for label: Label in [_name_label, _level_label, _shard_label]:
		label.add_theme_color_override("font_color", text_color)
		label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
		label.add_theme_constant_override("outline_size", outline_size)

	_selection_outline.add_theme_stylebox_override("panel", _make_box(Color(0, 0, 0, 0), rank.glow_color, 8, 24))
	_setup_fire(rank)


func _apply_class(unit_class: UnitClassData) -> void:
	var has_icon := unit_class.icon_texture != null
	_class_icon.texture = unit_class.icon_texture
	_class_icon.modulate = unit_class.tint
	_class_icon.visible = has_icon
	_class_icon_fallback.visible = not has_icon
	_class_icon_fallback.text = unit_class.display_name.substr(0, 1).to_upper()
	_class_icon_fallback.add_theme_color_override("font_color", unit_class.tint)


func _apply_texts() -> void:
	_art_window.texture = _art
	_name_label.text = _display_name
	_level_label.text = "Lv. %d" % _level
	if _shards_needed <= 0:
		_shard_bar.max_value = 1.0
		_shard_bar.value = 1.0
		_shard_label.text = "MAX"
	else:
		_shard_bar.max_value = float(_shards_needed)
		_shard_bar.value = float(clampi(_shards, 0, _shards_needed))
		_shard_label.text = "%d/%d" % [_shards, _shards_needed]


func _apply_selection() -> void:
	_selection_outline.visible = _selected


func _setup_fire(rank: RankData) -> void:
	_stop_glow_tween()
	_fire_frames.clear()
	_fire_index = 0
	_fire_time = 0.0
	_fire_overlay.visible = false
	_glow_fx.visible = false
	if not rank.has_fire:
		_update_fire_processing()
		return
	_fire_frames = _build_fire_frames(rank)
	if _fire_frames.is_empty():
		# No fire textures yet: pulsing glow fallback.
		var glow := rank.glow_color
		glow.a = 0.85
		var style := _make_box(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 24)
		style.shadow_color = glow
		style.shadow_size = 22
		_glow_fx.add_theme_stylebox_override("panel", style)
		_glow_fx.visible = true
		_glow_fx.modulate.a = 0.75
	else:
		_fire_overlay.texture = _fire_frames[0]
		_fire_overlay.visible = true
	_update_fire_processing()


func _build_fire_frames(rank: RankData) -> Array[Texture2D]:
	var frames: Array[Texture2D] = []
	if rank.fire_sheet != null:
		var count := maxi(rank.fire_sheet_frames, 1)
		var sheet_size := rank.fire_sheet.get_size()
		var frame_width := sheet_size.x / float(count)
		for i in count:
			var atlas := AtlasTexture.new()
			atlas.atlas = rank.fire_sheet
			atlas.region = Rect2(i * frame_width, 0.0, frame_width, sheet_size.y)
			frames.append(atlas)
	elif rank.fire_overlay != null:
		frames.append(rank.fire_overlay)
	return frames


func _update_fire_processing() -> void:
	var animate := RankDB.fire_animation_enabled and is_visible_in_tree()
	set_process(animate and _fire_frames.size() > 1)
	var use_glow_tween := animate and _glow_fx.visible
	if use_glow_tween and _glow_tween == null:
		_glow_tween = create_tween().set_loops()
		_glow_tween.tween_property(_glow_fx, "modulate:a", 0.35, 0.9)
		_glow_tween.tween_property(_glow_fx, "modulate:a", 1.0, 0.9)
	elif not use_glow_tween:
		_stop_glow_tween()
		_glow_fx.modulate.a = 0.75


func _stop_glow_tween() -> void:
	if _glow_tween != null:
		_glow_tween.kill()
		_glow_tween = null


func _on_fire_animation_changed(_enabled: bool) -> void:
	_update_fire_processing()


static func _make_box(fill: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(border_width)
	box.set_corner_radius_all(radius)
	return box

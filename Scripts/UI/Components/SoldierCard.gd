class_name SoldierCard
extends VBoxContainer
## Collection card of one soldier class (scene: Scene/UI/Components/SoldierCard.tscn).
## Frame, gem, accent colors and fire effect come from the soldier's rank (RankDB);
## the small icon in the corner comes from its class (UnitClassDB).

signal selected(type: int)

const TAP_SLOP := 14.0

var type: int = SoldierDB.Type.RIFLEMAN
## Dev/preview only: shows this rank instead of the soldier's real one.
var rank_override: StringName = &""

@onready var _glow_fx: Panel = %GlowFX
@onready var _frame: TextureRect = %Frame
@onready var _portrait: TextureRect = %Portrait
@onready var _fire_overlay: TextureRect = %FireOverlay
@onready var _class_icon: TextureRect = %ClassIcon
@onready var _gem: TextureRect = %Gem
@onready var _name: Label = %NameLabel
@onready var _level: Label = %LevelLabel
@onready var _shard_label: Label = %ShardLabel
@onready var _bar: ProgressBar = %ShardBar
@onready var _upgrade: Button = %UpgradeButton

var _press_pos: Vector2 = Vector2.ZERO
var _rank: RankData
var _fire_frames: Array[Texture2D] = []
var _fire_index: int = 0
var _fire_time: float = 0.0
var _glow_tween: Tween


func setup(p_type: int, p_rank_override: StringName = &"") -> void:
	type = p_type
	rank_override = p_rank_override


func _ready() -> void:
	_upgrade.pressed.connect(_on_upgrade)
	PlayerData.wallet_changed.connect(_refresh)
	PlayerData.soldier_changed.connect(func(_t: int) -> void: _refresh())
	RankDB.fire_animation_changed.connect(func(_on: bool) -> void: _update_fire_processing())
	RankDB.reloaded.connect(_refresh)
	UnitClassDB.reloaded.connect(_refresh)
	visibility_changed.connect(_update_fire_processing)
	_refresh()


func _process(delta: float) -> void:
	if _fire_frames.size() < 2 or _rank == null:
		return
	_fire_time += delta
	var step := 1.0 / _rank.fire_fps
	while _fire_time >= step:
		_fire_time -= step
		_fire_index = (_fire_index + 1) % _fire_frames.size()
	_fire_overlay.texture = _fire_frames[_fire_index]


func _refresh() -> void:
	var d: Dictionary = SoldierDB.DATA[type]
	var lv := PlayerData.level_of(type)
	var rank_id: StringName = rank_override if rank_override != &"" else d["rank"]
	_rank = RankDB.get_rank(rank_id)
	var unit_class := UnitClassDB.get_unit_class(d["class"])
	_portrait.texture = load(d["icon"])
	_name.text = str(d["name"]).to_upper()
	var owned := PlayerData.owns(type)
	_level.text = "Lv %d" % lv if owned else "LOCKED"
	# Units the player has not unlocked yet (chest drops) stay visible but dimmed.
	modulate = Color.WHITE if owned else Color(0.55, 0.55, 0.62)
	tooltip_text = "%s - %s" % [_rank.display_name, unit_class.display_name]
	_apply_rank(_rank)
	_class_icon.texture = unit_class.icon_texture
	_class_icon.modulate = unit_class.tint
	var need := SoldierDB.upgrade_shards(lv, type)
	var have := PlayerData.shards_of(type)
	_bar.max_value = need
	_bar.value = mini(have, need)
	if lv >= SoldierDB.MAX_LEVEL:
		_shard_label.text = "MAX"
		_upgrade.text = "MAX"
		_upgrade.disabled = true
	else:
		_shard_label.text = "%d/%d" % [have, need]
		_upgrade.text = "UPGRADE" if owned else "LOCKED"
		_upgrade.disabled = not PlayerData.can_upgrade(type)


func _apply_rank(rank: RankData) -> void:
	_frame.texture = rank.frame_texture
	_gem.texture = rank.gem_texture
	_bar.add_theme_stylebox_override("fill", _make_box(rank.glow_color, 6))
	_bar.add_theme_stylebox_override("background", StyleBoxEmpty.new())
	_setup_fire(rank)


func _setup_fire(rank: RankData) -> void:
	_stop_glow_tween()
	_fire_frames.clear()
	_fire_index = 0
	_fire_time = 0.0
	_fire_overlay.visible = false
	_glow_fx.visible = false
	if rank.has_fire:
		_fire_frames = _build_fire_frames(rank)
		if _fire_frames.is_empty():
			var glow := rank.glow_color
			glow.a = 0.85
			var box := _make_box(Color(0, 0, 0, 0), 28)
			box.shadow_color = glow
			box.shadow_size = 20
			_glow_fx.add_theme_stylebox_override("panel", box)
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


## Fire animation runs only while the card is visible and low graphics is off.
func _update_fire_processing() -> void:
	var animate := RankDB.fire_animation_enabled and is_visible_in_tree()
	set_process(animate and _fire_frames.size() > 1)
	if animate and _glow_fx.visible:
		if _glow_tween == null:
			_glow_tween = create_tween().set_loops()
			_glow_tween.tween_property(_glow_fx, "modulate:a", 0.35, 0.9)
			_glow_tween.tween_property(_glow_fx, "modulate:a", 1.0, 0.9)
	else:
		_stop_glow_tween()
		_glow_fx.modulate.a = 0.75


func _stop_glow_tween() -> void:
	if _glow_tween != null:
		_glow_tween.kill()
		_glow_tween = null


static func _make_box(fill: Color, radius: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.set_corner_radius_all(radius)
	return box


func _on_upgrade() -> void:
	if PlayerData.try_upgrade(type):
		AudioManager.play("gate_good")


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_press_pos = event.position
		elif event.position.distance_to(_press_pos) < TAP_SLOP:
			AudioManager.play("ui_click")
			selected.emit(type)

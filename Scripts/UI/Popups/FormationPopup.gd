class_name FormationPopup
extends Control
## "Prepare your army" (scene: Scene/Menus/Popups/FormationPopup.tscn). The slots on top hold the
## unit classes that go to battle (min 1, max PlayerData.MAX_EQUIPPED); the grid below lists every
## class the player owns. Tap a unit to equip it or remove it. Changes apply at once and are saved
## by SaveManager (PlayerData.equipped_changed). A rare / super rare unit is its own class, so it
## takes its own slot even when it does the same job as its common version.

signal closed()

const TILE := preload("res://Scene/UI/Components/FormationTile.tscn")

@onready var _count: Label = %CountLabel
@onready var _slots: HBoxContainer = %Slots
@onready var _grid: GridContainer = %Grid
@onready var _hint: Label = %HintLabel
@onready var _close: Button = %CloseButton
@onready var _done: Button = %DoneButton

var _default_hint := ""
var _tiles: Dictionary = {}


func _ready() -> void:
	_default_hint = _hint.text
	_close.pressed.connect(close)
	_done.pressed.connect(close)
	var owned := PlayerData.owned_types()
	owned.sort_custom(_before)
	for t in owned:
		var tile := _make_tile(t, true)
		_tiles[t] = tile
		_grid.add_child(tile)
	var filter := UnitFilterBar.new()
	filter.changed.connect(func() -> void:
		for t: int in _tiles:
			(_tiles[t] as FormationTile).visible = filter.matches(t))
	var scroll := _grid.get_parent()
	scroll.get_parent().add_child(filter)
	scroll.get_parent().move_child(filter, scroll.get_index())
	PlayerData.equipped_changed.connect(_refresh_slots)
	_refresh_slots()


func close() -> void:
	AudioManager.play("ui_click")
	closed.emit()
	queue_free()


## Weakest rank first, then by class id.
func _before(a: int, b: int) -> bool:
	var rank_a := RankDB.get_order(SoldierDB.DATA[a]["rank"])
	var rank_b := RankDB.get_order(SoldierDB.DATA[b]["rank"])
	if rank_a != rank_b:
		return rank_a < rank_b
	return a < b


func _make_tile(type: int, list_mode: bool) -> FormationTile:
	var tile := TILE.instantiate() as FormationTile
	tile.setup(type, list_mode)
	tile.pressed.connect(_on_tile_pressed)
	return tile


func _refresh_slots() -> void:
	for c in _slots.get_children():
		_slots.remove_child(c)
		c.queue_free()
	for i in PlayerData.MAX_EQUIPPED:
		var t := PlayerData.equipped[i] if i < PlayerData.equipped.size() else -1
		_slots.add_child(_make_tile(t, false))
	_count.text = "EQUIPPED %d/%d" % [PlayerData.equipped.size(), PlayerData.MAX_EQUIPPED]
	_hint.text = _default_hint


## Tap on a slot or a list tile: equipped -> remove, otherwise -> equip. Empty slots do nothing.
func _on_tile_pressed(type: int) -> void:
	if type < 0:
		return
	AudioManager.play("ui_click")
	if PlayerData.is_equipped(type):
		if not PlayerData.unequip(type):
			_hint.text = "Your army needs at least 1 unit."
	elif not PlayerData.equip(type):
		_hint.text = "Army is full (max %d). Remove a unit first." % PlayerData.MAX_EQUIPPED

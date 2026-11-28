extends Node
## Headless test for the class / rank filter bar on the Soldiers tab and Prepare your army.
## Run: godot --headless --path . res://Tools/test_filter.tscn

var _failed := 0


func _check(name: String, ok: bool) -> void:
	print("%s  %s" % ["PASS" if ok else "FAIL", name])
	if not ok:
		_failed += 1


func _ready() -> void:
	SaveManager.enabled = false
	PlayerData.reset_to_defaults()
	await _test_soldiers_page()
	await _test_formation()
	PlayerData.reset_to_defaults()
	get_tree().quit(0 if _failed == 0 else 1)


func _visible(grid: Container) -> Array:
	return grid.get_children().filter(func(c: Node) -> bool: return (c as Control).visible)


func _chip(bar: Node, text: String) -> Button:
	for b in bar.find_children("*", "Button", true, false):
		if (b as Button).text == text:
			return b
	return null


func _test_soldiers_page() -> void:
	var page := load("res://Scene/Menus/Pages/SoldiersPage.tscn").instantiate() as SoldiersPage
	add_child(page)
	await get_tree().process_frame
	var grid := page.get_node("%Grid") as GridContainer
	var bar := page.find_children("*", "MarginContainer", true, false).filter(func(n: Node) -> bool: return n is UnitFilterBar)[0] as UnitFilterBar
	var all := _visible(grid).size()
	_check("soldiers tab lists %d units, owned and locked" % all, all == SoldierDB.listed_types().size() and all > PlayerData.owned_types().size())
	_chip(bar, "Support").button_pressed = true
	var support := _visible(grid).size()
	var want := 0
	for t in SoldierDB.listed_types():
		want += int(SoldierDB.DATA[t]["class"] == &"support")
	_check("class chip shows only that class (%d)" % support, support == want and support > 0 and support < all)
	_chip(bar, "Rare").button_pressed = true
	var both := _visible(grid).size()
	_check("class + rank combine (AND)", both > 0 and both < support)
	_chip(bar, "Rare").button_pressed = false
	_check("tapping the active chip clears it", _visible(grid).size() == support)
	_chip(bar, "Assault").button_pressed = true
	_check("choosing another class replaces the first", not _chip(bar, "Support").button_pressed)
	_chip(bar, "Assault").button_pressed = false
	_check("no chip = everything again", _visible(grid).size() == all)
	page.queue_free()


func _test_formation() -> void:
	var pop := load("res://Scene/Menus/Popups/FormationPopup.tscn").instantiate() as FormationPopup
	add_child(pop)
	await get_tree().process_frame
	var grid := pop.get_node("%Grid") as GridContainer
	var owned := PlayerData.owned_types().size()
	_check("prepare your army lists owned units only", _visible(grid).size() == owned)
	var bar := pop.find_children("*", "MarginContainer", true, false).filter(func(n: Node) -> bool: return n is UnitFilterBar)[0] as UnitFilterBar
	var first_class: StringName = SoldierDB.DATA[PlayerData.owned_types()[0]]["class"]
	var name := UnitClassDB.get_unit_class(first_class).display_name
	_chip(bar, name).button_pressed = true
	var shown := _visible(grid).size()
	_check("filter narrows the owned list (%d of %d)" % [shown, owned], shown > 0 and shown <= owned)
	pop.queue_free()

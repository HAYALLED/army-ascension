extends Node
## Headless check of rank + class on the soldier cards.
## Run: godot --headless --path . res://Tools/test_cards.tscn

var fails: int = 0


func check(cond: bool, msg: String) -> void:
	if cond:
		print("PASS ", msg)
	else:
		fails += 1
		print("FAIL ", msg)


func _ready() -> void:
	await _run()
	print("RESULT fails=", fails)
	get_tree().quit(1 if fails > 0 else 0)


func _run() -> void:
	var T := SoldierDB.Type
	var expected_rank := {
		T.RIFLEMAN: &"common", T.MACHINE_GUNNER: &"common", T.SNIPER: &"common", T.ROCKET: &"common", T.MEDIC: &"rare",
		T.RIFLEMAN_RARE: &"rare", T.MACHINE_GUNNER_RARE: &"rare", T.SNIPER_RARE: &"rare", T.ROCKET_RARE: &"rare",
		T.MEDIC_SUPER_RARE: &"super_rare",
		T.MORTAR: &"common", T.MORTAR_RARE: &"rare", T.WEAKENER: &"common", T.WEAKENER_RARE: &"rare",
		T.DRUMMER: &"common", T.DRUMMER_RARE: &"rare", T.BLINDER: &"common", T.BLINDER_RARE: &"rare",
		T.SHIELD_KNIGHT: &"common", T.SHIELD_KNIGHT_RARE: &"rare",
	}
	var expected_class := {
		T.RIFLEMAN: &"assault", T.MACHINE_GUNNER: &"assault", T.SNIPER: &"deadeye", T.ROCKET: &"explosive", T.MEDIC: &"support",
		T.RIFLEMAN_RARE: &"assault", T.MACHINE_GUNNER_RARE: &"assault", T.SNIPER_RARE: &"deadeye", T.ROCKET_RARE: &"explosive",
		T.MEDIC_SUPER_RARE: &"support",
		T.MORTAR: &"explosive", T.MORTAR_RARE: &"explosive", T.WEAKENER: &"debuffer", T.WEAKENER_RARE: &"debuffer",
		T.DRUMMER: &"support", T.DRUMMER_RARE: &"support", T.BLINDER: &"debuffer", T.BLINDER_RARE: &"debuffer",
		T.SHIELD_KNIGHT: &"defender", T.SHIELD_KNIGHT_RARE: &"defender",
	}
	for t in SoldierDB.DATA:
		check(SoldierDB.DATA[t]["rank"] == expected_rank[t], "%s rank" % SoldierDB.DATA[t]["name"])
		check(SoldierDB.DATA[t]["class"] == expected_class[t], "%s class" % SoldierDB.DATA[t]["name"])
	check(RankDB.get_sorted().size() == 5 and UnitClassDB.get_sorted().size() == 7, "5 ranks / 7 classes loaded")
	for r in RankDB.get_sorted():
		check(r.frame_texture != null and r.gem_texture != null, "%s has frame+gem" % r.id)
		if r.has_fire:
			check(r.fire_sheet != null, "%s has fire sheet" % r.id)
	for c in UnitClassDB.get_sorted():
		check(c.icon_texture != null, "%s has icon" % c.id)

	var holder := Control.new()
	holder.size = Vector2(720, 1280)
	add_child(holder)
	var scene: PackedScene = load("res://Scene/UI/Components/SoldierCard.tscn")
	var cards: Array[SoldierCard] = []
	for t in SoldierDB.DATA:
		var card := scene.instantiate() as SoldierCard
		card.setup(t)
		holder.add_child(card)
		cards.append(card)
	await get_tree().process_frame
	await get_tree().process_frame
	var medic: SoldierCard = cards[4]
	var rifle: SoldierCard = cards[0]
	check((medic.get_node("%Frame") as TextureRect).texture == RankDB.get_rank(&"rare").frame_texture, "medic card uses rare frame")
	check((rifle.get_node("%Frame") as TextureRect).texture == RankDB.get_rank(&"common").frame_texture, "rifleman card uses common frame")
	check((medic.get_node("%Gem") as TextureRect).texture == RankDB.get_rank(&"rare").gem_texture, "medic gem rare")
	check((rifle.get_node("%ClassIcon") as TextureRect).texture == UnitClassDB.get_unit_class(&"assault").icon_texture, "rifleman class icon")
	var area := rifle.get_node("CardArea") as Control
	check(area.size.is_equal_approx(Vector2(320, 480)), "card area 320x480: " + str(area.size))
	var art := rifle.get_node("%Portrait") as Control
	check(absf(art.size.x - 259.0) < 2.0 and absf(art.size.y - 259.0) < 2.0, "portrait fills art window: " + str(art.size))
	check((rifle.get_node("%NameLabel") as Label).text == "RIFLEMAN", "name label")
	check(not (rifle.get_node("%FireOverlay") as Control).visible, "no fire on common")

	# preview with every rank
	var legend_card := scene.instantiate() as SoldierCard
	legend_card.setup(SoldierDB.Type.RIFLEMAN, &"legend")
	holder.add_child(legend_card)
	await get_tree().process_frame
	check((legend_card.get_node("%FireOverlay") as Control).visible, "legend shows fire overlay")
	check(legend_card.is_processing(), "legend fire animating")
	RankDB.fire_animation_enabled = false
	check(not legend_card.is_processing(), "low graphics stops fire")
	RankDB.fire_animation_enabled = true
	var uniq := scene.instantiate() as SoldierCard
	uniq.setup(SoldierDB.Type.MEDIC, &"unique")
	holder.add_child(uniq)
	await get_tree().process_frame
	check((uniq.get_node("%FireOverlay") as Control).visible, "unique shows fire overlay")

	# tap + upgrade button still work
	var got := [-1]
	rifle.selected.connect(func(t: int) -> void: got[0] = t)
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	down.position = Vector2(20, 20)
	rifle._gui_input(down)
	var up := down.duplicate() as InputEventMouseButton
	up.pressed = false
	rifle._gui_input(up)
	check(got[0] == SoldierDB.Type.RIFLEMAN, "tap emits selected")

	# soldiers page + preview scene
	var page: Control = (load("res://Scene/Menus/Pages/SoldiersPage.tscn") as PackedScene).instantiate()
	holder.add_child(page)
	await get_tree().process_frame
	check(page.get_node("%Grid").get_child_count() == SoldierDB.DATA.size(), "soldiers page has one card per soldier")
	var prev: Control = (load("res://Scene/Dev/RankPreview.tscn") as PackedScene).instantiate()
	holder.add_child(prev)
	await get_tree().process_frame
	check(prev.get_node("%Grid").get_child_count() == 5 * SoldierDB.DATA.size(), "rank preview has every soldier in every rank")
	# detail popup
	var popup: Control = (load("res://Scene/Menus/Popups/UnitDetailPopup.tscn") as PackedScene).instantiate()
	popup.setup(SoldierDB.Type.MEDIC)
	holder.add_child(popup)
	await get_tree().process_frame
	check((popup.get_node("%RarityLabel") as Label).text == "Rare - Support", "popup shows rank - class: " + (popup.get_node("%RarityLabel") as Label).text)

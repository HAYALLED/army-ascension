extends Node
## Regenerates Scene/Dev/RankPreview.tscn. Run: godot --headless --path . res://Tools/build_rank_preview.tscn


func _ready() -> void:
	var root := Control.new()
	root.name = "RankPreview"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.theme = load("res://Resources/UI/ui_theme.tres")
	root.set_script(load("res://Scripts/Dev/RankPreview.gd"))
	var bg := ColorRect.new()
	bg.color = Color(0.13, 0.15, 0.2)
	_add(root, root, bg, "Background")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var vbox := VBoxContainer.new()
	_add(root, root, vbox, "Content")
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var toggle := CheckButton.new()
	toggle.text = "Low graphics (no fire animation)"
	_add(root, vbox, toggle, "LowGraphics", true)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_add(root, vbox, scroll, "Scroll")
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	_add(root, scroll, margin, "Margin")
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 20)
	_add(root, margin, grid, "Grid", true)
	var ps := PackedScene.new()
	ps.pack(root)
	print("save preview -> ", ResourceSaver.save(ps, "res://Scene/Dev/RankPreview.tscn"))
	root.free()
	get_tree().quit()


func _add(owner_node: Node, parent: Node, node: Node, node_name: String, unique: bool = false) -> void:
	node.name = node_name
	parent.add_child(node)
	node.owner = owner_node
	node.unique_name_in_owner = unique

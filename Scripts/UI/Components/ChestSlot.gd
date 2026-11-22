class_name ChestSlot
extends PanelContainer
## One of the 4 chest slots under the DAILY / FREE CHEST buttons on the home page.
## Slots are empty for now. The chest system will fill them later (wooden, silver, gold
## chests dropped after a beaten level): add a set_chest() here and call it from HomePage.
## Built in code with the shared UI theme.

const CHEST_ICON := "res://Assets/UI/chest_wood.png"

## 0-based position of the slot (0..3).
var index: int = 0


func setup(p_index: int) -> void:
	index = p_index
	name = "ChestSlot%d" % (p_index + 1)


func _ready() -> void:
	theme_type_variation = &"PanelDark"
	custom_minimum_size = Vector2(0, 170)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var box := VBoxContainer.new()
	box.name = "Box"
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 4)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(box)
	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.custom_minimum_size = Vector2(0, 96)
	icon.size_flags_vertical = Control.SIZE_EXPAND_FILL
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.modulate = Color(1.0, 1.0, 1.0, 0.2)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(CHEST_ICON):
		icon.texture = load(CHEST_ICON)
	box.add_child(icon)
	var label := Label.new()
	label.name = "StateLabel"
	label.theme_type_variation = &"LabelSmall"
	label.text = "EMPTY"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(label)

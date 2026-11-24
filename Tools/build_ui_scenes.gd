extends Node
## Authoring tool: (re)generates the UI theme and all menu / HUD scenes from
## the 2D assets in Assets/UI.
## Run:  godot --headless --path . res://Tools/build_ui_scenes.tscn
## After generating, edit the scenes freely in the Godot editor.

const UI := "res://Assets/UI/"
const NAVY := Color(0.106, 0.137, 0.251)
const GOLD := Color(1.0, 0.85, 0.25)

var _theme: Theme
var _r: Node


func _ready() -> void:
	_make_theme()
	_theme = load("res://Resources/UI/ui_theme.tres")
	_cur_pill()
	_soldier_card()
	_upgrade_row()
	_mission_row()
	_shop_item()
	_shop_offer()
	_stat_row()
	_unit_preview()
	_home_page()
	_soldiers_page()
	_upgrade_page()
	_missions_page()
	_shop_page()
	_unit_detail_popup()
	_settings_popup()
	_main_menu()
	_loading()
	_hud()
	get_tree().quit()


# ------------------------------------------------------------------ theme

func _sb(tex: String, margin: Vector4, content: Vector4, mod: Color = Color.WHITE) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = load(UI + tex)
	sb.texture_margin_left = margin.x
	sb.texture_margin_top = margin.y
	sb.texture_margin_right = margin.z
	sb.texture_margin_bottom = margin.w
	sb.content_margin_left = content.x
	sb.content_margin_top = content.y
	sb.content_margin_right = content.z
	sb.content_margin_bottom = content.w
	sb.modulate_color = mod
	return sb


func _make_theme() -> void:
	var t := Theme.new()
	t.default_font_size = 30
	# Labels
	t.set_font_size("font_size", "Label", 30)
	t.set_color("font_color", "Label", Color.WHITE)
	t.set_color("font_outline_color", "Label", NAVY)
	t.set_constant("outline_size", "Label", 7)
	for v in [["LabelTitle", 64, 12], ["LabelBig", 40, 9], ["LabelSmall", 24, 5]]:
		t.set_type_variation(v[0], "Label")
		t.set_font_size("font_size", v[0], v[1])
		t.set_constant("outline_size", v[0], v[2])
	t.set_type_variation("LabelDark", "Label")
	t.set_font_size("font_size", "LabelDark", 28)
	t.set_color("font_color", "LabelDark", NAVY)
	t.set_constant("outline_size", "LabelDark", 0)
	# Buttons
	t.set_font_size("font_size", "Button", 40)
	t.set_color("font_color", "Button", Color.WHITE)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", Color.WHITE)
	t.set_color("font_hover_pressed_color", "Button", Color.WHITE)
	t.set_color("font_disabled_color", "Button", Color(0.9, 0.92, 0.97, 0.85))
	t.set_color("font_outline_color", "Button", NAVY)
	t.set_constant("outline_size", "Button", 8)
	t.set_constant("h_separation", "Button", 12)
	t.set_constant("icon_max_width", "Button", 72)
	var empty := StyleBoxEmpty.new()
	var variants := [
		["ButtonPrimary", "btn_primary.png"], ["ButtonSecondary", "btn_secondary.png"],
		["ButtonGold", "btn_gold.png"], ["ButtonDanger", "btn_danger.png"],
		["ButtonDisabled", "btn_disabled.png"],
	]
	var bm := Vector4(60, 36, 60, 36)
	var bc := Vector4(24, 8, 24, 12)
	t.set_stylebox("normal", "Button", _sb("btn_secondary.png", bm, bc))
	t.set_stylebox("hover", "Button", _sb("btn_secondary.png", bm, bc, Color(1.12, 1.12, 1.12)))
	t.set_stylebox("pressed", "Button", _sb("btn_secondary.png", bm, bc, Color(0.8, 0.8, 0.8)))
	t.set_stylebox("disabled", "Button", _sb("btn_disabled.png", bm, bc))
	t.set_stylebox("focus", "Button", empty)
	for v in variants:
		t.set_type_variation(v[0], "Button")
		t.set_stylebox("normal", v[0], _sb(v[1], bm, bc))
		t.set_stylebox("hover", v[0], _sb(v[1], bm, bc, Color(1.12, 1.12, 1.12)))
		t.set_stylebox("pressed", v[0], _sb(v[1], bm, bc, Color(0.8, 0.8, 0.8)))
		t.set_stylebox("hover_pressed", v[0], _sb(v[1], bm, bc, Color(0.9, 0.9, 0.9)))
		t.set_stylebox("disabled", v[0], _sb("btn_disabled.png", bm, bc))
		t.set_stylebox("focus", v[0], empty)
	# Round icon button
	var rm := Vector4(50, 50, 50, 50)
	t.set_type_variation("ButtonRound", "Button")
	t.set_stylebox("normal", "ButtonRound", _sb("btn_round.png", rm, Vector4(14, 14, 14, 14)))
	t.set_stylebox("hover", "ButtonRound", _sb("btn_round.png", rm, Vector4(14, 14, 14, 14), Color(1.12, 1.12, 1.12)))
	t.set_stylebox("pressed", "ButtonRound", _sb("btn_round.png", rm, Vector4(14, 14, 14, 14), Color(0.8, 0.8, 0.8)))
	t.set_stylebox("focus", "ButtonRound", empty)
	# Bottom tabs (toggle buttons)
	var tm := Vector4(40, 40, 40, 40)
	var tc := Vector4(6, 6, 6, 6)
	t.set_type_variation("TabButton", "Button")
	t.set_font_size("font_size", "TabButton", 22)
	t.set_constant("outline_size", "TabButton", 5)
	t.set_constant("icon_max_width", "TabButton", 64)
	t.set_constant("h_separation", "TabButton", 0)
	for st in ["normal", "hover", "disabled"]:
		t.set_stylebox(st, "TabButton", _sb("tab_inactive.png", tm, tc))
	for st in ["pressed", "hover_pressed"]:
		t.set_stylebox(st, "TabButton", _sb("tab_active.png", tm, tc))
	t.set_stylebox("focus", "TabButton", empty)
	# Panels
	var panels := [
		["PanelPopup", "panel_popup.png", Vector4(72, 72, 72, 72), Vector4(36, 36, 36, 36)],
		["PanelCard", "panel_card.png", Vector4(48, 48, 48, 48), Vector4(18, 18, 18, 18)],
		["PanelDark", "panel_dark.png", Vector4(40, 40, 40, 40), Vector4(16, 12, 16, 12)],
		["PanelCurrency", "topbar_currency.png", Vector4(28, 28, 28, 28), Vector4(12, 4, 14, 4)],
	]
	for p in panels:
		t.set_type_variation(p[0], "PanelContainer")
		t.set_stylebox("panel", p[0], _sb(p[1], p[2], p[3]))
	DirAccess.make_dir_recursive_absolute("res://Resources/UI")
	print("theme saved: ", ResourceSaver.save(t, "res://Resources/UI/ui_theme.tres"))


# ------------------------------------------------------------------ helpers

func _begin(root: Node) -> Node:
	_r = root
	if root is Control:
		(root as Control).theme = _theme
	return root


func _add(parent: Node, node: Node, node_name: String, unique: bool = false) -> Node:
	node.name = node_name
	parent.add_child(node)
	node.owner = _r
	if unique:
		node.unique_name_in_owner = true
	return node


func _full(c: Control) -> void:
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _lbl(parent: Node, node_name: String, text: String, variation: String = "", unique: bool = false, align: int = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = align as HorizontalAlignment
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if variation != "":
		l.theme_type_variation = variation
	_add(parent, l, node_name, unique)
	return l


func _tex(parent: Node, node_name: String, path: String, min_size: Vector2 = Vector2.ZERO, unique: bool = false, stretch: int = TextureRect.STRETCH_KEEP_ASPECT_CENTERED) -> TextureRect:
	var t := TextureRect.new()
	if path != "":
		t.texture = load(UI + path)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = stretch as TextureRect.StretchMode
	t.custom_minimum_size = min_size
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_add(parent, t, node_name, unique)
	return t


func _btn(parent: Node, node_name: String, text: String, variation: String = "", min_size: Vector2 = Vector2.ZERO, unique: bool = false, icon: String = "") -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	if variation != "":
		b.theme_type_variation = variation
	b.custom_minimum_size = min_size
	if icon != "":
		b.icon = load(UI + icon)
		b.expand_icon = true
	_add(parent, b, node_name, unique)
	return b


func _box(vertical: bool, parent: Node, node_name: String, sep: int = 8, unique: bool = false) -> BoxContainer:
	var b: BoxContainer = VBoxContainer.new() if vertical else HBoxContainer.new()
	b.add_theme_constant_override("separation", sep)
	_add(parent, b, node_name, unique)
	return b


func _panel(parent: Node, node_name: String, variation: String, min_size: Vector2 = Vector2.ZERO, unique: bool = false) -> PanelContainer:
	var p := PanelContainer.new()
	p.theme_type_variation = variation
	p.custom_minimum_size = min_size
	_add(parent, p, node_name, unique)
	return p


func _bar(parent: Node, node_name: String, fill: String, min_size: Vector2, unique: bool = false) -> TextureProgressBar:
	var b := TextureProgressBar.new()
	b.texture_under = load(UI + "bar_frame.png")
	b.texture_progress = load(UI + "bar_fill_%s.png" % fill)
	b.nine_patch_stretch = true
	b.stretch_margin_left = 22
	b.stretch_margin_right = 22
	b.stretch_margin_top = 10
	b.stretch_margin_bottom = 10
	b.custom_minimum_size = min_size
	b.value = 100.0
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_add(parent, b, node_name, unique)
	return b


func _spacer(parent: Node, expand_h: bool = true, min_size: Vector2 = Vector2.ZERO) -> Control:
	var c := Control.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.custom_minimum_size = min_size
	if expand_h:
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	else:
		c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_add(parent, c, "Spacer")
	return c


func _ribbon(parent: Node, text: String) -> void:
	var h := Control.new()
	h.custom_minimum_size = Vector2(0, 110)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_add(parent, h, "Header")
	var r := _tex(h, "Ribbon", "panel_header.png")
	_full(r)
	var l := _lbl(h, "Title", text, "LabelBig", false, HORIZONTAL_ALIGNMENT_CENTER)
	_full(l)
	l.offset_bottom = -12


func _save(root: Node, path: String) -> void:
	var ps := PackedScene.new()
	ps.pack(root)
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	print("save ", path, " -> ", ResourceSaver.save(ps, path))
	root.free()


func _page_root(page_name: String, script: String) -> Control:
	var root := Control.new()
	root.name = page_name
	if script != "":
		root.set_script(load(script))
	_begin(root)
	_full(root)
	return root


func _instance(parent: Node, path: String, node_name: String, unique: bool = false) -> Node:
	var n := (load(path) as PackedScene).instantiate()
	_add(parent, n, node_name, unique)
	return n


func _scroll(parent: Node, node_name: String = "Scroll") -> ScrollContainer:
	var s := ScrollContainer.new()
	s.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	s.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	s.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_add(parent, s, node_name)
	return s


func _margin(parent: Node, node_name: String, m: int) -> MarginContainer:
	var c := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		c.add_theme_constant_override("margin_" + side, m)
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_add(parent, c, node_name)
	return c


# ------------------------------------------------------------------ components

func _cur_pill() -> void:
	var root := PanelContainer.new()
	root.name = "CurrencyPill"
	root.theme_type_variation = "PanelCurrency"
	root.custom_minimum_size = Vector2(160, 64)
	root.set_script(load("res://Scripts/UI/Components/CurrencyPill.gd"))
	_begin(root)
	var h := _box(false, root, "Row", 8)
	_tex(h, "Icon", "icon_gold.png", Vector2(44, 44), true)
	var v := _lbl(h, "Value", "0", "", true, HORIZONTAL_ALIGNMENT_RIGHT)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_save(root, "res://Scene/UI/Components/CurrencyPill.tscn")


func _soldier_card() -> void:
	# Card art uses the rank frame (512x768); anchors below match its windows:
	# class-icon slot, gem slot, art window, name/level strip and the shard-bar slot.
	var root := VBoxContainer.new()
	root.name = "SoldierCard"
	root.add_theme_constant_override("separation", 6)
	root.custom_minimum_size = Vector2(320, 0)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	root.set_script(load("res://Scripts/UI/Components/SoldierCard.gd"))
	_begin(root)
	var area := Control.new()
	area.custom_minimum_size = Vector2(320, 480)
	area.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_add(root, area, "CardArea")
	var glow := Panel.new()
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_add(area, glow, "GlowFX", true)
	_card_anchor(glow, 0, 0, 1, 1)
	var frame := _card_tex(area, "Frame", "res://Assets/UI/Cards/frame_common.png", 0, 0, 1, 1, TextureRect.STRETCH_SCALE)
	_card_tex(area, "Portrait", "res://Assets/UI/class_rifleman.png", 0.0957, 0.2174, 0.9043, 0.7565)
	var fire := _card_tex(area, "FireOverlay", "", 0, 0, 1, 1, TextureRect.STRETCH_SCALE)
	fire.visible = false
	_card_tex(area, "ClassIcon", "res://Assets/UI/Icons/icon_assault.png", 0.1094, 0.0781, 0.2656, 0.1719)
	_card_tex(area, "Gem", "res://Assets/UI/Cards/gem_common.png", 0.7344, 0.0781, 0.8906, 0.1719)
	var nm := _card_lbl(area, "NameLabel", "RIFLEMAN", 0.1016, 0.7865, 0.8984, 0.8438, 22, HORIZONTAL_ALIGNMENT_CENTER)
	nm.clip_text = true
	_card_lbl(area, "LevelLabel", "Lv 1", 0.1172, 0.8464, 0.5, 0.9089, 20, HORIZONTAL_ALIGNMENT_LEFT)
	_card_tex(area, "ShardIcon", "res://Assets/UI/icon_shard.png", 0.5430, 0.8542, 0.6094, 0.9010)
	_card_lbl(area, "ShardLabel", "4/10", 0.6133, 0.8464, 0.8828, 0.9089, 20, HORIZONTAL_ALIGNMENT_RIGHT)
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.value = 40.0
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_add(area, bar, "ShardBar", true)
	_card_anchor(bar, 0.1289, 0.9141, 0.8711, 0.9401)
	var up := _btn(root, "UpgradeButton", "UPGRADE", "ButtonPrimary", Vector2(320, 76), true)
	up.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	up.add_theme_font_size_override("font_size", 30)
	frame.unique_name_in_owner = true
	_save(root, "res://Scene/UI/Components/SoldierCard.tscn")


func _card_anchor(c: Control, l: float, t: float, r: float, b: float) -> void:
	c.set_anchors_preset(Control.PRESET_TOP_LEFT)
	c.anchor_left = l
	c.anchor_top = t
	c.anchor_right = r
	c.anchor_bottom = b
	c.offset_left = 0
	c.offset_top = 0
	c.offset_right = 0
	c.offset_bottom = 0
	c.set("layout_mode", 1)


func _card_tex(parent: Node, node_name: String, path: String, l: float, t: float, r: float, b: float, stretch: int = TextureRect.STRETCH_KEEP_ASPECT_CENTERED) -> TextureRect:
	var tr := TextureRect.new()
	if path != "":
		tr.texture = load(path)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = stretch as TextureRect.StretchMode
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_add(parent, tr, node_name, true)
	_card_anchor(tr, l, t, r, b)
	return tr


func _card_lbl(parent: Node, node_name: String, text: String, l: float, t: float, r: float, b: float, font: int, align: int) -> Label:
	var lb := Label.new()
	lb.text = text
	lb.horizontal_alignment = align as HorizontalAlignment
	lb.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lb.add_theme_font_size_override("font_size", font)
	lb.add_theme_constant_override("outline_size", 5)
	lb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_add(parent, lb, node_name, true)
	_card_anchor(lb, l, t, r, b)
	return lb


func _upgrade_row() -> void:
	var root := PanelContainer.new()
	root.name = "UpgradeRow"
	root.theme_type_variation = "PanelDark"
	root.custom_minimum_size = Vector2(0, 150)
	root.set_script(load("res://Scripts/UI/Components/UpgradeRow.gd"))
	_begin(root)
	var h := _box(false, root, "Row", 14)
	_tex(h, "ClassIcon", "class_rifleman.png", Vector2(96, 96), true)
	var info := _box(true, h, "Info", 2)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var nl := _lbl(info, "NameLabel", "BATTLE INCOME  Lv 0", "LabelBig", true)
	nl.add_theme_font_size_override("font_size", 30)
	nl.clip_text = true
	var sl := _lbl(info, "StatLabel", "More gold at the end of every level.\n+0% > +10%", "LabelSmall", true)
	sl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sl.custom_minimum_size = Vector2(120, 0)
	var cost := _box(true, h, "Cost", 2)
	var g := _box(false, cost, "GoldRow", 6)
	_tex(g, "GoldIcon", "icon_gold.png", Vector2(36, 36))
	_lbl(g, "GoldCost", "500", "LabelSmall", true)
	var b := _btn(h, "UpgradeButton", "UPGRADE", "ButtonPrimary", Vector2(150, 84), true)
	b.add_theme_font_size_override("font_size", 24)
	_save(root, "res://Scene/UI/Components/UpgradeRow.tscn")


func _mission_row() -> void:
	var root := PanelContainer.new()
	root.name = "MissionRow"
	root.theme_type_variation = "PanelDark"
	root.custom_minimum_size = Vector2(0, 130)
	root.set_script(load("res://Scripts/UI/Components/MissionRow.gd"))
	_begin(root)
	var h := _box(false, root, "Row", 14)
	_tex(h, "Icon", "icon_trophy.png", Vector2(80, 80), true)
	var info := _box(true, h, "Info", 4)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lbl(info, "TitleLabel", "Defeat 100 enemies", "LabelSmall", true)
	var pr := _box(false, info, "ProgressRow", 8)
	_bar(pr, "Bar", "yellow", Vector2(150, 30), true)
	_lbl(pr, "ProgressLabel", "0/100", "LabelSmall", true)
	var rw := _box(true, h, "Reward", 0)
	var ri := _tex(rw, "RewardIcon", "icon_gold.png", Vector2(48, 48), true)
	ri.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_lbl(rw, "RewardLabel", "300", "LabelSmall", true, HORIZONTAL_ALIGNMENT_CENTER)
	var b := _btn(h, "ClaimButton", "CLAIM", "ButtonGold", Vector2(150, 72), true)
	b.add_theme_font_size_override("font_size", 28)
	_save(root, "res://Scene/UI/Components/MissionRow.tscn")


func _shop_item() -> void:
	var root := PanelContainer.new()
	root.name = "ShopItem"
	root.theme_type_variation = "PanelCard"
	root.custom_minimum_size = Vector2(200, 330)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.set_script(load("res://Scripts/UI/Components/ShopItem.gd"))
	_begin(root)
	var v := _box(true, root, "Content", 4)
	_lbl(v, "TitleLabel", "GOLD", "LabelDark", true, HORIZONTAL_ALIGNMENT_CENTER)
	var ic := _tex(v, "Icon", "shop_gold_s.png", Vector2(140, 140), true)
	ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ic.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_lbl(v, "AmountLabel", "x500", "LabelDark", true, HORIZONTAL_ALIGNMENT_CENTER)
	var b := _btn(v, "BuyButton", "$0.99", "ButtonGold", Vector2(0, 76), true)
	b.add_theme_font_size_override("font_size", 30)
	_save(root, "res://Scene/UI/Components/ShopItem.tscn")


func _shop_offer() -> void:
	var root := PanelContainer.new()
	root.name = "ShopOffer"
	root.theme_type_variation = "PanelDark"
	root.custom_minimum_size = Vector2(0, 170)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.set_script(load("res://Scripts/UI/Components/ShopOffer.gd"))
	_begin(root)
	var h := _box(false, root, "Row", 16)
	_tex(h, "Icon", "icon_ad_video.png", Vector2(120, 120), true)
	var v := _box(true, h, "Info", 4)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lbl(v, "TitleLabel", "OFFER", "", true)
	var d := _lbl(v, "DescLabel", "", "LabelSmall", true)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var b := _btn(h, "BuyButton", "$2.99", "ButtonGold", Vector2(190, 84), true)
	b.add_theme_font_size_override("font_size", 30)
	_save(root, "res://Scene/UI/Components/ShopOffer.tscn")


func _stat_row() -> void:
	var root := HBoxContainer.new()
	root.name = "StatRow"
	root.add_theme_constant_override("separation", 12)
	root.set_script(load("res://Scripts/UI/Components/StatRow.gd"))
	_begin(root)
	_tex(root, "Icon", "icon_damage.png", Vector2(48, 48), true)
	var n := _lbl(root, "NameLabel", "Damage", "", true)
	n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lbl(root, "ValueLabel", "10", "LabelBig", true, HORIZONTAL_ALIGNMENT_RIGHT)
	var nx := _lbl(root, "NextLabel", "+5", "LabelBig", true)
	nx.add_theme_color_override("font_color", Color(0.45, 1.0, 0.55))
	nx.custom_minimum_size = Vector2(80, 0)
	_save(root, "res://Scene/UI/Components/StatRow.tscn")


func _unit_preview() -> void:
	var root := SubViewportContainer.new()
	root.name = "UnitPreview3D"
	root.stretch = true
	root.custom_minimum_size = Vector2(360, 340)
	root.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	root.set_script(load("res://Scripts/UI/Components/UnitPreview3D.gd"))
	_begin(root)
	var vp := SubViewport.new()
	vp.transparent_bg = true
	vp.own_world_3d = true
	vp.size = Vector2i(360, 340)
	_add(root, vp, "Viewport")
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.85, 0.88, 1.0)
	env.ambient_light_energy = 0.8
	var we := WorldEnvironment.new()
	we.environment = env
	_add(vp, we, "WorldEnvironment")
	var cam := Camera3D.new()
	cam.position = Vector3(0, 2.384, 3.391)
	cam.rotation_degrees = Vector3(-30, 0, 0)
	cam.fov = 32.0
	_add(vp, cam, "Camera3D")
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, 25, 0)
	sun.light_energy = 1.1
	_add(vp, sun, "Sun")
	var pivot := Node3D.new()
	_add(vp, pivot, "Pivot", true)
	_save(root, "res://Scene/UI/Components/UnitPreview3D.tscn")


# ------------------------------------------------------------------ pages

func _home_page() -> void:
	var root := _page_root("HomePage", "res://Scripts/UI/Pages/HomePage.gd")
	var m := _margin(root, "Margin", 24)
	_full(m)
	var v := _box(true, m, "Content", 14)
	_tex(v, "Logo", "logo.png", Vector2(0, 340))
	var lv := Control.new()
	lv.custom_minimum_size = Vector2(0, 110)
	lv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_add(v, lv, "LevelBanner")
	_full(_tex(lv, "Ribbon", "panel_header.png"))
	var ll := _lbl(lv, "LevelLabel", "LEVEL 1", "LabelBig", true, HORIZONTAL_ALIGNMENT_CENTER)
	_full(ll)
	ll.offset_bottom = -12
	_spacer(v, false)
	var play := _btn(v, "PlayButton", "PLAY", "ButtonPrimary", Vector2(520, 150), true, "icon_play.png")
	play.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	play.add_theme_font_size_override("font_size", 72)
	play.add_theme_constant_override("icon_max_width", 96)
	var row := _box(false, v, "Extras", 16)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var d := _btn(row, "DailyButton", "DAILY", "ButtonGold", Vector2(250, 90), true, "icon_calendar_gift.png")
	d.add_theme_font_size_override("font_size", 32)
	var c := _btn(row, "ChestButton", "FREE CHEST", "ButtonSecondary", Vector2(290, 90), true, "icon_ad_video.png")
	c.add_theme_font_size_override("font_size", 30)
	_spacer(v, false, Vector2(0, 8))
	_save(root, "res://Scene/Menus/Pages/HomePage.tscn")


func _soldiers_page() -> void:
	var root := _page_root("SoldiersPage", "res://Scripts/UI/Pages/SoldiersPage.gd")
	var v := _box(true, root, "Content", 10)
	_full(v)
	_ribbon(v, "SOLDIERS")
	var s := _scroll(v)
	var m := _margin(s, "Margin", 16)
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 20)
	g.add_theme_constant_override("v_separation", 20)
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_add(m, g, "Grid", true)
	_save(root, "res://Scene/Menus/Pages/SoldiersPage.tscn")


func _upgrade_page() -> void:
	var root := _page_root("UpgradePage", "res://Scripts/UI/Pages/UpgradePage.gd")
	var v := _box(true, root, "Content", 10)
	_full(v)
	_ribbon(v, "UPGRADES")
	var s := _scroll(v)
	var m := _margin(s, "Margin", 16)
	var l := _box(true, m, "List", 16, true)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_save(root, "res://Scene/Menus/Pages/UpgradePage.tscn")


func _missions_page() -> void:
	var root := _page_root("MissionsPage", "res://Scripts/UI/Pages/MissionsPage.gd")
	var v := _box(true, root, "Content", 10)
	_full(v)
	_ribbon(v, "MISSIONS")
	var m0 := _margin(v, "StripMargin", 16)
	var p := _panel(m0, "DailyLogin", "PanelDark")
	var pv := _box(true, p, "Box", 6)
	_lbl(pv, "Title", "DAILY LOGIN", "LabelSmall", false, HORIZONTAL_ALIGNMENT_CENTER)
	var days := _box(false, pv, "Days", 6)
	var rewards := [["icon_gold.png", "100"], ["icon_gold.png", "200"], ["icon_shard.png", "5"], ["icon_gold.png", "300"],
		["icon_shard.png", "10"], ["icon_gold.png", "500"], ["chest_gold.png", "BOX"]]
	for i in 7:
		var d := _box(true, days, "Day%d" % (i + 1), 2)
		d.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_lbl(d, "Name", "D%d" % (i + 1), "LabelSmall", false, HORIZONTAL_ALIGNMENT_CENTER)
		_tex(d, "Icon", rewards[i][0], Vector2(56, 56))
		_lbl(d, "Amount", rewards[i][1], "LabelSmall", false, HORIZONTAL_ALIGNMENT_CENTER)
	var m1 := _margin(v, "TabsMargin", 16)
	var tabs := _box(false, m1, "Tabs", 8)
	var group := ButtonGroup.new()
	for t in [["TabDaily", "DAILY"], ["TabWeekly", "WEEKLY"], ["TabAchievements", "ACHIEVEMENTS"]]:
		var b := _btn(tabs, t[0], t[1], "TabButton", Vector2(0, 80), true)
		b.toggle_mode = true
		b.button_group = group
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 26)
		if t[0] == "TabDaily":
			b.button_pressed = true
	var s := _scroll(v)
	var m := _margin(s, "Margin", 16)
	var l := _box(true, m, "List", 14, true)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_save(root, "res://Scene/Menus/Pages/MissionsPage.tscn")


func _shop_page() -> void:
	var root := _page_root("ShopPage", "res://Scripts/UI/Pages/ShopPage.gd")
	var v := _box(true, root, "Content", 10)
	_full(v)
	_ribbon(v, "SHOP")
	var s := _scroll(v)
	var m := _margin(s, "Margin", 16)
	var col := _box(true, m, "List", 16)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_offer(col, "AdShards", "ad_shards", "FREE SHARDS", "Watch a short video: +5 shards", "WATCH", "icon_ad_video.png", "ButtonPrimary")
	_offer(col, "Starter", "starter_bundle", "STARTER BUNDLE", "Gold, shards and a chest", "$2.99", "shop_bundle_starter.png", "ButtonGold")
	_offer(col, "WoodChest", "wood_chest", "WOODEN CHEST", "Watch a video to get a wooden chest", "WATCH", "chest_wood.png", "ButtonPrimary")
	_offer(col, "GoldChest", "gold_chest", "GOLD CHEST", "", "20 GEMS", "chest_gold.png", "ButtonGold")
	_lbl(col, "GoldTitle", "GOLD", "LabelBig")
	var g := _box(false, col, "GoldRow", 16)
	_item(g, "Gold1", "gold_s", "SMALL", "x500", "$0.99", "shop_gold_s.png", "ButtonGold")
	_item(g, "Gold2", "gold_m", "MEDIUM", "x1,500", "$2.99", "shop_gold_m.png", "ButtonGold")
	_item(g, "Gold3", "gold_l", "LARGE", "x5,000", "$7.99", "shop_gold_l.png", "ButtonGold")
	_lbl(col, "GemTitle", "GEMS", "LabelBig")
	var sh := _box(false, col, "GemRow", 16)
	_item(sh, "Gem1", "gems_s", "SMALL", "x40", "$0.99", "icon_gem.png", "ButtonGold")
	_item(sh, "Gem2", "gems_m", "MEDIUM", "x150", "$2.99", "icon_gem.png", "ButtonGold")
	_item(sh, "Gem3", "gems_l", "LARGE", "x500", "$7.99", "icon_gem.png", "ButtonGold")
	_offer(col, "NoAds", "remove_ads", "NO RANDOM ADS", "No more ad after every 2 games! Reward ads pay instantly", "$4.99", "shop_no_ads.png", "ButtonGold")
	_save(root, "res://Scene/Menus/Pages/ShopPage.tscn")


func _item(parent: Node, node_name: String, id: String, title: String, amount: String, price: String, icon: String, style: String) -> void:
	var n := _instance(parent, "res://Scene/UI/Components/ShopItem.tscn", node_name) as ShopItem
	n.item_id = id
	n.title = title
	n.amount_text = amount
	n.price_text = price
	n.icon = load(UI + icon)
	n.button_style = style


func _offer(parent: Node, node_name: String, id: String, title: String, desc: String, price: String, icon: String, style: String) -> void:
	var n := _instance(parent, "res://Scene/UI/Components/ShopOffer.tscn", node_name) as ShopOffer
	n.item_id = id
	n.title = title
	n.description = desc
	n.price_text = price
	n.icon = load(UI + icon)
	n.button_style = style


# ------------------------------------------------------------------ popups

func _dim_popup(name_: String, script: String) -> Control:
	var root := Control.new()
	root.name = name_
	root.set_script(load(script))
	_begin(root)
	_full(root)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	_add(root, dim, "Dim")
	_full(dim)
	return root


func _unit_detail_popup() -> void:
	var root := _dim_popup("UnitDetailPopup", "res://Scripts/UI/Popups/UnitDetailPopup.gd")
	var c := CenterContainer.new()
	_add(root, c, "Center")
	_full(c)
	var p := _panel(c, "Panel", "PanelPopup", Vector2(650, 0))
	var v := _box(true, p, "Content", 8)
	var top := _box(false, v, "Top", 8)
	var n := _lbl(top, "NameLabel", "RIFLEMAN", "LabelBig", true)
	n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var close := _btn(top, "CloseButton", "", "ButtonRound", Vector2(84, 84), true, "icon_close.png")
	close.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var r := _box(false, v, "Rarity", 16)
	_lbl(r, "RarityLabel", "Common", "LabelSmall", true)
	_lbl(r, "LevelLabel", "Lv 1", "LabelSmall", true)
	_instance(v, "res://Scene/UI/Components/UnitPreview3D.tscn", "Preview", true)
	var d := _lbl(v, "DescLabel", "", "LabelSmall", true, HORIZONTAL_ALIGNMENT_CENTER)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.custom_minimum_size = Vector2(0, 64)
	_box(true, v, "Stats", 6, true)
	var cost := _box(false, v, "Cost", 10)
	cost.alignment = BoxContainer.ALIGNMENT_CENTER
	_tex(cost, "GoldIcon", "icon_gold.png", Vector2(44, 44))
	_lbl(cost, "GoldCost", "500", "LabelBig", true)
	_spacer(cost, true, Vector2(30, 0)).size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_tex(cost, "ShardIcon", "icon_shard.png", Vector2(44, 44))
	_lbl(cost, "ShardCost", "10", "LabelBig", true)
	_btn(v, "UpgradeButton", "UPGRADE", "ButtonPrimary", Vector2(0, 100), true)
	_save(root, "res://Scene/Menus/Popups/UnitDetailPopup.tscn")


func _settings_popup() -> void:
	var root := _dim_popup("SettingsPopup", "res://Scripts/UI/Popups/SettingsPopup.gd")
	var c := CenterContainer.new()
	_add(root, c, "Center")
	_full(c)
	var p := _panel(c, "Panel", "PanelPopup", Vector2(620, 0))
	var v := _box(true, p, "Content", 14)
	var top := _box(false, v, "Top", 8)
	var t := _lbl(top, "Title", "SETTINGS", "LabelBig")
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn(top, "CloseButton", "", "ButtonRound", Vector2(84, 84), true, "icon_close.png")
	for r in [["Sound", "icon_sound_on.png", "SoundToggle"], ["Music", "icon_music_on.png", "MusicToggle"], ["Vibration", "icon_vibration_on.png", "VibrationToggle"]]:
		var row := _box(false, v, r[0] + "Row", 12)
		_tex(row, "Icon", r[1], Vector2(56, 56))
		var l := _lbl(row, "Label", str(r[0]).to_upper(), "LabelBig")
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var b := _btn(row, r[2], "ON", "ButtonPrimary", Vector2(150, 76), true)
		b.toggle_mode = true
		b.button_pressed = true
		b.add_theme_font_size_override("font_size", 34)
	_lbl(v, "GraphicsLabel", "GRAPHICS", "LabelBig")
	var g := _box(false, v, "GraphicsRow", 12)
	var group := ButtonGroup.new()
	for q in [["GfxLow", "LOW"], ["GfxHigh", "HIGH"]]:
		var b := _btn(g, q[0], q[1], "ButtonDisabled", Vector2(0, 80), true)
		b.toggle_mode = true
		b.button_group = group
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 34)
	_save(root, "res://Scene/Menus/Popups/SettingsPopup.tscn")


# ------------------------------------------------------------------ main menu / loading / HUD

func _main_menu() -> void:
	var root := Control.new()
	root.name = "MainMenu"
	root.set_script(load("res://Scripts/UI/MainMenu.gd"))
	_begin(root)
	_full(root)
	var bg := _tex(root, "Background", "bg_main_menu.png", Vector2.ZERO, true, TextureRect.STRETCH_KEEP_ASPECT_COVERED)
	_full(bg)
	var pages := Control.new()
	pages.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_add(root, pages, "Pages")
	_full(pages)
	pages.offset_top = 130.0
	pages.offset_bottom = -180.0
	for pg in [["HomePage", "HomePage"], ["SoldiersPage", "SoldiersPage"], ["UpgradePage", "UpgradePage"],
			["MissionsPage", "MissionsPage"], ["ShopPage", "ShopPage"]]:
		_instance(pages, "res://Scene/Menus/Pages/%s.tscn" % pg[0], pg[1], true)
	# Top bar
	var top := MarginContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in ["left", "right", "bottom"]:
		top.add_theme_constant_override("margin_" + side, 16)
	top.add_theme_constant_override("margin_top", 16)
	_add(root, top, "TopBar", true)
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	var tb := _box(false, top, "Row", 10)
	tb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for k in ["gold", "shards", "gems"]:
		var pill := _instance(tb, "res://Scene/UI/Components/CurrencyPill.tscn", k.capitalize() + "Pill") as CurrencyPill
		pill.kind = k
	_spacer(tb)
	var st := _btn(tb, "SettingsButton", "", "ButtonRound", Vector2(84, 84), true, "icon_settings.png")
	st.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	# Tab bar
	var bar := Control.new()
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_add(root, bar, "TabBar")
	bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bar.offset_top = -180.0
	var bar_bg := _tex(bar, "Background", "tabbar.png", Vector2.ZERO, false, TextureRect.STRETCH_SCALE)
	_full(bar_bg)
	var tm := MarginContainer.new()
	tm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tm.add_theme_constant_override("margin_left", 14)
	tm.add_theme_constant_override("margin_right", 14)
	tm.add_theme_constant_override("margin_top", 22)
	tm.add_theme_constant_override("margin_bottom", 10)
	_add(bar, tm, "Margin")
	_full(tm)
	var tabs := _box(false, tm, "Tabs", 6)
	tabs.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var group := ButtonGroup.new()
	for t in [["TabSoldiers", "SOLDIERS", "icon_soldiers.png"], ["TabUpgrades", "UPGRADES", "icon_upgrade.png"],
			["TabHome", "PLAY", "icon_play.png"], ["TabMissions", "MISSIONS", "icon_missions.png"], ["TabShop", "SHOP", "icon_shop.png"]]:
		var b := _btn(tabs, t[0], t[1], "TabButton", Vector2(0, 140), true, t[2])
		b.toggle_mode = true
		b.button_group = group
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if t[0] == "TabHome":
			b.button_pressed = true
	# Toast + popup layer
	var toast := _lbl(root, "Toast", "", "LabelSmall", true, HORIZONTAL_ALIGNMENT_CENTER)
	toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	toast.offset_top = -280.0
	toast.offset_bottom = -190.0
	toast.offset_left = 30.0
	toast.offset_right = -30.0
	var popups := Control.new()
	popups.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_add(root, popups, "Popups", true)
	_full(popups)
	_save(root, "res://Scene/Menus/MainMenu.tscn")


func _loading() -> void:
	var root := Control.new()
	root.name = "Loading"
	root.set_script(load("res://Scripts/UI/Loading.gd"))
	_begin(root)
	_full(root)
	_full(_tex(root, "Background", "bg_loading.png", Vector2.ZERO, false, TextureRect.STRETCH_KEEP_ASPECT_COVERED))
	var logo := _tex(root, "Logo", "logo.png", Vector2(560, 280))
	logo.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	logo.offset_left = -280.0
	logo.offset_right = 280.0
	logo.offset_top = 80.0
	logo.offset_bottom = 360.0
	var box := _box(true, root, "Bottom", 10)
	box.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	box.offset_left = 60.0
	box.offset_right = -60.0
	box.offset_top = -190.0
	box.offset_bottom = -90.0
	_lbl(box, "Label", "LOADING...", "LabelBig", false, HORIZONTAL_ALIGNMENT_CENTER)
	var bar := _bar(box, "Bar", "yellow", Vector2(0, 44), true)
	bar.value = 0.0
	_save(root, "res://Scene/Menus/Loading.tscn")


func _hud() -> void:
	var layer := CanvasLayer.new()
	layer.name = "HUD"
	layer.set_script(load("res://Scripts/UI/HUD.gd"))
	_r = layer
	var root := Control.new()
	_add(layer, root, "Root")
	root.theme = _theme
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_full(root)
	var tm := MarginContainer.new()
	tm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in ["left", "right", "bottom"]:
		tm.add_theme_constant_override("margin_" + side, 16)
	tm.add_theme_constant_override("margin_top", 14)
	_add(root, tm, "TopMargin", true)
	_full(tm)
	var col := _box(true, tm, "Column", 10)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var top := _box(false, col, "TopRow", 12)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var res := _panel(top, "Resources", "PanelDark")
	res.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rv := _box(true, res, "Rows", 0)
	for r in [["Gold", "icon_gold.png", "GoldLabel"], ["Shards", "icon_shard.png", "ShardLabel"], ["Kills", "icon_trophy.png", "KillsLabel"]]:
		var row := _box(false, rv, r[0] + "Row", 8)
		_tex(row, "Icon", r[1], Vector2(34, 34))
		_lbl(row, r[2], "0", "LabelSmall", true)
	var army := _box(true, top, "Army", 2)
	army.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	army.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lbl(army, "ArmyLabel", "ARMY  0", "LabelBig", true, HORIZONTAL_ALIGNMENT_CENTER)
	_bar(army, "ArmyBar", "green", Vector2(0, 38), true)
	var buffs := _lbl(army, "BuffsLabel", "DMG +0%   RATE +0%", "LabelSmall", true, HORIZONTAL_ALIGNMENT_CENTER)
	buffs.add_theme_color_override("font_color", Color(1.0, 0.82, 0.4))
	var pause := _btn(top, "PauseButton", "", "ButtonRound", Vector2(84, 84), true, "icon_pause.png")
	pause.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_bar(col, "ProgressBar", "yellow", Vector2(0, 26), true).value = 0.0
	var boss := _panel(col, "BossPanel", "PanelDark", Vector2.ZERO, true)
	boss.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bv := _box(true, boss, "Rows", 2)
	var bn := _lbl(bv, "BossName", "BOSS", "LabelBig", true, HORIZONTAL_ALIGNMENT_CENTER)
	bn.add_theme_color_override("font_color", Color(1.0, 0.35, 0.3))
	_bar(bv, "BossBar", "red", Vector2(0, 40), true)
	# Banner
	var banner := _lbl(root, "Banner", "", "LabelTitle", true, HORIZONTAL_ALIGNMENT_CENTER)
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.add_theme_font_size_override("font_size", 84)
	banner.anchor_left = 0.0
	banner.anchor_right = 1.0
	banner.anchor_top = 0.24
	banner.anchor_bottom = 0.36
	banner.offset_left = 0.0
	banner.offset_right = 0.0
	banner.offset_top = 0.0
	banner.offset_bottom = 0.0
	# Pause / result overlay
	var ov := ColorRect.new()
	ov.color = Color(0, 0, 0, 0.72)
	_add(root, ov, "Overlay", true)
	_full(ov)
	var c := CenterContainer.new()
	_add(ov, c, "Center")
	_full(c)
	var p := _panel(c, "Panel", "PanelPopup", Vector2(600, 0))
	var v := _box(true, p, "Content", 16)
	_lbl(v, "Title", "PAUSED", "LabelTitle", true, HORIZONTAL_ALIGNMENT_CENTER)
	var stats := _lbl(v, "Stats", "", "", true, HORIZONTAL_ALIGNMENT_CENTER)
	stats.add_theme_font_size_override("font_size", 36)
	_btn(v, "PrimaryButton", "RESUME", "ButtonPrimary", Vector2(0, 110), true)
	_btn(v, "SecondaryButton", "RESTART", "ButtonGold", Vector2(0, 96), true)
	_btn(v, "TertiaryButton", "HOME", "ButtonSecondary", Vector2(0, 96), true)
	_save(layer, "res://Scene/UI/HUD.tscn")

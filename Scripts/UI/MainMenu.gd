class_name MainMenu
extends Control
## Main menu shell (scene: Scene/Menus/MainMenu.tscn): background, currency
## bar, bottom tab bar and the pages / popups it hosts.

const BG_HOME := preload("res://Assets/UI/bg_main_menu.png")
const BG_PAGE := preload("res://Assets/UI/bg_menu_generic.png")
const SETTINGS_POPUP := preload("res://Scene/Menus/Popups/SettingsPopup.tscn")
const DETAIL_POPUP := preload("res://Scene/Menus/Popups/UnitDetailPopup.tscn")
const COACH_SCENE := preload("res://Scene/UI/TutorialCoach.tscn")

@onready var _bg: TextureRect = %Background
@onready var _popups: Control = %Popups
@onready var _toast: Label = %Toast
@onready var _top_bar: MarginContainer = %TopBar
@onready var _pages: Dictionary = {
	&"soldiers": %SoldiersPage, &"upgrades": %UpgradePage, &"home": %HomePage,
	&"missions": %MissionsPage, &"shop": %ShopPage,
}

var _toast_tween: Tween = null


func _ready() -> void:
	_top_bar.add_theme_constant_override("margin_top", 16 + _safe_top())
	%TabSoldiers.pressed.connect(show_page.bind(&"soldiers"))
	%TabUpgrades.pressed.connect(show_page.bind(&"upgrades"))
	%TabHome.pressed.connect(show_page.bind(&"home"))
	%TabMissions.pressed.connect(show_page.bind(&"missions"))
	%TabShop.pressed.connect(show_page.bind(&"shop"))
	%SettingsButton.pressed.connect(_open_settings)
	%HomePage.play_pressed.connect(Game.goto_battle)
	%HomePage.toast_requested.connect(toast)
	%MissionsPage.toast_requested.connect(toast)
	%ShopPage.toast_requested.connect(toast)
	%SoldiersPage.soldier_selected.connect(_open_detail)
	_toast.modulate.a = 0.0
	show_page(&"home")
	AudioManager.play_music()
	if Game.coach_pending:
		Game.coach_pending = false
		start_coach.call_deferred()


func _safe_top() -> int:
	var win := DisplayServer.window_get_size()
	if win.y <= 0:
		return 0
	var safe := DisplayServer.get_display_safe_area()
	var vp := get_viewport().get_visible_rect().size
	return int(float(safe.position.y) * vp.y / float(win.y))


func show_page(page: StringName) -> void:
	for key in _pages:
		(_pages[key] as Control).visible = key == page
	_bg.texture = BG_HOME if page == &"home" else BG_PAGE
	AudioManager.play("ui_click")


## Dims the screen and walks the player through the home screen (after the first tutorial, or from HOW TO PLAY).
func start_coach() -> void:
	show_page(&"home")
	var coach := COACH_SCENE.instantiate() as TutorialCoach
	add_child(coach)
	coach.start(self)


func _open_settings() -> void:
	AudioManager.play("ui_click")
	_popups.add_child(SETTINGS_POPUP.instantiate())


func _open_detail(type: int) -> void:
	var popup := DETAIL_POPUP.instantiate() as UnitDetailPopup
	popup.setup(type)
	_popups.add_child(popup)


func toast(text: String) -> void:
	_toast.text = text
	if _toast_tween != null:
		_toast_tween.kill()
	_toast.modulate.a = 1.0
	_toast_tween = create_tween()
	_toast_tween.tween_interval(1.8)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.4)

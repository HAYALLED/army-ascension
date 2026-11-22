class_name ShopItem
extends PanelContainer
## Shop card (scene: Scene/UI/Components/ShopItem.tscn). Texts and icon are
## set in the inspector. Purchases are MOCKED: the signal only reports the click.

signal buy(item_id: String)

@export var item_id: String = ""
@export var title: String = "GOLD"
@export var amount_text: String = "x500"
@export var price_text: String = "$0.99"
@export var icon: Texture2D = null
@export_enum("ButtonGold", "ButtonPrimary", "ButtonSecondary") var button_style: String = "ButtonGold"

@onready var _title: Label = %TitleLabel
@onready var _icon: TextureRect = %Icon
@onready var _amount: Label = %AmountLabel
@onready var _button: Button = %BuyButton


func _ready() -> void:
	_title.text = title
	_icon.texture = icon
	_amount.text = amount_text
	_amount.visible = amount_text != ""
	_button.text = price_text
	_button.theme_type_variation = button_style
	_button.pressed.connect(func() -> void:
		AudioManager.play("ui_click")
		buy.emit(item_id))


## Replaces the buy button text; a disabled button (OWNED, SOON) uses the gray style.
func set_button(text: String, disabled: bool) -> void:
	_button.text = text
	_button.disabled = disabled
	_button.theme_type_variation = &"ButtonDisabled" if disabled else StringName(button_style)

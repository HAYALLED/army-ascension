class_name ShopOffer
extends PanelContainer
## Wide shop offer (ad reward, starter bundle). Same fields as ShopItem.
## Purchases are MOCKED in dev.

signal buy(item_id: String)

@export var item_id: String = ""
@export var title: String = "OFFER"
@export var description: String = ""
@export var price_text: String = "$2.99"
@export var icon: Texture2D = null
@export_enum("ButtonGold", "ButtonPrimary", "ButtonSecondary") var button_style: String = "ButtonGold"

@onready var _title: Label = %TitleLabel
@onready var _desc: Label = %DescLabel
@onready var _icon: TextureRect = %Icon
@onready var _button: Button = %BuyButton


func _ready() -> void:
	_title.text = title
	_desc.text = description
	_icon.texture = icon
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

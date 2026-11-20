class_name CurrencyPill
extends PanelContainer
## Top-bar currency counter. Pick the wallet value in the inspector.

@export_enum("gold", "shards", "gems") var kind: String = "gold"

const ICONS := {
	"gold": "res://Assets/UI/icon_gold.png",
	"shards": "res://Assets/UI/icon_shard.png",
	"gems": "res://Assets/UI/icon_gem.png",
}

@onready var _value: Label = %Value
@onready var _icon: TextureRect = %Icon


func _ready() -> void:
	_icon.texture = load(ICONS[kind])
	PlayerData.wallet_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	match kind:
		"gold":
			_value.text = str(PlayerData.gold)
		"shards":
			_value.text = str(PlayerData.total_shards())
		"gems":
			_value.text = str(PlayerData.gems)

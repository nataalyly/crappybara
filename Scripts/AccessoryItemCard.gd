extends PanelContainer

signal action_pressed(data: AccessoryData)

@onready var icon_rect: TextureRect = $CardVBox/IconRect
@onready var name_label: Label = $CardVBox/NameLabel
@onready var action_button: Button = $CardVBox/ActionButton

var data: AccessoryData

func _ready() -> void:
	action_button.pressed.connect(func(): action_pressed.emit(data))
	ButtonFX.apply_bounce(action_button)

func setup(item: AccessoryData) -> void:
	data = item
	icon_rect.texture = item.icon if item.icon != null else item.texture
	name_label.text = item.accessory_name
	refresh()

func refresh() -> void:
	if GameState.is_accessory_equipped(data):
		action_button.text = "Unequip"
	elif GameState.is_accessory_owned(data):
		action_button.text = "Equip"
	else:
		action_button.text = "Buy %d" % data.price

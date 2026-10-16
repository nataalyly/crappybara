extends Resource
class_name AccessoryData

@export var accessory_name: String = ""
@export_enum("Head", "Eyewear", "Body") var slot: String = "Head"
@export var texture: Texture2D
@export var icon: Texture2D
@export var price: int = 3

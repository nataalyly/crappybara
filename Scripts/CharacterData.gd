extends Resource
class_name CharacterData

@export var character_name: String = ""
@export var description: String = ""
@export_enum("common", "rare", "epic", "legendary") var rarity: String = ""

@export var eyes_open_texture: Texture2D
@export var eyes_closed_texture: Texture2D
@export var mouth_open_texture: Texture2D
@export var chew_texture_1: Texture2D
@export var chew_texture_2: Texture2D

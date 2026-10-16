extends TextureButton

signal card_pressed(character_id: String)

var character_id: String

func setup(id: String, data: CharacterData) -> void:
	character_id = id
	texture_normal = data.eyes_open_texture
	pressed.connect(func(): card_pressed.emit(character_id))
	ButtonFX.apply_bounce(self)

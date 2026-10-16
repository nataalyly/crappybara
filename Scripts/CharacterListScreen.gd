extends Control

const CHARACTER_CARD_SCENE := preload("res://Scenes/CharacterCard.tscn")
const CHARACTER_DETAIL_SCENE := preload("res://Scenes/CharacterDetailPopup.tscn")

@onready var dim_background: ColorRect = $DimBackground
@onready var list_panel: Panel = $ListPanel
@onready var character_grid: GridContainer = $ListPanel/ScrollContainer/CharacterGrid
@onready var close_button: TextureButton = $ListPanel/CloseButton

func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)
	ButtonFX.apply_bounce(close_button)
	_populate_character_list()

func _populate_character_list() -> void:
	for id in GameState.owned_character_ids.keys():
		var data: CharacterData = GameState.get_character_data_by_id(id)

		var card: TextureButton = CHARACTER_CARD_SCENE.instantiate()
		character_grid.add_child(card)
		card.setup(id, data)
		card.card_pressed.connect(_on_card_pressed)

func _on_card_pressed(character_id: String) -> void:
	dim_background.visible = false
	list_panel.visible = false

	var detail_instance: Control = CHARACTER_DETAIL_SCENE.instantiate()
	add_child(detail_instance)
	detail_instance.setup(character_id)
	detail_instance.closed.connect(_on_detail_closed)
	detail_instance.character_chosen.connect(queue_free)

func _on_detail_closed() -> void:
	dim_background.visible = true
	list_panel.visible = true

func _on_close_pressed() -> void:
	queue_free()

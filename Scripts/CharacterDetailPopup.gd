extends Control

signal character_chosen
signal closed

@onready var detail_portrait: TextureRect = $DetailPanel/MainVBox/ContentRow/LeftBox/LeftBoxContent/DetailPortrait
@onready var detail_level_label: Label = $DetailPanel/MainVBox/ContentRow/LeftBox/LeftBoxContent/LevelLabel
@onready var detail_xp_bar: ProgressBar = $DetailPanel/MainVBox/ContentRow/LeftBox/LeftBoxContent/XP_Bar
@onready var detail_xp_label: Label = $DetailPanel/MainVBox/ContentRow/LeftBox/LeftBoxContent/XP_Bar/XP_Value

@onready var detail_name_label: Label = $DetailPanel/MainVBox/HeaderBox/DetailNameLabel
@onready var detail_rarity_label: Label = $DetailPanel/MainVBox/HeaderBox/DetailRarityLabel

@onready var detail_description_label: Label = $DetailPanel/MainVBox/ContentRow/RightBox/RightBoxContent/DetailDescriptionLabel
@onready var choose_button: BaseButton = $DetailPanel/MainVBox/ContentRow/RightBox/RightBoxContent/ChooseButton

@onready var close_button: TextureButton = $DetailPanel/CloseButton

var character_id: String

func _ready() -> void:
	choose_button.pressed.connect(_on_choose_pressed)
	close_button.pressed.connect(_on_close_pressed)
	ButtonFX.apply_bounce(choose_button)
	ButtonFX.apply_bounce(close_button)

func setup(id: String) -> void:
	character_id = id
	var data: CharacterData = GameState.get_character_data_by_id(id)
	var progress: Dictionary = GameState.character_progress.get(id, {})
	var level: int = progress.get("level", 1)
	var current_xp: int = progress.get("current_xp", 0)
	var xp_needed: int = GameState.get_xp_required(data.rarity, level)

	detail_portrait.texture = data.eyes_open_texture
	detail_name_label.text = data.character_name
	detail_rarity_label.text = data.rarity.capitalize()
	detail_description_label.text = data.description
	detail_level_label.text = "Lv. %d" % level

	detail_xp_bar.max_value = xp_needed
	detail_xp_bar.value = current_xp
	detail_xp_label.text = "%d/%d" % [current_xp, xp_needed]

	var is_active: bool = (id == GameState.active_character_id)
	choose_button.visible = not is_active

func _on_choose_pressed() -> void:
	GameState.active_character_id = character_id
	character_chosen.emit()
	queue_free()

func _on_close_pressed() -> void:
	closed.emit()
	queue_free()

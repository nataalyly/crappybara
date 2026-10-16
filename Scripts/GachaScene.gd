extends Control
signal gold_changed

@onready var pull_choice_popup: Panel = $PullChoicePopup
@onready var pull_1x_button: TextureButton = $PullChoicePopup/Pull1xButton
@onready var pull_10x_button: TextureButton = $PullChoicePopup/Pull10xButton
@onready var close_button: TextureButton = $PullChoicePopup/CloseButton

@onready var result_layer: Control = $ResultLayer
@onready var glow_effect: TextureRect = $ResultLayer/ResultCard/PotraitWrapper/GlowEffect
@onready var character_portrait: TextureRect = $ResultLayer/ResultCard/PotraitWrapper/CharacterPotrait
@onready var rarity_label: Label = $ResultLayer/ResultCard/RarityLabel
@onready var pull_status_label: Label = $ResultLayer/ResultCard/PullStatusLabel
@onready var character_name_label: Label = $ResultLayer/ResultCard/InfoBox/InfoBoxContent/CharacterNameLabel
@onready var character_description_label: Label = $ResultLayer/ResultCard/InfoBox/InfoBoxContent/CharacterDescriptionLabel
@onready var tap_to_continue_label: Label = $ResultLayer/ResultCard/TapContinueLabel

@onready var insufficient_gold_toast: PanelContainer = $PullChoicePopup/InsufficientGoldToast
@onready var ticket_bonus_label: Label = $ResultLayer/ResultCard/PotraitWrapper/BonusList/TicketBonusLabel
@onready var gold_bonus_label: Label = $ResultLayer/ResultCard/PotraitWrapper/BonusList/GoldBonusLabel

var continue_hint_tween: Tween
const PULL_1X_COST: int = 5
const PULL_10X_COST: int = 50
const DUPLICATE_TRADE_GOLD: int = 2

const RARITY_COLORS := {
	"common": Color(0.8, 0.8, 0.8),
	"rare": Color(0.3, 0.5, 1.0),
	"epic": Color(0.7, 0.3, 1.0),
	"legendary": Color(1.0, 0.8, 0.1),
}

var pending_results: Array[Dictionary] = []
var current_result_index: int = 0
var glow_tween: Tween

func _ready() -> void:
	pull_1x_button.pressed.connect(_on_pull_1x_pressed)
	pull_10x_button.pressed.connect(_on_pull_10x_pressed)
	close_button.pressed.connect(_on_close_pressed)
	result_layer.gui_input.connect(_on_result_layer_input)
	
	ButtonFX.apply_bounce(pull_1x_button)
	ButtonFX.apply_bounce(pull_10x_button)
	ButtonFX.apply_bounce(close_button)

	pull_choice_popup.visible = true
	result_layer.visible = false
	insufficient_gold_toast.visible = false

func _on_pull_1x_pressed() -> void:
	if GameState.gold < PULL_1X_COST:
		_show_insufficient_gold_toast()
		return
	GameState.gold -= PULL_1X_COST

	pending_results = [_roll_pull()]
	gold_changed.emit()
	_start_result_sequence()

func _on_pull_10x_pressed() -> void:
	if GameState.gold < PULL_10X_COST:
		_show_insufficient_gold_toast()
		return
	GameState.gold -= PULL_10X_COST

	pending_results.clear()
	for i in range(10):
		pending_results.append(_roll_pull())
	gold_changed.emit()
	_start_result_sequence()

func _show_insufficient_gold_toast() -> void:
	var toast: PanelContainer = insufficient_gold_toast.duplicate()
	toast.visible = true
	toast.modulate = Color(1, 1, 1, 1)
	pull_choice_popup.add_child(toast)

	var start_pos: Vector2 = toast.position
	toast.position = start_pos + Vector2(0, 20)

	var fade_tween := create_tween()

	fade_tween.set_parallel(true)
	fade_tween.tween_property(toast, "position", start_pos, 0.15).set_trans(Tween.TRANS_SINE)
	fade_tween.tween_property(toast, "modulate:a", 1.0, 0.15).from(0.0)

	fade_tween.chain().tween_interval(0.5)

	fade_tween.set_parallel(true)
	fade_tween.tween_property(toast, "position", start_pos - Vector2(0, 30), 0.8).set_trans(Tween.TRANS_SINE)
	fade_tween.tween_property(toast, "modulate:a", 0.0, 0.8)

	fade_tween.chain().tween_callback(toast.queue_free)

	var shake_tween := create_tween()
	var original_pos: Vector2 = pull_choice_popup.position
	shake_tween.tween_property(pull_choice_popup, "position", original_pos + Vector2(10, 0), 0.05)
	shake_tween.tween_property(pull_choice_popup, "position", original_pos - Vector2(10, 0), 0.05)
	shake_tween.tween_property(pull_choice_popup, "position", original_pos + Vector2(6, 0), 0.05)
	shake_tween.tween_property(pull_choice_popup, "position", original_pos, 0.05)

func _start_result_sequence() -> void:
	current_result_index = 0
	pull_choice_popup.visible = false
	result_layer.visible = true
	_show_current_result()

func _roll_pull() -> Dictionary:
	GameState.pulls_since_legendary += 1

	var rarity: String
	if GameState.pulls_since_legendary >= 50:
		rarity = "legendary"
		GameState.pulls_since_legendary = 0
	else:
		var roll: float = randf_range(0, 100)
		if roll <= 60:
			rarity = "common"
		elif roll <= 90:
			rarity = "rare"
		elif roll <= 98:
			rarity = "epic"
		else:
			rarity = "legendary"

		if rarity == "legendary":
			GameState.pulls_since_legendary = 0

	return _resolve_pull_result(rarity)

func _resolve_pull_result(rarity: String) -> Dictionary:
	var candidates: Array[CharacterData] = GameState.get_characters_by_rarity(rarity)

	var fallback_order: Array[String] = ["legendary", "epic", "rare", "common"]
	var i: int = fallback_order.find(rarity)
	while candidates.is_empty() and i < fallback_order.size() - 1:
		i += 1
		candidates = GameState.get_characters_by_rarity(fallback_order[i])

	var chosen: CharacterData = candidates[randi() % candidates.size()]
	var id: String = chosen.resource_path
	var is_duplicate: bool = GameState.owned_character_ids.has(id)

	if is_duplicate:
		GameState.gold += DUPLICATE_TRADE_GOLD
	else:
		GameState._add_owned_character(chosen)

	var got_ticket: bool = randf_range(0, 100) <= 40
	if got_ticket:
		GameState.tickets += 1

	return {
		"character": chosen,
		"is_duplicate": is_duplicate,
		"got_ticket": got_ticket,
	}

func _show_current_result() -> void:
	var result: Dictionary = pending_results[current_result_index]
	var character: CharacterData = result["character"]

	character_portrait.texture = character.eyes_open_texture
	character_name_label.text = character.character_name
	character_description_label.text = character.description
	rarity_label.text = character.rarity.capitalize()
	AudioManager.play_gacha_sfx(character.rarity)
	
	if result["is_duplicate"]:
		pull_status_label.text = "DUPLICATE"
		pull_status_label.modulate = Color(1.0, 0.417, 0.186, 1.0)
	else:
		pull_status_label.text = "NEW CHARACTER!"
		pull_status_label.modulate = Color(1.0, 0.785, 0.0)

	var rarity_color: Color = RARITY_COLORS.get(character.rarity, Color.WHITE)
	rarity_label.modulate = rarity_color
	glow_effect.modulate = rarity_color

	var result_card: Control = $ResultLayer/ResultCard
	result_card.pivot_offset = result_card.size / 2
	result_card.scale = Vector2(0.3, 0.3)
	result_card.modulate.a = 0.0

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(result_card, "scale", Vector2(1.0, 1.0), 0.35).set_trans(Tween.TRANS_BACK)
	tween.tween_property(result_card, "modulate:a", 1.0, 0.2)
	
	glow_effect.pivot_offset = glow_effect.size / 2
	
	if glow_tween:
		glow_tween.kill()
	glow_tween = create_tween()
	glow_tween.set_loops()
	glow_tween.tween_property(glow_effect, "rotation_degrees", 360.0, 4.0).from(0.0)
	
	ticket_bonus_label.visible = result["got_ticket"]
	gold_bonus_label.visible = result["is_duplicate"]
	if result["is_duplicate"]:
		gold_bonus_label.text = "BONUS +%d Gold" % DUPLICATE_TRADE_GOLD
	
	if continue_hint_tween:
		continue_hint_tween.kill()
	tap_to_continue_label.modulate.a = 1.0
	continue_hint_tween = create_tween()
	continue_hint_tween.set_loops()
	continue_hint_tween.tween_property(tap_to_continue_label, "modulate:a", 0.2, 0.6).set_trans(Tween.TRANS_SINE)
	continue_hint_tween.tween_property(tap_to_continue_label, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE)

func _on_result_layer_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		current_result_index += 1
		if current_result_index >= pending_results.size():
			_end_result_sequence()
		else:
			_show_current_result()

func _end_result_sequence() -> void:
	if glow_tween:
		glow_tween.kill()
	if continue_hint_tween:
		continue_hint_tween.kill()
	result_layer.visible = false
	pending_results.clear()
	pull_choice_popup.visible = true

func _on_close_pressed() -> void:
	queue_free()

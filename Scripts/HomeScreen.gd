extends Control

# --- Referensi node (disesuaikan sama struktur scene kita) ---
@onready var gold_label: Label = $CurrencyContainer/GoldDisplay/GoldRow/GoldLabel
@onready var ticket_label: Label = $CurrencyContainer/TicketDisplay/TicketRow/TicketLabel

@onready var energy_bar: TextureProgressBar = $CharacterArea/CharacterRow/EnergyBarWrapper/EnergyBar
@onready var energy_percent_label: Label = $CharacterArea/CharacterRow/EnergyBarWrapper/EnergyBar/PercentLabel

@onready var xp_bar: ProgressBar = $CharacterArea/XP_Row/XP_Bar
@onready var xp_value_label: Label = $CharacterArea/XP_Row/XP_Bar/XP_Value
@onready var level_label: Label = $CharacterArea/XP_Row/LevelLabel

# --- Texture 4 tahap energy bar (drag PNG dari Inspector nanti) ---
@export var energy_sad_texture: Texture2D
@export var energy_poker_texture: Texture2D
@export var energy_normal_texture: Texture2D
@export var energy_happy_texture: Texture2D

@onready var character_display: TextureRect = $CharacterArea/CharacterRow/CharacterDisplay
@onready var blink_timer: Timer = $CharacterArea/CharacterRow/CharacterDisplay/BlinkTimer

@onready var food_display: TextureRect = $CharacterArea/CharacterRow/CharacterDisplay/FoodDisplay
@onready var mouth_drop_zone: Control = $CharacterArea/CharacterRow/CharacterDisplay/MouthDropZone
@onready var eat_timer: Timer = $CharacterArea/CharacterRow/CharacterDisplay/EatTimer

@export var peach_stages: Array[Texture2D] = []
@export var corn_stages: Array[Texture2D] = []
@export var watermelon_stages: Array[Texture2D] = []
@export var bite_interval: float = 0.6

@onready var menu_popup: Panel = $MenuPopup
@onready var menu_button: TextureButton = $TopLeftButtons/MenuButton
@onready var close_button: TextureButton = $MenuPopup/CloseButton
@onready var door_button: TextureButton = $Background/DoorButton
@onready var feed_button: TextureButton = $CharacterArea/CharacterRow/FeedButton
@onready var shop_button: TextureButton = $MenuPopup/MenuButtonList/ShopButton
@onready var settings_button: TextureButton = $MenuPopup/MenuButtonList/SettingsButton
@onready var accessories_button: TextureButton = $MenuPopup/MenuButtonList/AccessoriesButton
@onready var inventory_button: TextureButton = $MenuPopup/MenuButtonList/InventoryButton

@onready var hungry_warning_toast: PanelContainer = $HungryWarningToast
@onready var hungry_warning_label: Label = $HungryWarningToast/HungryWarningLabel
@onready var coming_soon_toast: PanelContainer = $ComingSoonToast

@onready var gacha_button: TextureButton = $MenuPopup/MenuButtonList/GachaButton
@onready var popup_layer: Control = $PopupLayer
const GACHA_SCENE := preload("res://Scenes/GachaScene.tscn")

@onready var character_button: TextureButton = $MenuPopup/MenuButtonList/CharacterButton
const CHARACTER_LIST_SCENE := preload("res://Scenes/CharacterListScreen.tscn")

const ACCESSORY_SIDEBAR_SCENE := preload("res://Scenes/AccessorySidebar.tscn")
const CHARACTER_SHIFT_X: float = 350.0

@onready var character_area: Control = $CharacterArea
@onready var energy_bar_wrapper: Control = $CharacterArea/CharacterRow/EnergyBarWrapper
var hud_tween: Tween

@onready var accessory_layer: AccessoryLayer = $CharacterArea/CharacterRow/CharacterDisplay/AccessoryLayer
var accessories_mode: bool = false
var character_area_rest_x: float = 0.0
var shift_tween: Tween

enum FeedState { NONE, ACTIVE }
var feed_state: int = FeedState.NONE
var food_spawn_position: Vector2
var current_food_stages: Array[Texture2D] = []
var current_food_stage_index: int = 0
var is_holding_to_eat: bool = false
var last_feed_sfx_time: int = -999999

var active_data: CharacterData
var is_swapping: bool = false

func _ready() -> void:
	update_currency_display()
	update_energy_display()
	update_xp_display()
	_load_character_textures()
	blink_timer.timeout.connect(_on_blink_timer_timeout)
	_randomize_blink_timer()
	
	food_spawn_position = food_display.position
	food_display.visible = false
	food_display.gui_input.connect(_on_food_gui_input)
	eat_timer.timeout.connect(_on_eat_timer_timeout)
	$CharacterArea/CharacterRow/FeedButton.pressed.connect(_on_feed_button_pressed)
	
	menu_button.pressed.connect(_on_menu_button_pressed)
	close_button.pressed.connect(_on_close_button_pressed)
	door_button.pressed.connect(_on_door_button_pressed)
	gacha_button.pressed.connect(_on_gacha_button_pressed)
	character_button.pressed.connect(_on_character_button_pressed)
	shop_button.pressed.connect(_show_coming_soon)
	settings_button.pressed.connect(_show_coming_soon)
	accessories_button.pressed.connect(_on_accessories_button_pressed)
	inventory_button.pressed.connect(_show_coming_soon)
	
	ButtonFX.apply_bounce(feed_button)
	ButtonFX.apply_bounce(door_button)
	ButtonFX.apply_bounce(menu_button)
	ButtonFX.apply_bounce(close_button)
	ButtonFX.apply_bounce(gacha_button)
	ButtonFX.apply_bounce(character_button)
	ButtonFX.apply_bounce(shop_button)
	ButtonFX.apply_bounce(settings_button)
	ButtonFX.apply_bounce(accessories_button)
	ButtonFX.apply_bounce(inventory_button)

func _on_feed_button_pressed() -> void:
	if accessories_mode:
		return
		
	if is_swapping:
		return
	
	if feed_state != FeedState.NONE:
		return
	
	var food_options := [peach_stages, corn_stages, watermelon_stages]
	current_food_stages = food_options[randi() % food_options.size()]
	current_food_stage_index = 0

	food_display.texture = current_food_stages[0]
	food_display.position = food_spawn_position
	food_display.visible = true
	feed_state = FeedState.ACTIVE
	
	blink_timer.stop()
	character_display.texture = active_data.mouth_open_texture

func _on_food_gui_input(event: InputEvent) -> void:
	if feed_state != FeedState.ACTIVE:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_update_mouth_overlap()
		else:
			_stop_eating()

	elif event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		food_display.position += event.relative
		_update_mouth_overlap()

func _update_mouth_overlap() -> void:
	var overlapping: bool = food_display.get_global_rect().intersects(mouth_drop_zone.get_global_rect())

	if overlapping and not is_holding_to_eat:
		_start_eating()
	elif not overlapping and is_holding_to_eat:
		_stop_eating()

func _start_eating() -> void:
	is_holding_to_eat = true
	_update_chew_expression()
	eat_timer.start(bite_interval)
	
	var now: int = Time.get_ticks_msec()
	if now - last_feed_sfx_time >= 2000:
		AudioManager.play_sfx(AudioManager.sfx_feed_bite)
		last_feed_sfx_time = now

func _stop_eating() -> void:
	is_holding_to_eat = false
	eat_timer.stop()
	character_display.texture = active_data.mouth_open_texture

func _update_chew_expression() -> void:
	if current_food_stage_index % 2 == 0:
		character_display.texture = active_data.chew_texture_1
	else:
		character_display.texture = active_data.chew_texture_2

func _on_eat_timer_timeout() -> void:
	if not is_holding_to_eat:
		return

	current_food_stage_index += 1
	
	var energy_per_bite: float = 35.0 / current_food_stages.size()
	GameState.add_energy(energy_per_bite)
	update_energy_display()

	if current_food_stage_index >= current_food_stages.size():
		_finish_feeding()
	else:
		food_display.texture = current_food_stages[current_food_stage_index]
		_update_chew_expression()
		eat_timer.start(bite_interval)

func _finish_feeding() -> void:
	food_display.visible = false
	feed_state = FeedState.NONE
	is_holding_to_eat = false
	character_display.texture = active_data.eyes_open_texture
	_randomize_blink_timer()

	GameState.grant_feed_reward()
	update_currency_display()

func _load_character_textures() -> void:
	active_data = GameState.get_active_character()
	if active_data == null:
		return
	character_display.texture = active_data.eyes_open_texture

func _on_menu_button_pressed() -> void:
	if accessories_mode:
		return
		
	menu_popup.visible = true

func _on_close_button_pressed() -> void:
	menu_popup.visible = false

func _on_door_button_pressed() -> void:
	if accessories_mode:
		return
		
	if not GameState.can_battle():
		_show_hungry_warning()
		return
	get_tree().change_scene_to_file("res://Scenes/BattleScene.tscn")

func _show_hungry_warning() -> void:
	var toast: PanelContainer = hungry_warning_toast.duplicate()
	toast.visible = true
	toast.modulate = Color(1, 1, 1, 1)
	add_child(toast)

	var label: Label = toast.get_node("HungryWarningLabel")
	label.text = "%s is hungry!" % active_data.character_name

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
	var original_pos: Vector2 = door_button.position
	shake_tween.tween_property(door_button, "position", original_pos + Vector2(10, 0), 0.05)
	shake_tween.tween_property(door_button, "position", original_pos - Vector2(10, 0), 0.05)
	shake_tween.tween_property(door_button, "position", original_pos + Vector2(6, 0), 0.05)
	shake_tween.tween_property(door_button, "position", original_pos, 0.05)

func _on_blink_timer_timeout() -> void:
	if active_data.eyes_open_texture == null or active_data.eyes_closed_texture == null:
		_randomize_blink_timer()
		return

	character_display.texture = active_data.eyes_closed_texture
	await get_tree().create_timer(0.15).timeout
	character_display.texture = active_data.eyes_open_texture
	_randomize_blink_timer()

func _randomize_blink_timer() -> void:
	blink_timer.wait_time = randf_range(2.0, 5.0)
	blink_timer.start()

func update_currency_display() -> void:
	gold_label.text = str(GameState.gold)
	ticket_label.text = str(GameState.tickets)

func update_energy_display() -> void:
	var value: float = GameState.energy
	energy_bar.value = value
	energy_percent_label.text = "%d%%" % value

	var stage_texture: Texture2D
	if value <= 25:
		stage_texture = energy_sad_texture
	elif value <= 50:
		stage_texture = energy_poker_texture
	elif value <= 75:
		stage_texture = energy_normal_texture
	else:
		stage_texture = energy_happy_texture

	energy_bar.texture_under = stage_texture
	energy_bar.texture_progress = stage_texture
	energy_bar.tint_under = Color(0.4, 0.4, 0.4)
	energy_bar.tint_progress = Color(1, 1, 1)

func refresh_character_display() -> void:
	_load_character_textures()
	current_food_stages.clear()
	feed_state = FeedState.NONE
	food_display.visible = false
	update_energy_display()
	update_xp_display()

func update_xp_display() -> void:
	var character: CharacterData = GameState.get_active_character()
	if character == null:
		return
	
	var progress: Dictionary = GameState.get_active_progress()
	var level: int = progress.get("level", 1)
	var current_xp: int = progress.get("current_xp", 0)
	var xp_needed: int = GameState.get_xp_required(character.rarity, level)

	xp_bar.max_value = xp_needed
	xp_bar.value = current_xp
	xp_value_label.text = "%d/%d" % [current_xp, xp_needed]
	level_label.text = "Lv. %d" % level

func _on_gacha_button_pressed() -> void:
	menu_popup.visible = false
	var gacha_instance: Control = GACHA_SCENE.instantiate()
	popup_layer.add_child(gacha_instance)
	gacha_instance.gold_changed.connect(update_currency_display)
	gacha_instance.tree_exited.connect(update_currency_display)

func _on_character_button_pressed() -> void:
	menu_popup.visible = false
	var previous_id: String = GameState.active_character_id

	var list_instance: Control = CHARACTER_LIST_SCENE.instantiate()
	popup_layer.add_child(list_instance)
	list_instance.tree_exited.connect(func():
		if GameState.active_character_id != previous_id:
			play_character_swap()
	)

func play_character_swap() -> void:
	if is_swapping:
		return
	is_swapping = true

	# bersihin sisa proses makan (kalau ada)
	eat_timer.stop()
	is_holding_to_eat = false
	current_food_stages.clear()
	feed_state = FeedState.NONE
	food_display.visible = false
	blink_timer.stop()

	var rest_y: float = character_display.position.y
	var drop_distance: float = get_viewport_rect().size.y

	# 1. karakter lama turun sampai hilang
	var out_tween := create_tween()
	out_tween.tween_property(character_display, "position:y", rest_y + drop_distance, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	await out_tween.finished

	# 2. ganti data & texture selagi tidak terlihat
	character_display.modulate.a = 0.0
	_load_character_textures()
	update_energy_display()
	update_xp_display()
	accessory_layer.refresh()
	await get_tree().process_frame

	# 3. karakter baru naik dari bawah dengan bounce
	character_display.position.y = rest_y + drop_distance
	character_display.modulate.a = 1.0

	var in_tween := create_tween()
	in_tween.tween_property(character_display, "position:y", rest_y, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await in_tween.finished

	character_display.position.y = rest_y
	_randomize_blink_timer()
	is_swapping = false

func _show_coming_soon() -> void:
	var toast: PanelContainer = coming_soon_toast.duplicate()
	toast.visible = true
	toast.modulate = Color(1, 1, 1, 1)
	add_child(toast)

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

func _on_accessories_button_pressed() -> void:
	if accessories_mode or is_swapping:
		return
	accessories_mode = true
	menu_popup.visible = false
	_reset_feeding()
	_fade_feeding_hud(false)
	
	character_area_rest_x = character_area.position.x
	_shift_character_area(character_area_rest_x - CHARACTER_SHIFT_X)

	var sidebar: Control = ACCESSORY_SIDEBAR_SCENE.instantiate()
	popup_layer.add_child(sidebar)
	sidebar.closing.connect(_on_accessory_sidebar_closing)
	sidebar.tickets_changed.connect(update_currency_display)

func _on_accessory_sidebar_closing() -> void:
	accessories_mode = false
	_shift_character_area(character_area_rest_x)
	_fade_feeding_hud(true)

func _shift_character_area(target_x: float) -> void:
	if shift_tween:
		shift_tween.kill()
	shift_tween = create_tween()
	shift_tween.tween_property(character_area, "position:x", target_x, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _reset_feeding() -> void:
	eat_timer.stop()
	is_holding_to_eat = false
	current_food_stages.clear()
	feed_state = FeedState.NONE
	food_display.visible = false
	if active_data:
		character_display.texture = active_data.eyes_open_texture
	_randomize_blink_timer()

func _fade_feeding_hud(show: bool) -> void:
	if hud_tween:
		hud_tween.kill()
	var target_alpha: float = 1.0 if show else 0.0
	hud_tween = create_tween().set_parallel(true)
	hud_tween.tween_property(feed_button, "modulate:a", target_alpha, 0.25)
	hud_tween.tween_property(energy_bar_wrapper, "modulate:a", target_alpha, 0.25)

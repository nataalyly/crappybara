extends Control

@onready var enemy_display: TextureButton = $EnemyArea/EnemyDisplay
@onready var enemy_hp_bar: ProgressBar = $EnemyArea/EnemyHPBar
@onready var damage_label: Label = $EnemyArea/DamageLabel
@onready var character_display: TextureRect = $BottomArea/CharacterDisplay

@onready var kill_count_label: Label = $TopBar/KillCountLabel
@onready var exit_button: TextureButton = $TopBar/ExitButton

@onready var tap_hint_label: Label = $TapHintLabel
@onready var afk_timer: Timer = $AfkTimer

@onready var reward_toast: PanelContainer = $RewardToast
@onready var reward_label: Label = $RewardToast/RewardLabel
@onready var toast_timer: Timer = $RewardToast/ToastTimer

@onready var xp_bar: ProgressBar = $BottomArea/XP_Row/XP_Bar
@onready var xp_value_label: Label = $BottomArea/XP_Row/XP_Bar/XP_Value
@onready var level_label: Label = $BottomArea/XP_Row/LevelLabel

@export var enemy_pool: Array[EnemyData] = []

var hint_blink_tween: Tween
var current_enemy: EnemyData
var current_hp: int
var kill_count: int = 0
var active_character: CharacterData
var progress: Dictionary

func _ready() -> void:
	active_character = GameState.get_active_character()
	progress = GameState.get_active_progress()
	
	if active_character:
		character_display.texture = active_character.eyes_open_texture

	damage_label.visible = false
	reward_toast.visible = false
	toast_timer.timeout.connect(func(): reward_toast.visible = false)
	
	afk_timer.timeout.connect(_show_tap_hint)
	afk_timer.start()
	_show_tap_hint()

	enemy_display.pressed.connect(_on_enemy_tapped)
	exit_button.pressed.connect(_on_exit_pressed)
	
	ButtonFX.apply_bounce(enemy_display)
	ButtonFX.apply_bounce(exit_button)

	update_xp_display()
	spawn_enemy()

func spawn_enemy() -> void:
	current_enemy = enemy_pool[randi() % enemy_pool.size()]
	current_hp = current_enemy.max_hp

	var variants: Array[Texture2D] = current_enemy.texture_variants
	enemy_display.texture_normal = variants[randi() % variants.size()]

	enemy_hp_bar.max_value = current_enemy.max_hp
	enemy_hp_bar.value = current_hp

func _on_enemy_tapped() -> void:
	_hide_tap_hint()
	afk_timer.start()
	
	var damage: int = GameState.get_damage(active_character.rarity, progress.get("level", 1))
	current_hp -= damage
	enemy_hp_bar.value = current_hp

	_play_hit_animation()
	_show_damage_number(damage)

	if current_hp <= 0:
		_on_enemy_defeated()

func _play_hit_animation() -> void:
	var tween := create_tween()
	tween.tween_property(enemy_display, "scale", Vector2(1.15, 1.15), 0.1)
	tween.tween_property(enemy_display, "scale", Vector2(1.0, 1.0), 0.1)

func _show_damage_number(damage: int) -> void:
	var label: Label = damage_label.duplicate()
	label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	label.text = "-%d" % damage
	label.visible = true
	label.modulate = Color(1, 1, 1, 1)
	
	var global_center: Vector2 = enemy_display.get_global_rect().get_center()
	var local_center: Vector2 = global_center - $EnemyArea.get_global_rect().position

	var enemy_size: Vector2 = enemy_display.get_global_rect().size
	var random_offset := Vector2(
		randf_range(-enemy_size.x * 0.7, enemy_size.x * 0.7),
		randf_range(-enemy_size.y * 0.5, enemy_size.y * 0.5)
	)
	label.position = local_center + random_offset
	
	$EnemyArea.add_child(label)
	
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 50, 0.6)
	tween.tween_property(label, "modulate:a", 0.0, 0.6)
	tween.chain().tween_callback(label.queue_free)

func _on_enemy_defeated() -> void:
	kill_count += 1
	kill_count_label.text = "Kills: %d" % kill_count

	_add_xp(current_enemy.xp_reward)
	_try_gold_drop()

	if kill_count % 5 == 0:
		_grant_milestone_reward()

	spawn_enemy()

func _add_xp(amount: int) -> void:
	var level: int = progress.get("level", 1)
	var current_xp: int = progress.get("current_xp", 0) + amount
	var xp_needed: int = GameState.get_xp_required(active_character.rarity, level)

	while current_xp >= xp_needed:
		current_xp -= xp_needed
		level += 1
		xp_needed = GameState.get_xp_required(active_character.rarity, level)

	progress["level"] = level
	progress["current_xp"] = current_xp
	update_xp_display()

func _try_gold_drop() -> void:
	var chance: float = 5.0 + kill_count * 1.0
	if randf_range(0, 100) <= chance:
		GameState.gold += 1

func _grant_milestone_reward() -> void:
	var bonus_gold: int = kill_count / 5
	GameState.gold += bonus_gold
	reward_label.text = "+%d Gold!" % bonus_gold
	reward_toast.visible = true
	toast_timer.start(2.0)

func update_xp_display() -> void:
	var level: int = progress.get("level", 1)
	var current_xp: int = progress.get("current_xp", 0)
	var xp_needed: int = GameState.get_xp_required(active_character.rarity, level)

	xp_bar.max_value = xp_needed
	xp_bar.value = current_xp
	xp_value_label.text = "%d/%d" % [current_xp, xp_needed]
	level_label.text = "Lv. %d" % level

func _on_exit_pressed() -> void:
	if kill_count > 5:
		GameState.energy = 0.0
	get_tree().change_scene_to_file("res://Scenes/HomeScreen.tscn")

func _show_tap_hint() -> void:
	tap_hint_label.visible = true
	tap_hint_label.modulate.a = 1.0

	if hint_blink_tween:
		hint_blink_tween.kill()
	hint_blink_tween = create_tween()
	hint_blink_tween.set_loops()
	hint_blink_tween.tween_property(tap_hint_label, "modulate:a", 0.2, 0.6).set_trans(Tween.TRANS_SINE)
	hint_blink_tween.tween_property(tap_hint_label, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE)

func _hide_tap_hint() -> void:
	if hint_blink_tween:
		hint_blink_tween.kill()
	tap_hint_label.visible = false

extends Control

signal closing
signal tickets_changed

const ITEM_CARD_SCENE := preload("res://Scenes/AccessoryItemCard.tscn")
const PANEL_WIDTH: float = 600.0
const TAB_SIZE_NORMAL := Vector2(110, 70)
const TAB_SIZE_ACTIVE := Vector2(150, 105)

@onready var sidebar_column: VBoxContainer = $SidebarColumn
@onready var tab_row: HBoxContainer = $SidebarColumn/TabRow
@onready var hat_tab: BaseButton = $SidebarColumn/TabRow/HeadTab
@onready var glasses_tab: BaseButton = $SidebarColumn/TabRow/EyewearTab
@onready var clothes_tab: BaseButton = $SidebarColumn/TabRow/BodyTab
@onready var sidebar_panel: PanelContainer = $SidebarColumn/SidebarPanel
@onready var ticket_label: Label = $SidebarColumn/SidebarPanel/Margin/MainVBox/HeaderRow/TicketLabel
@onready var close_button: BaseButton = $SidebarColumn/SidebarPanel/Margin/MainVBox/HeaderRow/CloseButton
@onready var item_grid: GridContainer = $SidebarColumn/SidebarPanel/Margin/MainVBox/ScrollContainer/ItemGrid
@onready var ticket_toast: PanelContainer = $TicketToast

var current_slot: String = "Head"
var is_closing: bool = false
var tabs: Dictionary = {}
var tab_tweens: Dictionary = {}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	sidebar_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tab_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ticket_toast.visible = false

	sidebar_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tab_row.custom_minimum_size.y = TAB_SIZE_ACTIVE.y  # tinggi tetap, panel nggak ikut naik-turun

	tabs = {"Head": hat_tab, "Eyewear": glasses_tab, "Body": clothes_tab}
	for slot in tabs:
		var tab: BaseButton = tabs[slot]
		tab.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		tab.size_flags_vertical = Control.SIZE_SHRINK_END
		tab.pressed.connect(_set_slot.bind(slot))
		ButtonFX.apply_bounce(tab)
	_update_tabs(false)

	close_button.pressed.connect(_on_close_pressed)
	ButtonFX.apply_bounce(close_button)

	_update_ticket_label()
	_populate_items()
	_slide_in()

func _set_slot(slot: String) -> void:
	if slot == current_slot:
		return
	current_slot = slot
	_update_tabs(true)
	_populate_items()

func _update_tabs(animated: bool) -> void:
	for slot in tabs:
		var tab: BaseButton = tabs[slot]
		var target: Vector2 = TAB_SIZE_ACTIVE if slot == current_slot else TAB_SIZE_NORMAL

		if tab_tweens.has(slot) and tab_tweens[slot]:
			tab_tweens[slot].kill()

		if animated:
			var tween := create_tween()
			tween.tween_property(tab, "custom_minimum_size", target, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tab_tweens[slot] = tween
		else:
			tab.custom_minimum_size = target


func _populate_items() -> void:
	for child in item_grid.get_children():
		item_grid.remove_child(child)
		child.queue_free()

	for data in GameState.get_accessories_by_slot(current_slot):
		var card: PanelContainer = ITEM_CARD_SCENE.instantiate()
		item_grid.add_child(card)
		card.setup(data)
		card.action_pressed.connect(_on_item_action)

func _refresh_cards() -> void:
	for card in item_grid.get_children():
		card.refresh()

func _on_item_action(data: AccessoryData) -> void:
	if GameState.is_accessory_equipped(data):
		GameState.unequip_slot(data.slot)
	elif GameState.is_accessory_owned(data):
		GameState.equip_accessory(data)
	else:
		if not GameState.buy_accessory(data):
			_show_ticket_toast()
			return
		GameState.equip_accessory(data)
		tickets_changed.emit()
		_update_ticket_label()
	_refresh_cards()

func _update_ticket_label() -> void:
	ticket_label.text = "Tiket: %d" % GameState.tickets

func _slide_in() -> void:
	sidebar_column.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	sidebar_column.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	sidebar_column.offset_top = 0.0
	sidebar_column.offset_bottom = 0.0
	sidebar_column.offset_left = 0.0
	sidebar_column.offset_right = PANEL_WIDTH  # mulai di luar layar (kanan)

	var tween := create_tween().set_parallel(true)
	tween.tween_property(sidebar_column, "offset_left", -PANEL_WIDTH, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(sidebar_column, "offset_right", 0.0, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _on_close_pressed() -> void:
	if is_closing:
		return
	is_closing = true
	closing.emit()

	var tween := create_tween().set_parallel(true)
	tween.tween_property(sidebar_column, "offset_left", 0.0, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(sidebar_column, "offset_right", PANEL_WIDTH, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await tween.finished
	queue_free()

func _show_ticket_toast() -> void:
	var toast: PanelContainer = ticket_toast.duplicate()
	toast.visible = true
	toast.modulate = Color(1, 1, 1, 1)
	toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(toast)

	var start_pos: Vector2 = toast.position
	toast.position = start_pos + Vector2(0, 20)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(toast, "position", start_pos, 0.15).set_trans(Tween.TRANS_SINE)
	tween.tween_property(toast, "modulate:a", 1.0, 0.15).from(0.0)

	tween.chain().tween_interval(0.5)

	tween.set_parallel(true)
	tween.tween_property(toast, "position", start_pos - Vector2(0, 30), 0.8).set_trans(Tween.TRANS_SINE)
	tween.tween_property(toast, "modulate:a", 0.0, 0.8)

	tween.chain().tween_callback(toast.queue_free)

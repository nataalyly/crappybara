extends Control
class_name AccessoryLayer

# Urutan gambar: yang pertama paling belakang, yang terakhir paling depan
const SLOT_ORDER: Array[String] = ["Body", "Eyewear", "Head"]

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	GameState.equipment_changed.connect(refresh)
	refresh()

func refresh() -> void:
	for child in get_children():
		child.queue_free()

	var equipped: Dictionary = GameState.get_active_equipped()
	for slot in SLOT_ORDER:
		var id: String = equipped.get(slot, "")
		if id == "":
			continue
		var data: AccessoryData = GameState.get_accessory_by_id(id)
		if data == null or data.texture == null:
			continue

		var item := TextureRect.new()
		item.texture = data.texture
		item.mouse_filter = Control.MOUSE_FILTER_IGNORE
		item.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		item.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		add_child(item)
		item.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

extends Node
signal equipment_changed

# --- Currency ---
var gold: int = 500
var tickets: int = 100
var pulls_since_legendary: int = 0

# --- Energy karakter aktif (0-100) ---
var energy: float = 0.0

var character_pool: Array[CharacterData] = []
func _init() -> void:
	character_pool = [
		load("res://Assets/CharacterData/clay.tres"),
		load("res://Assets/CharacterData/capybara.tres"),
		load("res://Assets/CharacterData/greg.tres"),
		load("res://Assets/CharacterData/lovey.tres"),
		load("res://Assets/CharacterData/melon.tres"),
		load("res://Assets/CharacterData/golda.tres"),
		load("res://Assets/CharacterData/sprinkle.tres"),
		load("res://Assets/CharacterData/bolu.tres"),
		load("res://Assets/CharacterData/klepto.tres"),
		load("res://Assets/CharacterData/bubble.tres"),
		load("res://Assets/CharacterData/mikan.tres"),
		load("res://Assets/CharacterData/lhumud.tres"),
		load("res://Assets/CharacterData/adien.tres"),
		load("res://Assets/CharacterData/brando.tres"),
		load("res://Assets/CharacterData/painom.tres"),
		load("res://Assets/CharacterData/yazuka.tres"),
		#load("res://Assets/CharacterData/"),
	]
	accessory_catalog = [
		#baju
		load("res://Assets/AccessoryData/miku.tres"),
		load("res://Assets/AccessoryData/jas.tres"),
		load("res://Assets/AccessoryData/onic.tres"),
		load("res://Assets/AccessoryData/merah.tres"),
		load("res://Assets/AccessoryData/kuning.tres"),
		load("res://Assets/AccessoryData/ijo_tosca.tres"),
		#load("res://Assets/AccessoryData/"),
		#topi
		#load("res://Assets/AccessoryData/"),
		#load("res://Assets/AccessoryData/"),
		#load("res://Assets/AccessoryData/"),
		#load("res://Assets/AccessoryData/"),
		#muka
		#load("res://Assets/AccessoryData/"),
		#load("res://Assets/AccessoryData/"),
		#load("res://Assets/AccessoryData/"),
		#load("res://Assets/AccessoryData/"),
	]

# --- Semua capybara yang dimiliki player ---
var owned_character_ids: Dictionary = {}
var character_progress: Dictionary = {}
var active_character_id: String = ""

# --- Inventory aksesoris & perabot ---
var accessory_catalog: Array[AccessoryData] = []
var owned_accessory_ids: Dictionary = {}      # resource_path -> true
var equipped_by_character: Dictionary = {}    # character_id -> {slot -> resource_path}var owned_furniture: Array = []
var placed_furniture: Array = []  

# --- Base XP requirement & increment per rarity ---
const BASE_XP: int = 500
const XP_INCREMENT := {
	"common": 100,
	"rare": 150,
	"epic": 200,
	"legendary": 300,
}

# --- Base damage & increment per rarity ---
const BASE_DMG := {
	"common": 10,
	"rare": 15,
	"epic": 25,
	"legendary": 50,
}
const DMG_INCREMENT := {
	"common": 10,
	"rare": 15,
	"epic": 25,
	"legendary": 50,
}

func _ready() -> void:
	if owned_character_ids.is_empty() and not character_pool.is_empty():
		_grant_starter_character()

func _grant_starter_character() -> void:
	var starter: CharacterData = character_pool[0]  # karakter pertama di pool jadi starter
	_add_owned_character(starter)
	active_character_id = starter.resource_path

func _add_owned_character(data: CharacterData) -> void:
	var id: String = data.resource_path
	owned_character_ids[id] = true
	character_progress[id] = {"level": 1, "current_xp": 0}

func get_characters_by_rarity(rarity: String) -> Array[CharacterData]:
	var result: Array[CharacterData] = []
	for c in character_pool:
		if c.rarity == rarity:
			result.append(c)
	return result

func get_character_data_by_id(id: String) -> CharacterData:
	for c in character_pool:
		if c.resource_path == id:
			return c
	return null

func _create_starter_character() -> void:
	var starter_id := "capy_001"
	var data: CharacterData = load("res://Assets/CharacterData/01_capy_common.tres")
	owned_character_ids[starter_id] = data
	character_progress[starter_id] = {"level": 1, "current_xp": 0}
	active_character_id = starter_id

func get_active_character() -> CharacterData:
	return get_character_data_by_id(active_character_id)

func get_active_progress() -> Dictionary:
	return character_progress.get(active_character_id, {})

func get_xp_required(rarity: String, level: int) -> int:
	var increment: int = XP_INCREMENT.get(rarity, 100)
	return BASE_XP + increment * (level - 1)

func get_damage(rarity: String, level: int) -> int:
	var base: int = BASE_DMG.get(rarity, 10)
	var increment: int = DMG_INCREMENT.get(rarity, 10)
	return base + increment * (level - 1)

func add_energy(amount: float) -> void:
	energy = min(energy + amount, 100.0)

func grant_feed_reward() -> void:
	gold += 1

func is_hungry() -> bool:
	return energy < 100.0

func can_battle() -> bool:
	return energy >= 100.0

func get_accessory_by_id(id: String) -> AccessoryData:
	for a in accessory_catalog:
		if a.resource_path == id:
			return a
	return null

func get_accessories_by_slot(slot: String) -> Array[AccessoryData]:
	var result: Array[AccessoryData] = []
	for a in accessory_catalog:
		if a.slot == slot:
			result.append(a)
	return result

func is_accessory_owned(data: AccessoryData) -> bool:
	return owned_accessory_ids.has(data.resource_path)

func buy_accessory(data: AccessoryData) -> bool:
	if is_accessory_owned(data) or tickets < data.price:
		return false
	tickets -= data.price
	owned_accessory_ids[data.resource_path] = true
	return true

func get_equipped_for(character_id: String) -> Dictionary:
	return equipped_by_character.get(character_id, {})

func get_active_equipped() -> Dictionary:
	return get_equipped_for(active_character_id)

func is_accessory_equipped(data: AccessoryData) -> bool:
	return get_active_equipped().get(data.slot, "") == data.resource_path

func equip_accessory(data: AccessoryData) -> void:
	if not is_accessory_owned(data) or active_character_id == "":
		return
	if not equipped_by_character.has(active_character_id):
		equipped_by_character[active_character_id] = {}
	equipped_by_character[active_character_id][data.slot] = data.resource_path
	equipment_changed.emit()

func unequip_slot(slot: String) -> void:
	if equipped_by_character.has(active_character_id):
		equipped_by_character[active_character_id].erase(slot)
	equipment_changed.emit()

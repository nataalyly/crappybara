extends Node

var bgm_player: AudioStreamPlayer
var bgm_track: AudioStream

var sfx_click: AudioStream
var sfx_feed_bite: AudioStream
var sfx_gacha_common: AudioStream
var sfx_gacha_rare: AudioStream
var sfx_gacha_epic: AudioStream
var sfx_gacha_legendary: AudioStream

func _init() -> void:
	bgm_track = load("res://Assets/Audio/Muse_Crappybara_OST.mp3")
	sfx_click = load("res://Assets/Audio/click_sound.mp3")
	sfx_feed_bite = load("res://Assets/Audio/eat_sound.mp3")
	sfx_gacha_common = load("res://Assets/Audio/common_win.mp3")
	sfx_gacha_rare = load("res://Assets/Audio/rare_win.mp3")
	sfx_gacha_epic = load("res://Assets/Audio/epic_win.mp3")
	sfx_gacha_legendary = load("res://Assets/Audio/legendary_win.mp3")

func _ready() -> void:
	bgm_player = AudioStreamPlayer.new()
	add_child(bgm_player)
	bgm_player.stream = bgm_track
	play_bgm()

func play_bgm() -> void:
	if bgm_track == null or bgm_player.playing:
		return
	bgm_player.play()

func play_sfx(stream: AudioStream, volume_db: float = 0.0) -> void:
	if stream == null:
		return
	var sfx_player := AudioStreamPlayer.new()
	add_child(sfx_player)
	sfx_player.stream = stream
	sfx_player.volume_db = volume_db
	sfx_player.play()
	sfx_player.finished.connect(sfx_player.queue_free)

func play_gacha_sfx(rarity: String) -> void:
	var sfx_map := {
		"common": sfx_gacha_common,
		"rare": sfx_gacha_rare,
		"epic": sfx_gacha_epic,
		"legendary": sfx_gacha_legendary,
	}
	play_sfx(sfx_map.get(rarity))

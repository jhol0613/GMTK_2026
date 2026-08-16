extends Node2D

@export var sprite: AnimatedSprite2D
@export var drop_radius: float = 120.0
@export var reward_battery: int = 4

@export_group("Audio")
@export var open_sound: AudioStream
@export var close_sound: AudioStream
@export_range(-80.0, 6.0, 0.5) var sound_volume_db: float = -6.0

var _lid_open := false
var _sound_player: AudioStreamPlayer2D


func _ready() -> void:
	add_to_group("recycle_bin")
	sprite.animation = &"open"
	sprite.frame = 0
	sprite.stop()
	_sound_player = AudioStreamPlayer2D.new()
	_sound_player.bus = &"SFX"
	_sound_player.volume_db = sound_volume_db
	add_child(_sound_player)


func set_lid_open(open: bool) -> void:
	if open == _lid_open:
		return
	_lid_open = open
	if open:
		sprite.play(&"open")
		_play_lid_sound(open_sound)
	else:
		sprite.play_backwards(&"open")
		_play_lid_sound(close_sound)


func _play_lid_sound(sound: AudioStream) -> void:
	if sound == null:
		return
	_sound_player.stop()
	_sound_player.stream = sound
	_sound_player.play()


func recycle(item: ItemData) -> void:
	Inventory.remove_item(item)
	Wallet.add(reward_battery)
	set_lid_open(false)

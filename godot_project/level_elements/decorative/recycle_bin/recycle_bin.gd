extends Node2D

@export var sprite: AnimatedSprite2D
@export var drop_radius: float = 120.0
@export var reward_battery_mask: int = 2
@export var reward_battery_coffee_cup: int = 2
@export var antenna_open_time := 1.5

@export_group("Audio")
@export var open_sound: AudioStream
@export var close_sound: AudioStream
@export_range(-80.0, 6.0, 0.5) var sound_volume_db: float = -6.0

@onready var _lightning_origin := $LightningOrigin

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
	var reward_amount: int
	if String(item.id).begins_with("mask_"):
		reward_amount = reward_battery_mask
	elif item.id == &"empty_coffee_cup":
		reward_amount = reward_battery_coffee_cup
	set_lid_open(false)
	await sprite.animation_finished
	sprite.play(&"antenna_reveal")
	await sprite.animation_finished
	Wallet.add(reward_amount, _lightning_origin.global_position)
	await get_tree().create_timer(antenna_open_time).timeout
	sprite.play_backwards(&"antenna_reveal")

extends Node2D

@export var sprite: AnimatedSprite2D
@export var drop_radius: float = 120.0
@export var reward_battery: int = 4


func _ready() -> void:
	add_to_group("recycle_bin")
	sprite.animation = &"open"
	sprite.frame = 0
	sprite.stop()


func set_lid_open(open: bool) -> void:
	if open:
		sprite.play(&"open")
	else:
		sprite.play_backwards(&"open")


func recycle(item: ItemData) -> void:
	Inventory.remove_item(item)
	Wallet.add(reward_battery)
	set_lid_open(false)

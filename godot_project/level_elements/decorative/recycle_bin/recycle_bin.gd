extends Node2D

@export var sprite: AnimatedSprite2D


func _ready() -> void:
	sprite.animation = &"open"
	sprite.frame = 0
	sprite.stop()


func _on_area_2d_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	sprite.play(&"open")


func _on_area_2d_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	if sprite.is_playing():
		sprite.play(&"open", -1.0)
	else:
		sprite.play_backwards(&"open")

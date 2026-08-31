extends Interactable

@export var sprite : AnimatedSprite2D
@export var collider : CollisionShape2D

var open : bool = false

func interact() -> void:
	open = not open
	if open:
		sprite.play("opening")
		collider.disabled = true
	else:
		sprite.play_backwards("opening")
		collider.disabled = false

extends Interactable

@export var sprite : AnimatedSprite2D
@export var collider : CollisionShape2D

var open : bool = false


func _ready() -> void:
	super._ready()
	add_to_group("save_state")
	open = SaveManager.state_for(self).get("open", false)
	if open:
		sprite.animation = &"opening"
		sprite.frame = sprite.sprite_frames.get_frame_count(&"opening") - 1
		collider.set_deferred("disabled", true)


func get_save_state() -> Dictionary:
	return {"open": open}

func interact() -> void:
	open = not open
	if open:
		sprite.play("opening")
		collider.disabled = true
	else:
		sprite.play_backwards("opening")
		collider.disabled = false

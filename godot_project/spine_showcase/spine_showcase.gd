extends Node2D



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var sprite : SpineSprite = $SpineSprite
	var animation_state = sprite.get_animation_state()
	animation_state.set_animation("Demo/atktest")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_rhythm_notifier_beat(current_beat: int) -> void:
	print(current_beat)

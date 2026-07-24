@tool

extends Node2D

@export var sprite : AnimatedSprite2D
@export var color := Enums.TrainColor.BROWN :
	# Ensure that index of animation names matches the order of the Enums
	set(new_color):
		print("setting color")
		color = new_color
		var anim_names = sprite.sprite_frames.get_animation_names()
		print(color)
		print(anim_names)
		sprite.play(anim_names[color])

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

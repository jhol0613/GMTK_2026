@tool

extends Node2D

class_name Train

@export var sprite : AnimatedSprite2D
@export var color := Enums.TrainColor.BROWN :
	# Ensure that index of animation names matches the order of the Enums
	set(new_color):
		color = new_color
		if sprite:
			sprite.play(Enums.TrainColor.find_key(color))



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

extends Node2D

enum anims {shroom1, white1, yellow1}
@export var anim = anims.shroom1
@export var sprite : AnimatedSprite2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	sprite.play(anims.keys()[anim])

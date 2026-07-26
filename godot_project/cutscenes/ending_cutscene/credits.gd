extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func roll_credits():
	$CreditsAnimation.play("scroll_credits")

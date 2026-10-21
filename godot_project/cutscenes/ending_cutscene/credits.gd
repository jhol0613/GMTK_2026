extends Node2D

var scroll_tween : Tween

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func roll_credits():
	#$CreditsAnimation.play("scroll_credits")
	scroll_tween = create_tween()
	var end_posit = $VBoxContainer.position.y + $VBoxContainer.size.y - get_viewport().size.y / 2
	scroll_tween.tween_property($VBoxContainer,"position.y",end_posit, 11)
	scroll_tween.play()

extends Sprite2D

class_name FadingSprite2D

@export var fade_in_time := 1.0
@export var fade_out_time := 1.0


func _ready():
	self_modulate.a = 0.0

func fade_in():
	print("fading in")
	create_tween().tween_property(self, "self_modulate:a", 1.0, 1.0)

func fade_out():
	create_tween().tween_property(self, "self_modulate:a", 0.0, 1.0)

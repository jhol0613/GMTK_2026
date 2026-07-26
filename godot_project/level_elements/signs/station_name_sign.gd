extends Node2D

@export var station_number := 0

@onready var sprite = $AnimatedSprite2D
@onready var resshan_interactable = $ResshanInteractable

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	sprite.play(str(station_number))
	resshan_interactable._string = "<<station." + str(station_number) + ">>"
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

extends Node2D

@export var station_number := 0:
	set(value):
		station_number = value
		_apply_station_number()

@onready var sprite = $AnimatedSprite2D
@onready var resshan_interactable = $ResshanInteractable

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_apply_station_number()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _apply_station_number() -> void:
	if not is_inside_tree():
		return
	if sprite == null:
		sprite = get_node_or_null("AnimatedSprite2D")
	if resshan_interactable == null:
		resshan_interactable = get_node_or_null("ResshanInteractable")
	if sprite:
		sprite.play(str(station_number))
	if resshan_interactable:
		resshan_interactable._string = "<<station." + str(station_number) + ">>"

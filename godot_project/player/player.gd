extends CharacterBody2D

var direction: Vector2 = Vector2(1,1)
var speed: int = 100
var distance: int = 0

@export var distance_per_minute: int = 50

@onready var timer: Timer = $Timer

func _ready() -> void:
	add_to_group("player")


func _physics_process(delta: float) -> void:
	if _is_any_panel_open():
		direction = Vector2.ZERO
		return

	var old_position = position
	direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * speed
	move_and_slide()
	if position != old_position:
		distance += 1
	
	if distance == distance_per_minute:
		SignalBus.player_moved.emit()
		distance = 0


func _is_any_panel_open() -> bool:
	for panel in get_tree().get_nodes_in_group("interaction_panel"):
		if panel.has_method("is_open") and panel.is_open():
			return true
	return false

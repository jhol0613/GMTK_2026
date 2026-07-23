extends CharacterBody2D

var direction: Vector2 = Vector2(1,1)
var tile_size_x: int = 16
var tile_size_y: int = 16
var movement_speed: float = 0.3 #time inbetween moving a tile

@onready var timer: Timer = $Timer

func _ready() -> void:
	add_to_group("player")
	timer.start(movement_speed)


func _physics_process(delta: float) -> void:
	get_direction()
	
	
	
func _on_timer_timeout() -> void:
	
	if Input.is_action_pressed("left") or Input.is_action_pressed("right"):
		self.position += Vector2(tile_size_x, 0) * direction
		
	if Input.is_action_pressed("up") or Input.is_action_pressed("down"):
		self.position += Vector2(0, tile_size_y) * direction
	
	timer.start(movement_speed)

func get_direction() -> void:
	var x: int = Input.get_axis("left", "right")
		
	var y: int = Input.get_axis("up", "down")
	
	if x != 0 and y != 0:
		direction = Vector2(0, 0)
	else:
		direction = Vector2(x, y)

extends CharacterBody2D

var direction: Vector2 = Vector2(1,1)
var tile_size_x: int = 16
var tile_size_y: int = 16
var movement_speed: float = 0.25 #time inbetween moving a tile

@onready var timer: Timer = $Timer
@export var footstep_sounds: Array[AudioStream] = []
var _footsteps: AudioStreamPlayer


func _ready() -> void:
	add_to_group("player")
	timer.start(movement_speed)
	_footsteps = AudioStreamPlayer.new()
	var rng := AudioStreamRandomizer.new()
	rng.playback_mode = AudioStreamRandomizer.PLAYBACK_RANDOM_NO_REPEATS
	rng.random_pitch = 1.1
	for s in footstep_sounds:
		rng.add_stream(-1, s)
	_footsteps.stream = rng
	add_child(_footsteps)
	SignalBus.player_moved.connect(_on_player_moved)
	$AudioListener2D.make_current()


func _physics_process(delta: float) -> void:
	if _is_any_panel_open():
		direction = Vector2.ZERO
		return
	get_direction()
	
	
	
func _on_timer_timeout() -> void:
	
	if Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right"):
		self.position += Vector2(tile_size_x, 0) * direction
		if direction != Vector2(0, 0):
			SignalBus.player_moved.emit()
		
	if Input.is_action_pressed("move_up") or Input.is_action_pressed("move_down"):
		self.position += Vector2(0, tile_size_y) * direction
		if direction != Vector2(0, 0):
			SignalBus.player_moved.emit()
	
	timer.start(movement_speed)

func get_direction() -> void:
	var x: float = Input.get_axis("move_left", "move_right")
		
	var y: float = Input.get_axis("move_up", "move_down")
	
	if x != 0 and y != 0:
		direction = Vector2(0, 0)
	else:
		direction = Vector2(x, y)


func _is_any_panel_open() -> bool:
	for panel in get_tree().get_nodes_in_group("interaction_panel"):
		if panel.has_method("is_open") and panel.is_open():
			return true
	return false

func _on_player_moved() -> void:
	_footsteps.play()

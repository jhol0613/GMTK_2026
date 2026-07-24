extends CharacterBody2D

var direction: Vector2 = Vector2(1,1)
var speed: int = 100
var distance: int = 0

@export var distance_per_minute: int = 50

@export var footstep_sounds: Array[AudioStream] = []
var _footsteps: AudioStreamPlayer
@export var footstep_distance: float = 40.0
var _step_accum: float = 0.0

@export_category("Footstep Surfaces")

@export var grass_footstep_sounds: Array[AudioStream] = []
@export var stone_footstep_sounds: Array[AudioStream] = []
@export var wood_footstep_sounds: Array[AudioStream] = []

@export var footstep_sample_offset := Vector2(0, 8)

var _footstep_randomizers: Dictionary[StringName, AudioStreamRandomizer] = {}

@onready var sprite := $PlayerSprite
@onready var timer: Timer = $Timer


func _ready() -> void:
	add_to_group("player")
	
	_footsteps = AudioStreamPlayer.new()
	var rng := AudioStreamRandomizer.new()
	rng.playback_mode = AudioStreamRandomizer.PLAYBACK_RANDOM_NO_REPEATS
	rng.random_pitch = 1.1
	for s in footstep_sounds:
		rng.add_stream(-1, s)
	_footsteps.stream = rng
	add_child(_footsteps)
	$AudioListener2D.make_current()
	
	_footsteps = AudioStreamPlayer.new()

	add_child(_footsteps)

	_footstep_randomizers[&"default"] = (
		_create_footstep_randomizer(footstep_sounds)
	)
	_footstep_randomizers[&"grass"] = (
		_create_footstep_randomizer(grass_footstep_sounds)
	)
	_footstep_randomizers[&"stone"] = (
		_create_footstep_randomizer(stone_footstep_sounds)
	)
	_footstep_randomizers[&"wood"] = (
		_create_footstep_randomizer(wood_footstep_sounds)
	)
	

	$AudioListener2D.make_current()


func _physics_process(_delta: float) -> void:
	if _is_any_panel_open():
		direction = Vector2.ZERO
		return

	
	direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	_animate()
	
	if not direction:
		return
	
	
	velocity = direction * speed
	var old_position = position
	move_and_slide()
	if position != old_position:
		distance += 1
	
	if distance == distance_per_minute:
		SignalBus.minutes_passed.emit(1)
		distance = 0
		
	_step_accum += (position - old_position).length()
	if direction != Vector2.ZERO and _step_accum >= footstep_distance:
		_step_accum = 0.0
		_play_footstep()


func _is_any_panel_open() -> bool:
	for panel in get_tree().get_nodes_in_group("interaction_panel"):
		if panel.has_method("is_open") and panel.is_open():
			return true
	return false

func _animate() -> void:
	# Left/right facing
	if direction.x != 0 :
		sprite.flip_h = direction.x < 0
	
	# Walking animations
	if abs( direction.x ) > 0 :
		sprite.play( "walk_right" )
	elif direction.y > 0 :
		sprite.play( "walk_down" )
	elif direction.y < 0 :
		sprite.play( "walk_up" )
	# Idle animations
	else :
		# Plays the animation for the last direction the player was walking before they stopped
		match sprite.animation :
			"walk_right" :
				sprite.play( "idle_right" )
			"walk_up" :
				sprite.play( "idle_up" )
			"walk_down" :
				sprite.play( "idle" )

func _create_footstep_randomizer(
	sounds: Array[AudioStream]
) -> AudioStreamRandomizer:
	var randomizer := AudioStreamRandomizer.new()

	randomizer.playback_mode = (
		AudioStreamRandomizer.PLAYBACK_RANDOM_NO_REPEATS
	)
	randomizer.random_pitch = 1.1

	for sound in sounds:
		randomizer.add_stream(-1, sound)

	return randomizer
	
func _get_footstep_surface() -> StringName:
	var foot_position := global_position + footstep_sample_offset

	for node in get_tree().get_nodes_in_group("footstep_surfaces"):
		var tile_layer := node as TileMapLayer

		if tile_layer == null:
			continue

		var local_position := tile_layer.to_local(foot_position)
		var cell_position := tile_layer.local_to_map(local_position)
		var tile_data := tile_layer.get_cell_tile_data(cell_position)

		if tile_data == null:
			continue

		var surface := StringName(
			tile_data.get_custom_data("footstep_surface")
		)

		if surface != &"":
			return surface

	return &"default"
	
func _play_footstep() -> void:
	var surface := _get_footstep_surface()

	var randomizer := _footstep_randomizers.get(
		surface,
		_footstep_randomizers[&"default"]
	) as AudioStreamRandomizer

	if randomizer == null or randomizer.streams_count == 0:
		return

	_footsteps.stream = randomizer
	_footsteps.play()

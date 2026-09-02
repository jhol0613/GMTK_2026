class_name PlayerCharacter
extends CharacterBody2D

var direction: Vector2 = Vector2(1, 1)
const NORMAL_SPEED := 100
const NORMAL_SPRINT_SPEED := 200
const COFFEE_SPEED := 150
const COFFEE_SPRINT_SPEED := 300
var speed: int = NORMAL_SPEED
var sprint_speed: int = NORMAL_SPRINT_SPEED
var sprint_animation_multiplier := 1.5
var distance: int = 0
var movement_disabled: bool = false

@export_group("Following")
@export var trail_buffer_max_size = 20
@export var min_trail_distance_squared = 100.0
@export var max_trail_distance_squared = 900.0
var _trail_buffer : Array[Vector2]
var _moved_last_iteration := false

@export var distance_per_minute: int = 50

@export var footstep_sounds: Array[AudioStream] = []
var _footsteps: AudioStreamPlayer
@export var footstep_distance: float = 40.0
var _step_accum: float = 0.0

@export_category("Footstep Surfaces")

@export_category("Footstep Volumes")
@export_range(-40.0, 6.0, 0.5)
var default_footstep_volume_db: float = -10.0
@export_range(-40.0, 6.0, 0.5) var grass_footstep_volume_db: float = -4.0
@export_range(-40.0, 6.0, 0.5) var stone_footstep_volume_db: float = -10.0
@export_range(-40.0, 6.0, 0.5) var wood_footstep_volume_db: float = -10.0

@export var grass_footstep_sounds: Array[AudioStream] = []
@export var stone_footstep_sounds: Array[AudioStream] = []
@export var wood_footstep_sounds: Array[AudioStream] = []

@export var footstep_sample_offset := Vector2(0, 8)

var _footstep_randomizers: Dictionary[StringName, AudioStreamRandomizer] = { }

@onready var sprite := $PlayerSprite
@onready var timer: Timer = $Timer
@onready var trail_marker := $FollowPosition


func _ready() -> void:
	add_to_group("player")

	_initialize_footstep_audio()
	TimeManager.time_scale_changed.connect(_on_time_scale_changed)
	_on_time_scale_changed(TimeManager.time_scale)
	#trail_marker.reparent(get_parent())


func _on_time_scale_changed(scale: float) -> void:
	var coffee_active := scale < 1.0
	speed = COFFEE_SPEED if coffee_active else NORMAL_SPEED
	sprint_speed = COFFEE_SPRINT_SPEED if coffee_active else NORMAL_SPRINT_SPEED


func _physics_process(_delta: float) -> void:
	if _is_any_panel_open() or movement_disabled:
		direction = Vector2.ZERO
		sprite.speed_scale = 1.0
		_animate()
		return

	direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	_animate()

	if not direction:
		
		if _moved_last_iteration and _trail_buffer.size() > 1 and \
			_trail_buffer[0].distance_squared_to(_trail_buffer[-1]) > max_trail_distance_squared:
			_trail_buffer.pop_front()
			trail_marker.position = _trail_buffer[0] - position
			_moved_last_iteration = true
		else:
			_moved_last_iteration = false
		return

	var sprinting = Input.is_action_pressed("sprint")
	sprite.speed_scale = sprint_animation_multiplier if sprinting else 1.0
	velocity = direction * (sprint_speed if sprinting else speed)
	var old_position = position
	move_and_slide()
	if position != old_position:
		distance += 1
		
		#keep track of position behind player for a following node to target
		_trail_buffer.append(old_position)
		if _trail_buffer.size() > trail_buffer_max_size:
			_trail_buffer.pop_front()
		trail_marker.position = _trail_buffer[0] - position
		_moved_last_iteration = true

	if distance == distance_per_minute:
		SignalBus.minutes_passed.emit(1)
		distance = 0

	_step_accum += (position - old_position).length()
	if direction != Vector2.ZERO and _step_accum >= footstep_distance:
		_step_accum = 0.0
		_play_footstep()

func set_active(active: bool):
	visible = active
	movement_disabled = not active
	set_physics_process(active)

func _is_any_panel_open() -> bool:
	for panel in get_tree().get_nodes_in_group("interaction_panel"):
		if panel.has_method("is_open") and panel.is_open():
			return true
	return false


## Scripted walk used by cutscenes (train boarding / exit). Disables input until done.
## `walk_up` forces the up clip (boarding, where the player walks into the train).
## Otherwise the clip follows the direction of travel, same as normal movement.
func walk_to(
	target_global: Vector2,
	walk_speed: float = 80.0,
	walk_up: bool = false,
) -> void:
	movement_disabled = true
	var delta_pos := target_global - global_position
	var travel_distance := delta_pos.length()

	var walk_anim: StringName = &"walk_up"
	var idle_anim: StringName = &"idle_up"
	if not walk_up:
		if absf(delta_pos.x) > absf(delta_pos.y):
			walk_anim = &"walk_right"
			idle_anim = &"idle_right"
			sprite.flip_h = delta_pos.x < 0.0
		elif delta_pos.y > 0.0:
			walk_anim = &"walk_down"
			idle_anim = &"idle"
	if travel_distance < 1.0:
		direction = Vector2.ZERO
		sprite.play(idle_anim)
		return

	direction = delta_pos.normalized()
	sprite.play(walk_anim)

	var duration := travel_distance / walk_speed
	var tween := create_tween()
	tween.tween_property(self, "global_position", target_global, duration)
	await tween.finished

	direction = Vector2.ZERO
	sprite.play(idle_anim)


func _animate() -> void:
	# Left/right facing
	if direction.x != 0:
		sprite.flip_h = direction.x < 0

	# Walking animations
	if abs(direction.x) > 0:
		sprite.play("walk_right")
	elif direction.y > 0:
		sprite.play("walk_down")
	elif direction.y < 0:
		sprite.play("walk_up")
	else:
		match sprite.animation:
			"walk_right":
				sprite.play("idle_right")
			"walk_up":
				sprite.play("idle_up")
			"walk_down":
				sprite.play("idle")


func _initialize_footstep_audio() -> void:
	_footsteps = AudioStreamPlayer.new()
	_footsteps.name = "FootstepPlayer"
	_footsteps.bus = AudioManager.SFX_BUS
	add_child(_footsteps)

	_footstep_randomizers[&"default"] = (_create_footstep_randomizer(footstep_sounds))
	_footstep_randomizers[&"grass"] = (_create_footstep_randomizer(grass_footstep_sounds))
	_footstep_randomizers[&"stone"] = (_create_footstep_randomizer(stone_footstep_sounds))
	_footstep_randomizers[&"wood"] = (_create_footstep_randomizer(wood_footstep_sounds))

	$AudioListener2D.make_current()


func _create_footstep_randomizer(sounds: Array[AudioStream]) -> AudioStreamRandomizer:
	var randomizer := AudioStreamRandomizer.new()

	randomizer.playback_mode = (AudioStreamRandomizer.PLAYBACK_RANDOM_NO_REPEATS)
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

		var surface := StringName(tile_data.get_custom_data("footstep_surface"))

		if surface != &"":
			return surface

	return &"default"


func _play_footstep() -> void:
	var surface := _get_footstep_surface()

	var randomizer := _footstep_randomizers.get(surface, _footstep_randomizers[&"default"]) as AudioStreamRandomizer

	if randomizer == null or randomizer.streams_count == 0:
		return

	_footsteps.stream = randomizer
	_footsteps.volume_db = _get_footstep_volume(surface)
	_footsteps.play()


func _get_footstep_volume(surface: StringName) -> float:
	match surface:
		&"grass":
			return grass_footstep_volume_db
		&"stone":
			return stone_footstep_volume_db
		&"wood":
			return wood_footstep_volume_db
		_:
			return default_footstep_volume_db

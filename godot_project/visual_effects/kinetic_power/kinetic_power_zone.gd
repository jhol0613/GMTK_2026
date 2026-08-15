extends Area2D

const CIRCUIT_COLOR := Color(0.25, 0.82, 1.0, 1.0)
const PULSE_COLOR := Color(0.68, 0.92, 1.0, 1.0)
const LINE_ALPHA := 0.42
const PULSE_ALPHA := 0.9
const FADE_DURATION := 0.08
const ACTIVITY_HOLD := 0.12
const PULSE_SPEED := 150.0
const PULSE_COUNT := 3
const MOVEMENT_THRESHOLD_SQUARED := 0.04

@export var range_radius := 12.0
@export var receiver_offset := Vector2(0, -4)

@onready var circuit: Line2D = $Circuit
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var _player: Node2D
var _last_player_position := Vector2.ZERO
var _path_points := PackedVector2Array()
var _path_length := 0.0
var _circuit_alpha := 0.0
var _pulse_alpha := 0.0
var _pulse_phase := 0.0
var _activity_left := 0.0


func _ready() -> void:
	add_to_group("kinetic_power_zones")
	var circle := collision_shape.shape as CircleShape2D
	if circle != null:
		circle.radius = range_radius
	circuit.default_color = CIRCUIT_COLOR
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _process(delta: float) -> void:
	if _player != null and not is_instance_valid(_player):
		_player = null

	var moving := false
	if _player != null:
		var player_position := _player.global_position
		moving = player_position.distance_squared_to(_last_player_position) > MOVEMENT_THRESHOLD_SQUARED
		_last_player_position = player_position

	var selected := _player != null and _is_closest_zone()
	if selected and moving:
		_activity_left = ACTIVITY_HOLD
	else:
		_activity_left = move_toward(_activity_left, 0.0, delta)
	if not selected:
		_activity_left = 0.0
	var active := selected and _activity_left > 0.0
	if active:
		_update_path()

	_circuit_alpha = move_toward(
		_circuit_alpha,
		1.0 if active else 0.0,
		delta / FADE_DURATION,
	)
	_pulse_alpha = move_toward(
		_pulse_alpha,
		1.0 if active and moving else 0.0,
		delta / FADE_DURATION,
	)
	circuit.visible = _circuit_alpha > 0.0
	circuit.modulate.a = _circuit_alpha * LINE_ALPHA

	if active and moving and _path_length > 0.0:
		_pulse_phase = fposmod(
			_pulse_phase + delta * PULSE_SPEED / _path_length,
			1.0,
		)
	queue_redraw()


func _draw() -> void:
	if _pulse_alpha > 0.0 and _path_length > 0.0:
		var pulse_color := PULSE_COLOR
		pulse_color.a = _pulse_alpha * PULSE_ALPHA
		for index in PULSE_COUNT:
			var progress := fposmod(
				_pulse_phase - float(index) / float(PULSE_COUNT),
				1.0,
			)
			var point := _point_on_path(progress)
			draw_rect(Rect2(point - Vector2.ONE, Vector2(2, 2)), pulse_color)

func _update_path() -> void:
	var start := to_local(_player.global_position).round()
	var target := receiver_offset.round()
	var midpoint := Vector2(
		snappedf((start.x + target.x) * 0.5, 4.0),
		start.y,
	)
	_path_points = PackedVector2Array([
		start,
		midpoint,
		Vector2(midpoint.x, target.y),
		target,
	])
	circuit.points = _path_points
	_path_length = 0.0
	for index in _path_points.size() - 1:
		_path_length += _path_points[index].distance_to(_path_points[index + 1])


func _point_on_path(progress: float) -> Vector2:
	var target_distance := progress * _path_length
	var travelled := 0.0
	for index in _path_points.size() - 1:
		var start := _path_points[index]
		var end := _path_points[index + 1]
		var segment_length := start.distance_to(end)
		if segment_length <= 0.0:
			continue
		if travelled + segment_length >= target_distance:
			return start.lerp(
				end,
				(target_distance - travelled) / segment_length,
			)
		travelled += segment_length
	return _path_points[-1]


func _is_closest_zone() -> bool:
	var distance := global_position.distance_squared_to(_player.global_position)
	for candidate in get_tree().get_nodes_in_group("kinetic_power_zones"):
		if candidate == self or candidate.get("_player") != _player:
			continue
		var candidate_distance := (
			(candidate as Node2D).global_position.distance_squared_to(_player.global_position)
		)
		if candidate_distance < distance:
			return false
		if is_equal_approx(candidate_distance, distance) and candidate.get_instance_id() < get_instance_id():
			return false
	return true


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	_player = body
	_last_player_position = body.global_position
	_activity_left = ACTIVITY_HOLD


func _on_body_exited(body: Node2D) -> void:
	if body == _player:
		_player = null

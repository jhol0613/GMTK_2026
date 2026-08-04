extends Node2D

@export var sprite: AnimatedSprite2D
@export var speed: float = 100.0
@export var ambient_interval_min: float = 3.0
@export var ambient_interval_max: float = 8.0
@export var fly_duration: float = 4.0
@export var respawn_delay_min: float = 12.0
@export var respawn_delay_max: float = 24.0
@export var respawn_check_interval: float = 0.5
@export var respawn_screen_margin: float = 24.0

@onready var _ambient_sound: AudioStreamPlayer2D = $AmbientSound
@onready var _fly_away_sound: AudioStreamPlayer2D = $FlyAwaySound

var _flying: bool = false
var _waiting_to_respawn: bool = false
var _flip: bool = false
var _ambient_muted: bool = false
var _rest_sprite_position: Vector2
var random_turn: SceneTreeTimer
var _ambient_timer: SceneTreeTimer


func _ready() -> void:
	add_to_group("pigeons")
	_rest_sprite_position = sprite.position
	_flip = randi() & 1
	if _flip:
		sprite.flip_h = true

	_schedule_turn()

	if _ambient_sound.stream != null:
		_ambient_sound.finished.connect(_on_ambient_sound_finished)
		_schedule_ambient()


func _process(delta: float) -> void:
	if _flying:
		if _flip:
			sprite.position += Vector2(-1, -1) * speed * delta
			return
		sprite.position += Vector2(1, -1) * speed * delta


func _turn() -> void:
	if _flying or _waiting_to_respawn:
		return

	match sprite.animation:
		"look_left":
			sprite.play("look_right")
		"look_right":
			sprite.play("look_left")

	_schedule_turn()


func _schedule_turn() -> void:
	random_turn = get_tree().create_timer(randf_range(1.0, 10.0))
	random_turn.timeout.connect(_turn)


func _on_ambient_sound_finished() -> void:
	if not _flying and not _waiting_to_respawn and _ambient_sound.stream != null:
		_schedule_ambient()


func _schedule_ambient() -> void:
	var minimum := minf(ambient_interval_min, ambient_interval_max)
	var maximum := maxf(ambient_interval_min, ambient_interval_max)
	_ambient_timer = get_tree().create_timer(randf_range(minimum, maximum))
	_ambient_timer.timeout.connect(_play_ambient)


func _play_ambient() -> void:
	if _flying or _waiting_to_respawn or _ambient_sound.stream == null:
		return
	if _ambient_muted:
		_schedule_ambient()
		return

	_ambient_sound.pitch_scale = randf_range(0.95, 1.05)
	_ambient_sound.play()


func set_ambient_muted(muted: bool) -> void:
	_ambient_muted = muted
	if muted:
		_ambient_sound.stop()


func _on_area_2d_body_entered(body: Node2D) -> void:
	if _flying or _waiting_to_respawn or not body.is_in_group("player"):
		return

	_flying = true

	if random_turn.timeout.is_connected(_turn):
		random_turn.timeout.disconnect(_turn)
	if _ambient_timer != null and _ambient_timer.timeout.is_connected(_play_ambient):
		_ambient_timer.timeout.disconnect(_play_ambient)

	_ambient_sound.stop()
	if _fly_away_sound.stream != null:
		_fly_away_sound.play()

	sprite.play("fly")
	await get_tree().create_timer(fly_duration).timeout
	_flying = false
	_waiting_to_respawn = true
	sprite.hide()

	var minimum := minf(respawn_delay_min, respawn_delay_max)
	var maximum := maxf(respawn_delay_min, respawn_delay_max)
	await get_tree().create_timer(randf_range(minimum, maximum)).timeout

	while _spawn_is_visible() or _player_is_in_spawn_area():
		await get_tree().create_timer(maxf(respawn_check_interval, 0.1)).timeout

	_respawn()


func _spawn_is_visible() -> bool:
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return false

	var viewport_size := get_viewport_rect().size / camera.zoom
	var view_rect := Rect2(
		camera.get_screen_center_position() - viewport_size * 0.5,
		viewport_size
	).grow(respawn_screen_margin)
	return view_rect.has_point(to_global(_rest_sprite_position))


func _player_is_in_spawn_area() -> bool:
	for body in $Area2D.get_overlapping_bodies():
		if body.is_in_group("player"):
			return true
	return false


func _respawn() -> void:
	sprite.position = _rest_sprite_position
	_flip = randi() & 1
	sprite.flip_h = _flip
	sprite.play("look_left" if _flip else "look_right")
	sprite.show()
	_waiting_to_respawn = false
	_schedule_turn()
	if _ambient_sound.stream != null:
		_schedule_ambient()

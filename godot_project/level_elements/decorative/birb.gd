extends Node2D

@export var sprite: AnimatedSprite2D
@export var speed: float = 100.0
@export var ambient_interval_min: float = 3.0
@export var ambient_interval_max: float = 8.0

@onready var _ambient_sound: AudioStreamPlayer2D = $AmbientSound
@onready var _fly_away_sound: AudioStreamPlayer2D = $FlyAwaySound

var _flying: bool = false
var _flip: bool = false
var random_turn: SceneTreeTimer
var _ambient_timer: SceneTreeTimer


func _ready() -> void:
	_flip = randi() & 1
	if _flip:
		sprite.flip_h = true

	random_turn = get_tree().create_timer(randf_range(1, 10))
	random_turn.timeout.connect(_turn)

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
	match sprite.animation:
		"look_left":
			sprite.play("look_right")
		"look_right":
			sprite.play("look_left")

	random_turn = get_tree().create_timer(randf_range(1, 10))
	random_turn.timeout.connect(_turn)


func _on_ambient_sound_finished() -> void:
	if not _flying and _ambient_sound.stream != null:
		_schedule_ambient()


func _schedule_ambient() -> void:
	var minimum := minf(ambient_interval_min, ambient_interval_max)
	var maximum := maxf(ambient_interval_min, ambient_interval_max)
	_ambient_timer = get_tree().create_timer(randf_range(minimum, maximum))
	_ambient_timer.timeout.connect(_play_ambient)


func _play_ambient() -> void:
	if _flying or _ambient_sound.stream == null:
		return

	_ambient_sound.pitch_scale = randf_range(0.95, 1.05)
	_ambient_sound.play()


func _on_area_2d_body_entered(body: Node2D) -> void:
	if _flying or not body.is_in_group("player"):
		return

	_flying = true

	if random_turn.timeout.is_connected(_turn):
		random_turn.timeout.disconnect(_turn)

	_ambient_sound.stop()
	if _fly_away_sound.stream != null:
		_fly_away_sound.play()

	sprite.play("fly")
	var life_timer := get_tree().create_timer(4.0)
	life_timer.timeout.connect(queue_free)

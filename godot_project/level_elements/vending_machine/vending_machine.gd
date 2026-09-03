extends Node2D
class_name VendingMachine

@export var start_broken := false

@export_group("Spark")
@export var spark_gap_min := 0.8
@export var spark_gap_max := 4.0
@export var spark_pitch_min := 0.9
@export var spark_pitch_max := 1.15
@export_range(-40.0, 0.0, 0.5) var spark_volume_db := -18.0
@export_range(0.0, 12.0, 0.5) var spark_volume_jitter_db := 4.0

@export_group("Current")
@export var electricity: AnimatedSprite2D
@export var current_every_loops := 3

@export_group("Compressor")
@export var compressor_cycle_min := 18.0
@export var compressor_cycle_max := 40.0
@export var shake_offsets: PackedFloat32Array = PackedFloat32Array([0.0, 1.4, 2.2, 2.5])
@export var shake_scales: PackedFloat32Array = PackedFloat32Array([1.0, 0.7, 0.9, 0.4])

@export_group("Shake")
@export var shake_duration := 0.3
@export var shake_strength := 2.0
@export var shake_frequency := 26.0

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _glow: AnimatedSprite2D = $AnimatedSprite2D/NightGlow/Overlay
@onready var _spark: AudioStreamPlayer2D = $Spark
@onready var _compressor: AudioStreamPlayer2D = $Compressor
@onready var _current: AudioStreamPlayer2D = $Current


var _sprite_home: Vector2
var _shake_token := 0


func _ready() -> void:
	_sprite_home = $AnimatedSprite2D.position
	_sprite.frame_changed.connect(_sync_glow)
	_sync_glow()
	if electricity != null:
		electricity.visible = false
	if start_broken:
		_sprite.play("broken")
		#_run_spark()
		#_run_current()
		#_run_compressor()

func fix(break_again := true):
	_sprite.play("idle")
	if break_again:
		_run_spark()
		_run_current()
		_run_compressor()
	#_sprite.play("idle")
	#if time <= 0:
		#return
	#await get_tree().create_timer(time).timeout
	#_sprite.play("broken")


func _sync_glow() -> void:
	if _glow.sprite_frames.has_animation(_sprite.animation):
		_glow.animation = _sprite.animation
		_glow.frame = _sprite.frame


func _loop_seconds() -> float:
	var frames := _sprite.sprite_frames
	var anim := _sprite.animation
	var speed := frames.get_animation_speed(anim)
	if speed <= 0.0:
		return 1.0
	return frames.get_frame_count(anim) / speed


func _run_current() -> void:
	while electricity != null or _current.stream != null:
		await get_tree().create_timer(
			_loop_seconds() * current_every_loops
		).timeout
		if not is_inside_tree():
			return
		_burst()


func _burst() -> void:
	if _current.stream != null:
		_current.play()
	if electricity == null:
		return
	electricity.visible = true
	electricity.frame = 0
	electricity.play()
	await electricity.animation_finished
	if is_inside_tree():
		electricity.visible = false


func _run_spark() -> void:
	while _spark.stream != null:
		await get_tree().create_timer(randf_range(spark_gap_min, spark_gap_max)).timeout
		if not is_inside_tree():
			return
		_spark.pitch_scale = randf_range(spark_pitch_min, spark_pitch_max)
		_spark.volume_db = spark_volume_db + randf_range(
			-spark_volume_jitter_db, spark_volume_jitter_db
		)
		_spark.play()


func shake(duration := -1.0, strength_scale := 1.0) -> void:
	_shake_token += 1
	var token := _shake_token
	var total: float = shake_duration if duration < 0.0 else duration
	var elapsed := 0.0
	while elapsed < total and is_inside_tree() and token == _shake_token:
		elapsed += get_process_delta_time()
		var decay := 1.0 - elapsed / total
		var phase := elapsed * shake_frequency * TAU
		var amount := shake_strength * strength_scale * decay
		_sprite.position = _sprite_home + Vector2(
			roundf(sin(phase) * amount),
			roundf(sin(phase * 2.0) * amount * 0.5)
		)
		await get_tree().process_frame
	if token == _shake_token:
		_sprite.position = _sprite_home


func _run_compressor() -> void:
	while _compressor.stream != null:
		await get_tree().create_timer(
			randf_range(compressor_cycle_min, compressor_cycle_max)
		).timeout
		if not is_inside_tree():
			return
		_compressor.play()
		_run_shake_schedule()


func _run_shake_schedule() -> void:
	var elapsed := 0.0
	for i in shake_offsets.size():
		var wait: float = shake_offsets[i] - elapsed
		if wait > 0.0:
			await get_tree().create_timer(wait).timeout
			if not is_inside_tree():
				return
		elapsed = shake_offsets[i]
		shake(-1.0, shake_scales[i] if i < shake_scales.size() else 1.0)
	_sprite.play("broken")

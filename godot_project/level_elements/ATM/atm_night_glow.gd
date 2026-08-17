extends Node2D

@export_range(0.0, 1.0, 0.01) var start_progress := 0.25
@export_range(0.0, 1.0, 0.01) var full_strength_progress := 0.75
@export_range(0.0, 1.0, 0.05) var max_alpha := 0.75

@onready var source: AnimatedSprite2D = get_parent()
@onready var overlay: AnimatedSprite2D = $Overlay

var _tween: Tween


func _ready() -> void:
	overlay.stop()
	source.animation_changed.connect(_sync_animation)
	source.frame_changed.connect(_sync_frame)
	_sync_animation()
	var total := (
		TimeManager.HOURS_PER_DAY
		* TimeManager.MINUTES_PER_HOUR
		* TimeManager.SECONDS_PER_MINUTE
	)
	var progress := 1.0 - float(TimeManager.total_seconds()) / float(total)
	set_day_progress(progress, 0.0)


func _sync_animation() -> void:
	if not overlay.sprite_frames.has_animation(source.animation):
		overlay.visible = false
		return
	overlay.visible = true
	overlay.animation = source.animation
	_sync_frame()


func _sync_frame() -> void:
	if not overlay.visible:
		return
	var count := overlay.sprite_frames.get_frame_count(overlay.animation)
	if count <= 0:
		return
	overlay.frame = mini(source.frame, count - 1)


func set_day_progress(progress: float, duration: float) -> void:
	if overlay == null:
		return
	var strength := clampf(
		inverse_lerp(start_progress, full_strength_progress, progress),
		0.0,
		1.0
	)
	var alpha := strength * max_alpha
	if _tween != null and _tween.is_valid():
		_tween.kill()
	if duration <= 0.0:
		overlay.modulate.a = alpha
		return
	_tween = create_tween()
	_tween.tween_property(overlay, "modulate:a", alpha, duration)

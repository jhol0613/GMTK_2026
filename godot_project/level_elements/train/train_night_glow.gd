extends Node2D

@export_range(0.0, 1.0, 0.01) var start_progress := 0.25
@export_range(0.0, 1.0, 0.01) var full_strength_progress := 0.75
@export_range(0.0, 1.0, 0.01) var max_alpha := 0.525

@onready var overlay: Sprite2D = $Overlay

var _tween: Tween


func _ready() -> void:
	_sync_source()
	var total := (
		TimeManager.HOURS_PER_DAY
		* TimeManager.MINUTES_PER_HOUR
		* TimeManager.SECONDS_PER_MINUTE
	)
	var progress := 1.0 - float(TimeManager.total_seconds()) / float(total)
	set_day_progress(progress, 0.0)


func _sync_source() -> void:
	var source := get_parent()
	if source is Sprite2D:
		overlay.centered = source.centered
		overlay.offset = source.offset
		overlay.flip_h = source.flip_h
		overlay.flip_v = source.flip_v
	elif source is AnimatedSprite2D:
		overlay.centered = source.centered
		overlay.offset = source.offset
		overlay.flip_h = source.flip_h
		overlay.flip_v = source.flip_v


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

extends Node2D

@export_range(0.0, 1.0, 0.01) var start_progress := 0.25
@export_range(0.0, 1.0, 0.01) var full_strength_progress := 0.75

@onready var source: AnimatedSprite2D = get_parent().get_node("AnimatedSprite2D")
@onready var overlay: AnimatedSprite2D = $AnimatedSprite2D

var _tween: Tween


func _ready() -> void:
	var total := TimeManager.HOURS_PER_DAY * TimeManager.MINUTES_PER_HOUR * TimeManager.SECONDS_PER_MINUTE
	set_day_progress(1.0 - float(TimeManager.total_seconds()) / float(total), 0.0)


func _process(_delta: float) -> void:
	overlay.animation = source.animation
	overlay.frame = source.frame
	overlay.frame_progress = source.frame_progress


func set_day_progress(progress: float, duration: float) -> void:
	if overlay == null:
		return
	var alpha := clampf(inverse_lerp(start_progress, full_strength_progress, progress), 0.0, 1.0)
	if _tween != null and _tween.is_valid():
		_tween.kill()
	if duration <= 0.0:
		overlay.modulate.a = alpha
		return
	_tween = create_tween()
	_tween.tween_property(overlay, "modulate:a", alpha, duration)

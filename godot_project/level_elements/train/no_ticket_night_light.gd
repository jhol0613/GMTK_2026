extends Sprite2D

@export_range(0.0, 1.0, 0.01) var start_progress := 0.25
@export_range(0.0, 1.0, 0.01) var full_strength_progress := 0.75
@export_range(0.0, 1.0, 0.01) var max_energy := 0.126

@onready var display_light: PointLight2D = $PointLight2D

var _tween: Tween


func _ready() -> void:
	var total := (
		TimeManager.HOURS_PER_DAY
		* TimeManager.MINUTES_PER_HOUR
		* TimeManager.SECONDS_PER_MINUTE
	)
	var progress := 1.0 - float(TimeManager.total_seconds()) / float(total)
	set_day_progress(progress, 0.0)


func set_day_progress(progress: float, duration: float) -> void:
	if display_light == null:
		return
	var strength := clampf(
		inverse_lerp(start_progress, full_strength_progress, progress),
		0.0,
		1.0
	)
	var energy := strength * max_energy
	if _tween != null and _tween.is_valid():
		_tween.kill()
	if duration <= 0.0:
		display_light.energy = energy
		return
	_tween = create_tween()
	_tween.tween_property(display_light, "energy", energy, duration)

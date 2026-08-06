extends Node2D

@export_range(0.0, 1.0, 0.01) var start_progress := 0.25
@export_range(0.0, 1.0, 0.01) var full_strength_progress := 0.75
@export_range(0.0, 4.0, 0.05) var max_energy := 0.85
@export_range(0.0, 1.0, 0.05) var max_glow_alpha := 1.0

@onready var _glow_overlay: Sprite2D = $GlowOverlay
@onready var _point_light: PointLight2D = $PointLight2D

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
	if _glow_overlay == null or _point_light == null:
		return

	var strength := clampf(inverse_lerp(start_progress, full_strength_progress, progress), 0.0, 1.0)
	var glow_alpha := strength * max_glow_alpha
	var light_energy := strength * max_energy

	if _tween != null and _tween.is_valid():
		_tween.kill()

	if duration <= 0.0:
		_glow_overlay.modulate.a = glow_alpha
		_point_light.energy = light_energy
		return

	_tween = create_tween().set_parallel(true)
	_tween.tween_property(_glow_overlay, "modulate:a", glow_alpha, duration)
	_tween.tween_property(_point_light, "energy", light_energy, duration)

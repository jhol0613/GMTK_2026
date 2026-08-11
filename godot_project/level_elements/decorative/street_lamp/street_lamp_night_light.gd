extends "res://visual_effects/day_night/night_light_2d.gd"

@export_range(0.0, 1.0, 0.01) var max_cone_alpha := 0.26

@onready var light_cone: ColorRect = $LightCone

var cone_tween: Tween


func set_day_progress(progress: float, duration: float) -> void:
	super.set_day_progress(progress, duration)
	if light_cone == null:
		return
	var strength := clampf(
		inverse_lerp(start_progress + _stagger, full_strength_progress + _stagger, progress),
		0.0,
		1.0
	)
	var cone_alpha := strength * max_cone_alpha
	if cone_tween != null and cone_tween.is_valid():
		cone_tween.kill()
	if duration <= 0.0:
		light_cone.modulate.a = cone_alpha
		return
	cone_tween = create_tween()
	cone_tween.tween_property(light_cone, "modulate:a", cone_alpha, duration)

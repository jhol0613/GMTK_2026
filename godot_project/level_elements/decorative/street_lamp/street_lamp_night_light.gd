extends "res://visual_effects/day_night/night_light_2d.gd"

@export_range(0.0, 1.0, 0.01) var max_cone_alpha := 0.26

@onready var light_cone: ColorRect = $LightCone

var cone_tween: Tween
var startup_flicker_tween: Tween
var _flicker_eligible := false
var _initial_state_received := false
var _reached_full_strength := false


func _ready() -> void:
	var hash_source := int(global_position.x) * 73856093 ^ int(global_position.y) * 19349663
	_flicker_eligible = absi(hash_source) % 100 < 15
	super._ready()


func set_day_progress(progress: float, duration: float) -> void:
	var strength := clampf(
		inverse_lerp(start_progress + _stagger, full_strength_progress + _stagger, progress),
		0.0,
		1.0
	)
	var should_flicker := (
		_initial_state_received
		and _flicker_eligible
		and not _reached_full_strength
		and strength >= 0.95
	)
	_reached_full_strength = strength >= 0.95
	_initial_state_received = true

	super.set_day_progress(progress, duration)
	if light_cone == null:
		return
	var cone_alpha := strength * max_cone_alpha
	if cone_tween != null and cone_tween.is_valid():
		cone_tween.kill()
	if duration <= 0.0:
		light_cone.modulate.a = cone_alpha
		return
	cone_tween = create_tween()
	cone_tween.tween_property(light_cone, "modulate:a", cone_alpha, duration)

	if should_flicker:
		_play_startup_flicker(strength)


func _play_startup_flicker(strength: float) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	if cone_tween != null and cone_tween.is_valid():
		cone_tween.kill()
	if startup_flicker_tween != null and startup_flicker_tween.is_valid():
		startup_flicker_tween.kill()

	var glow_target := strength * max_glow_alpha
	var energy_target := strength * max_energy
	var cone_target := strength * max_cone_alpha
	startup_flicker_tween = create_tween()
	startup_flicker_tween.tween_method(
		_apply_flicker_level.bind(glow_target, energy_target, cone_target),
		0.0,
		0.4,
		0.07
	)
	startup_flicker_tween.tween_method(
		_apply_flicker_level.bind(glow_target, energy_target, cone_target),
		0.4,
		0.08,
		0.05
	)
	startup_flicker_tween.tween_method(
		_apply_flicker_level.bind(glow_target, energy_target, cone_target),
		0.08,
		0.72,
		0.08
	)
	startup_flicker_tween.tween_method(
		_apply_flicker_level.bind(glow_target, energy_target, cone_target),
		0.72,
		0.22,
		0.05
	)
	startup_flicker_tween.tween_method(
		_apply_flicker_level.bind(glow_target, energy_target, cone_target),
		0.22,
		1.0,
		0.1
	)


func _apply_flicker_level(
	level: float,
	glow_target: float,
	energy_target: float,
	cone_target: float,
) -> void:
	_glow_overlay.modulate.a = glow_target * level
	_point_light.energy = energy_target * level
	light_cone.modulate.a = cone_target * level

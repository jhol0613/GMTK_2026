extends Node2D

@export_range(0.0, 1.0, 0.01) var start_progress := 0.25
@export_range(0.0, 1.0, 0.01) var full_strength_progress := 0.75
@export_range(0.0, 1.0, 0.05) var max_glow_alpha := 1.0
@export_range(0.0, 8.0, 0.05) var max_warm_energy := 4.0
@export_range(0.0, 1.0, 0.05) var max_terminal_energy := 0.1
@export_range(0.0, 1.0, 0.01) var max_cone_alpha := 0.26

@export var light_cones: Array[ColorRect] = []

@onready var source: AnimatedSprite2D = $"../Sprite2D"
@onready var glow_overlay: AnimatedSprite2D = $GlowOverlay
@onready var terminal_light: PointLight2D = $TerminalLight

#var warm_lights: Array[PointLight2D] = []

#var _tween: Tween
var cone_tween: Tween
var startup_tween: Tween
var _reached_full_strength := false

func _ready() -> void:
	#for child in get_children():
		#if child is PointLight2D and child.name.to_lower().begins_with("warm"):
			#warm_lights.append(child)
	
	glow_overlay.pause()
	var total := TimeManager.HOURS_PER_DAY * TimeManager.MINUTES_PER_HOUR * TimeManager.SECONDS_PER_MINUTE
	set_day_progress(1.0 - float(TimeManager.total_seconds()) / float(total), 0.0)


func _process(_delta: float) -> void:
	var has_animation := glow_overlay.sprite_frames.has_animation(source.animation)
	glow_overlay.visible = has_animation
	if not has_animation:
		return
	glow_overlay.animation = source.animation
	glow_overlay.frame = source.frame
	glow_overlay.frame_progress = source.frame_progress


func set_day_progress(progress: float, duration: float) -> void:
	var strength := clampf(
		inverse_lerp(start_progress, full_strength_progress, progress),
		0.0,
		1.0
	)
	
	_reached_full_strength = strength >= 0.95
	
	for cone in light_cones:
		if cone == null:
			return
		var cone_alpha := strength * max_cone_alpha
		if cone_tween != null and cone_tween.is_valid():
			cone_tween.kill()
		if duration <= 0.0:
			cone.modulate.a = cone_alpha
			return
		cone_tween = create_tween()
		cone_tween.tween_property(cone, "modulate:a", cone_alpha, duration)
	
	_play_startup(strength)

	#if glow_overlay == null or warm_lights.is_empty() or terminal_light == null:
		#return
	#var strength := clampf(inverse_lerp(start_progress, full_strength_progress, progress), 0.0, 1.0)
	#var alpha := strength * max_glow_alpha
	#var warm_energy := strength * max_warm_energy
	#var terminal_energy := strength * max_terminal_energy
	#if _tween != null and _tween.is_valid():
		#_tween.kill()
	#if duration <= 0.0:
		#glow_overlay.modulate.a = alpha
		#for warm_light in warm_lights:
			#warm_light.energy = warm_energy
		#terminal_light.energy = terminal_energy
		#return
	#_tween = create_tween().set_parallel(true)
	#_tween.tween_property(glow_overlay, "modulate:a", alpha, duration)
	#for warm_light in warm_lights:
		#_tween.tween_property(warm_light, "energy", warm_energy, duration)
	#_tween.tween_property(terminal_light, "energy", terminal_energy, duration)


func _play_startup(strength: float) -> void:
	if cone_tween != null and cone_tween.is_valid():
		cone_tween.kill()
	var cone_target := strength * max_cone_alpha
	startup_tween = create_tween()
	startup_tween.tween_method(
		_apply_level.bind(cone_target),
		0.22,
		1.0,
		0.1
	)


func _apply_level(
	level: float,
	cone_target: float,
) -> void:
	for cone in light_cones:
		cone.modulate.a = cone_target * level

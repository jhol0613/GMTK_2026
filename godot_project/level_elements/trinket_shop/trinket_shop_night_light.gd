extends Node2D

@export_range(0.0, 1.0, 0.01) var start_progress := 0.25
@export_range(0.0, 1.0, 0.01) var full_strength_progress := 0.75
@export_range(0.0, 1.0, 0.05) var max_glow_alpha := 1.0
@export_range(0.0, 1.0, 0.01) var max_cone_alpha := 0.26
@export var light_cones: Array[ColorRect] = []

@onready var source: AnimatedSprite2D = $"../Sprite2D"
@onready var glow_overlay: AnimatedSprite2D = $GlowOverlay

var _strength := 0.0
var _tween: Tween


func _ready() -> void:
	glow_overlay.pause()
	_sync_frame()
	var total := TimeManager.HOURS_PER_DAY * TimeManager.MINUTES_PER_HOUR * TimeManager.SECONDS_PER_MINUTE
	set_day_progress(1.0 - float(TimeManager.total_seconds()) / float(total), 0.0)


func _process(_delta: float) -> void:
	_sync_frame()


func _sync_frame() -> void:
	glow_overlay.visible = glow_overlay.sprite_frames.has_animation(source.animation)
	if glow_overlay.visible:
		glow_overlay.animation = source.animation
		glow_overlay.set_frame_and_progress(source.frame, source.frame_progress)


func set_day_progress(progress: float, duration: float) -> void:
	if glow_overlay == null:
		return
	var target := clampf(inverse_lerp(start_progress, full_strength_progress, progress), 0.0, 1.0)
	if _tween != null and _tween.is_valid():
		_tween.kill()
	if duration <= 0.0:
		_apply_strength(target)
	else:
		_tween = create_tween()
		_tween.tween_method(_apply_strength, _strength, target, duration)


func _apply_strength(strength: float) -> void:
	_strength = strength
	glow_overlay.modulate.a = strength * max_glow_alpha
	for cone in light_cones:
		if is_instance_valid(cone):
			cone.modulate.a = strength * max_cone_alpha

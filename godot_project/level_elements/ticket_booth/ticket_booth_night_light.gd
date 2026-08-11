extends Node2D

@export var source_sprite_path: NodePath
@export_range(0.0, 1.0, 0.01) var start_progress := 0.25
@export_range(0.0, 1.0, 0.01) var full_strength_progress := 0.75
@export_range(0.0, 4.0, 0.05) var max_energy := 0.64
@export_range(0.0, 1.0, 0.05) var max_glow_alpha := 0.43
@export_range(0.0, 1.0, 0.05) var max_area_alpha := 0.38

@onready var source_sprite := get_node(source_sprite_path) as AnimatedSprite2D
@onready var glow_overlay: AnimatedSprite2D = $GlowOverlay
@onready var area_glow: Sprite2D = $AreaGlow
@onready var point_light: PointLight2D = $PointLight2D

var light_tween: Tween


func _ready() -> void:
	source_sprite.frame_changed.connect(_sync_frame)
	_sync_frame()
	var total := (
		TimeManager.HOURS_PER_DAY
		* TimeManager.MINUTES_PER_HOUR
		* TimeManager.SECONDS_PER_MINUTE
	)
	var progress := 1.0 - float(TimeManager.total_seconds()) / float(total)
	set_day_progress(progress, 0.0)


func _sync_frame() -> void:
	glow_overlay.frame = source_sprite.frame


func set_day_progress(progress: float, duration: float) -> void:
	if glow_overlay == null or area_glow == null or point_light == null:
		return
	var strength := clampf(inverse_lerp(start_progress, full_strength_progress, progress), 0.0, 1.0)
	var glow_alpha := strength * max_glow_alpha
	var area_alpha := strength * max_area_alpha
	var light_energy := strength * max_energy
	if light_tween != null and light_tween.is_valid():
		light_tween.kill()
	if duration <= 0.0:
		glow_overlay.modulate.a = glow_alpha
		area_glow.modulate.a = area_alpha
		point_light.energy = light_energy
		return
	light_tween = create_tween().set_parallel(true)
	light_tween.tween_property(glow_overlay, "modulate:a", glow_alpha, duration)
	light_tween.tween_property(area_glow, "modulate:a", area_alpha, duration)
	light_tween.tween_property(point_light, "energy", light_energy, duration)

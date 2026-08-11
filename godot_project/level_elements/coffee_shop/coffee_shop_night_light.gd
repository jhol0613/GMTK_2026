extends Node2D

const TINT_POSITIONS := [0.0, 0.25, 0.65, 0.85, 1.0]
const WORLD_TINTS := [
	Color("ffffff"),
	Color("ffe8ce"),
	Color("e0a8a6"),
	Color("7180a8"),
	Color("52658e"),
]

@export_range(0.0, 1.0, 0.01) var start_progress := 0.25
@export_range(0.0, 1.0, 0.01) var full_strength_progress := 0.75
@export_range(0.0, 1.0, 0.05) var max_glow_alpha := 0.85
@export_range(0.0, 1.0, 0.05) var max_bakery_interior_alpha := 0.42
@export_range(0.0, 1.0, 0.05) var max_cyan_area_alpha := 0.14

@onready var glow_overlay: Sprite2D = $GlowOverlay
@onready var coffee_machine_untinted: Sprite2D = $CoffeeMachineUntinted
@onready var bakery_interior_glow: Sprite2D = $BakeryInteriorGlow
@onready var bakery_interior_glow_2: Sprite2D = $BakeryInteriorGlow2
@onready var cyan_area_glow: Sprite2D = $CyanAreaGlow

var light_tween: Tween


func _ready() -> void:
	var total := (
		TimeManager.HOURS_PER_DAY
		* TimeManager.MINUTES_PER_HOUR
		* TimeManager.SECONDS_PER_MINUTE
	)
	var progress := 1.0 - float(TimeManager.total_seconds()) / float(total)
	set_day_progress(progress, 0.0)


func set_day_progress(progress: float, duration: float) -> void:
	if glow_overlay == null or coffee_machine_untinted == null or bakery_interior_glow == null or bakery_interior_glow_2 == null or cyan_area_glow == null:
		return
	_apply_world_tint_compensation(progress)
	var strength := clampf(inverse_lerp(start_progress, full_strength_progress, progress), 0.0, 1.0)
	var glow_alpha := strength * max_glow_alpha
	var bakery_interior_alpha := strength * max_bakery_interior_alpha
	var cyan_area_alpha := strength * max_cyan_area_alpha
	if light_tween != null and light_tween.is_valid():
		light_tween.kill()
	if duration <= 0.0:
		glow_overlay.modulate.a = glow_alpha
		bakery_interior_glow.modulate.a = bakery_interior_alpha
		bakery_interior_glow_2.modulate.a = bakery_interior_alpha
		cyan_area_glow.modulate.a = cyan_area_alpha
		return
	light_tween = create_tween().set_parallel(true)
	light_tween.tween_property(glow_overlay, "modulate:a", glow_alpha, duration)
	light_tween.tween_property(bakery_interior_glow, "modulate:a", bakery_interior_alpha, duration)
	light_tween.tween_property(bakery_interior_glow_2, "modulate:a", bakery_interior_alpha, duration)
	light_tween.tween_property(cyan_area_glow, "modulate:a", cyan_area_alpha, duration)


func _apply_world_tint_compensation(progress: float) -> void:
	var tint := _get_world_tint(progress)
	var inverse := Color(
		1.0 / maxf(tint.r, 0.001),
		1.0 / maxf(tint.g, 0.001),
		1.0 / maxf(tint.b, 0.001),
		1.0,
	)
	glow_overlay.self_modulate = inverse
	coffee_machine_untinted.self_modulate = inverse
	bakery_interior_glow.self_modulate = inverse
	bakery_interior_glow_2.self_modulate = inverse
	cyan_area_glow.self_modulate = inverse


func _get_world_tint(progress: float) -> Color:
	for index in TINT_POSITIONS.size() - 1:
		if progress <= TINT_POSITIONS[index + 1]:
			var amount := inverse_lerp(
				TINT_POSITIONS[index],
				TINT_POSITIONS[index + 1],
				progress,
			)
			return WORLD_TINTS[index].lerp(WORLD_TINTS[index + 1], amount)
	return WORLD_TINTS[-1]

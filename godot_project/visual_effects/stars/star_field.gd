extends Node2D


@export var texture: Texture2D
@export var star_count: int = 70
@export var area := Rect2(0.0, 0.0, 1920.0, 1080.0)
@export var scale_range := Vector2(0.09, 0.2)
@export var color := Color("dff1ff")
@export var brightness_range := Vector2(0.55, 1.0)
@export var twinkle_period_range := Vector2(2.0, 6.0)
@export_range(0.0, 1.0, 0.05) var twinkle_depth := 0.5
@export_range(0.0, 1.0, 0.01) var start_progress := 0.45
@export_range(0.0, 1.0, 0.01) var full_strength_progress := 0.85

var _stars: Array[Sprite2D] = []
var _phases: PackedFloat32Array = PackedFloat32Array()
var _periods: PackedFloat32Array = PackedFloat32Array()
var _bases: PackedFloat32Array = PackedFloat32Array()
var _night_strength := 0.0
var _time := 0.0
var _progress := 0.0


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	var material := CanvasItemMaterial.new()
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD

	for i in star_count:
		var star := Sprite2D.new()
		star.texture = texture
		star.material = material
		star.position = Vector2(
			rng.randf_range(area.position.x, area.end.x),
			rng.randf_range(area.position.y, area.end.y)
		)
		var star_scale := rng.randf_range(scale_range.x, scale_range.y)
		star.scale = Vector2(star_scale, star_scale)
		star.modulate = Color(color.r, color.g, color.b, 0.0)
		add_child(star)

		_stars.append(star)
		_phases.append(rng.randf() * TAU)
		_periods.append(rng.randf_range(twinkle_period_range.x, twinkle_period_range.y))
		_bases.append(rng.randf_range(brightness_range.x, brightness_range.y))

	var total := (
		TimeManager.HOURS_PER_DAY
		* TimeManager.MINUTES_PER_HOUR
		* TimeManager.SECONDS_PER_MINUTE
	)
	set_day_progress(1.0 - float(TimeManager.total_seconds()) / float(total), 0.0)
	_night_strength = _target_strength()


func set_day_progress(progress: float, _duration: float) -> void:
	_progress = progress


func _target_strength() -> float:
	return clampf(
		inverse_lerp(start_progress, full_strength_progress, _progress),
		0.0,
		1.0
	)


func _process(delta: float) -> void:
	_time += delta
	_night_strength = move_toward(_night_strength, _target_strength(), delta * 0.5)
	if _night_strength <= 0.0:
		for star in _stars:
			star.modulate.a = 0.0
		return

	for index in _stars.size():
		var twinkle := 1.0 - twinkle_depth * (
			0.5 + 0.5 * sin(_time * TAU / _periods[index] + _phases[index])
		)
		_stars[index].modulate.a = _bases[index] * twinkle * _night_strength

extends Node

@export_range(0.0, 1.0, 0.01) var start_progress := 0.25
@export_range(0.0, 1.0, 0.01) var full_strength_progress := 0.75
@export_range(0.0, 2.0, 0.05) var light_energy := 2.0

const PARTICLE_SHADER := preload("res://visual_effects/day_night/hoverthruster_particle.gdshader")
const LIGHT_TEXTURE := preload("res://visual_effects/day_night/light_radial.png")

const TINT_POSITIONS := [0.0, 0.25, 0.65, 0.85, 1.0]
const WORLD_TINTS := [
	Color("ffffff"),
	Color("ffe8ce"),
	Color("e0a8a6"),
	Color("7180a8"),
	Color("52658e"),
]

var _train_material := ShaderMaterial.new()
var _emitter: CanvasItem
var _light: PointLight2D
var _light_max_energy: float
var _occluding_layers: Array[TileMapLayer] = []
var _compensation := Vector3.ONE
var _tween: Tween


func _ready() -> void:
	add_to_group("night_lights")
	_train_material.shader = PARTICLE_SHADER
	_train_material.set_shader_parameter("full_sprite", true)
	_configure_thruster($".")
	_collect_occluding_layers()
	var total := (
		TimeManager.HOURS_PER_DAY
		* TimeManager.MINUTES_PER_HOUR
		* TimeManager.SECONDS_PER_MINUTE
	)
	var progress := 1.0 - float(TimeManager.total_seconds()) / float(total)
	set_day_progress(progress, 0.0)
	set_process(not _occluding_layers.is_empty())


func _process(_delta: float) -> void:
	_light.enabled = not _is_covered(_emitter, _light.global_position)


func _configure_thruster(sprite: CanvasItem) -> void:
	sprite.material = _train_material

	var light := PointLight2D.new()
	light.name = "CyanLight"
	light.color = Color("63d8e4")
	light.energy = 0.0
	light.texture = LIGHT_TEXTURE
	
	sprite.add_child(light)
	_emitter = sprite
	_light = light
	_light_max_energy = light_energy


func _collect_occluding_layers() -> void:
	for node in get_tree().root.find_children("*", "TileMapLayer", true, false):
		_occluding_layers.append(node as TileMapLayer)


func _is_covered(emitter: CanvasItem, sample_position: Vector2) -> bool:
	var emitter_z := _get_effective_z(emitter)
	for layer in _occluding_layers:
		if not is_instance_valid(layer) or not layer.is_visible_in_tree():
			continue
		if _get_effective_z(layer) < emitter_z:
			continue
		var cell := layer.local_to_map(layer.to_local(sample_position))
		if layer.get_cell_source_id(cell) != -1:
			return true
	return false


func _get_effective_z(item: CanvasItem) -> int:
	var result := item.z_index
	if not item.z_as_relative:
		return result
	var parent := item.get_parent()
	while parent is CanvasItem:
		var canvas_parent := parent as CanvasItem
		result += canvas_parent.z_index
		if not canvas_parent.z_as_relative:
			break
		parent = canvas_parent.get_parent()
	return result


func set_day_progress(progress: float, duration: float) -> void:
	var tint := _get_world_tint(progress)
	var target_compensation := Vector3(
		1.0 / maxf(tint.r, 0.01),
		1.0 / maxf(tint.g, 0.01),
		1.0 / maxf(tint.b, 0.01),
	)
	var strength := clampf(inverse_lerp(start_progress, full_strength_progress, progress), 0.0, 1.0)
	if _tween != null and _tween.is_valid():
		_tween.kill()
	if duration <= 0.0:
		_set_compensation(target_compensation)
		_light.energy = strength * _light_max_energy
		return
	_tween = create_tween().set_parallel(true)
	_tween.tween_method(_set_compensation, _compensation, target_compensation, duration)
	
	_tween.tween_property(
		_light,
		"energy",
		strength * _light_max_energy,
		duration,
		)


func _set_compensation(value: Vector3) -> void:
	_compensation = value
	_train_material.set_shader_parameter("tint_compensation", value)


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

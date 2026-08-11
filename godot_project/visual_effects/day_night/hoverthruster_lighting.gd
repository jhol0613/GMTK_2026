extends Node

@export var target_root_path := NodePath(".")
@export_range(0.0, 1.0, 0.01) var start_progress := 0.25
@export_range(0.0, 1.0, 0.01) var full_strength_progress := 0.75
@export_range(0.0, 2.0, 0.05) var static_light_energy := 2.0
@export_range(0.0, 2.0, 0.05) var train_light_energy := 2.0

const PARTICLE_SHADER := preload("res://visual_effects/day_night/hoverthruster_particle.gdshader")
const LIGHT_TEXTURE := preload("res://visual_effects/day_night/light_radial.png")
const LIGHT_DISABLED_THRUSTERS := [
	&"Hoverthruster8",
	&"Hoverthruster9",
	&"Hoverthruster10",
	&"Hoverthruster11",
]
const TINT_POSITIONS := [0.0, 0.25, 0.65, 0.85, 1.0]
const WORLD_TINTS := [
	Color("ffffff"),
	Color("ffe8ce"),
	Color("e0a8a6"),
	Color("7180a8"),
	Color("52658e"),
]

var _static_material := ShaderMaterial.new()
var _train_material := ShaderMaterial.new()
var _emitters: Array[CanvasItem] = []
var _lights: Array[PointLight2D] = []
var _light_max_energies: Array[float] = []
var _occluding_layers: Array[TileMapLayer] = []
var _compensation := Vector3.ONE
var _tween: Tween


func _ready() -> void:
	add_to_group("night_lights")
	_static_material.shader = PARTICLE_SHADER
	_train_material.shader = PARTICLE_SHADER
	_train_material.set_shader_parameter("full_sprite", true)
	_collect_thrusters(get_node(target_root_path))
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
	for index in _lights.size():
		_lights[index].enabled = not _is_covered(
			_emitters[index],
			_lights[index].global_position,
		)


func _collect_thrusters(node: Node) -> void:
	for child in node.get_children():
		if child is AnimatedSprite2D and child.name.begins_with("HoverSparcle"):
			_configure_thruster(child, true)
		elif child is Sprite2D and child.name.begins_with("Hoverthruster"):
			_configure_thruster(child, false)
		_collect_thrusters(child)


func _configure_thruster(sprite: CanvasItem, is_train_particle: bool) -> void:
	sprite.material = _train_material if is_train_particle else _static_material
	if not is_train_particle and sprite.name in LIGHT_DISABLED_THRUSTERS:
		return
	var light := PointLight2D.new()
	light.name = "CyanLight"
	light.color = Color("63d8e4")
	light.energy = 0.0
	light.texture = LIGHT_TEXTURE
	light.position = Vector2(0, 1 if is_train_particle else 16)
	light.texture_scale = 2.0 if is_train_particle else 2.0
	sprite.add_child(light)
	_emitters.append(sprite)
	_lights.append(light)
	_light_max_energies.append(train_light_energy if is_train_particle else static_light_energy)


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
		for index in _lights.size():
			_lights[index].energy = strength * _light_max_energies[index]
		return
	_tween = create_tween().set_parallel(true)
	_tween.tween_method(_set_compensation, _compensation, target_compensation, duration)
	for index in _lights.size():
		_tween.tween_property(
			_lights[index],
			"energy",
			strength * _light_max_energies[index],
			duration,
		)


func _set_compensation(value: Vector3) -> void:
	_compensation = value
	_static_material.set_shader_parameter("tint_compensation", value)
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

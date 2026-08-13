extends Node2D

@export_range(0.0, 5.0, 0.05) var transition_duration := 0.6

const LAYER_PATHS := [
	^"Blue",
	^"FarClouds",
	^"FloatingIslands",
	^"CloseClouds",
]

const DUSK_TEXTURES := [
	preload("uid://bglgptwvrigom"),
	preload("uid://dhr3vbrjwb8vl"),
	preload("uid://jayqwtmr11xa"),
	preload("uid://1d7vwovscjxu"),
]

const NIGHT_TEXTURES := [
	preload("uid://bx1cwgmqc50oe"),
	preload("uid://c4kwblfnl6uh0"),
	preload("uid://djjk26tjjykp1"),
	preload("uid://bu4essosi3i0d"),
]

const TINT_POSITIONS := [0.0, 0.25, 0.65, 0.85, 0.90]
const WORLD_TINTS := [
	Color("ffffff"),
	Color("ffe8ce"),
	Color("e0a8a6"),
	Color("7180a8"),
	Color("52658e"),
]

var _day_sprites: Array[Sprite2D] = []
var _dusk_sprites: Array[Sprite2D] = []
var _night_sprites: Array[Sprite2D] = []
var _world_items: Array[CanvasItem] = []
var _world_base_modulates: Array[Color] = []
var _fade_tween: Tween


func _ready() -> void:
	_collect_world_items()
	_create_background_sets()
	TimeManager.time_changed.connect(_on_time_changed)
	_update_background(TimeManager.hour, TimeManager.minute, TimeManager.second, false)


func _collect_world_items() -> void:
	for child in get_parent().get_children():
		if child == self or child is CanvasLayer or child is Camera2D:
			continue
		if child.is_in_group("night_lights"):
			continue
		if child is CanvasItem:
			var item := child as CanvasItem
			_world_items.append(item)
			_world_base_modulates.append(item.modulate)


func _create_background_sets() -> void:
	for index in LAYER_PATHS.size():
		var layer := get_node(LAYER_PATHS[index])
		var day_sprite := layer.get_node("Sprite2D") as Sprite2D
		var dusk_sprite := day_sprite.duplicate() as Sprite2D
		var night_sprite := day_sprite.duplicate() as Sprite2D

		dusk_sprite.name = "Dusk"
		night_sprite.name = "Night"
		dusk_sprite.texture = DUSK_TEXTURES[index]
		night_sprite.texture = NIGHT_TEXTURES[index]
		layer.add_child(dusk_sprite)
		layer.add_child(night_sprite)

		_day_sprites.append(day_sprite)
		_dusk_sprites.append(dusk_sprite)
		_night_sprites.append(night_sprite)


func _on_time_changed(hour: int, minute: int, second: int) -> void:
	_update_background(hour, minute, second, true)


func _update_background(hour: int, minute: int, second: int, animate: bool) -> void:
	var remaining := (
		hour * TimeManager.MINUTES_PER_HOUR * TimeManager.SECONDS_PER_MINUTE
		+ minute * TimeManager.SECONDS_PER_MINUTE
		+ second
	)
	var total := (
		TimeManager.HOURS_PER_DAY
		* TimeManager.MINUTES_PER_HOUR
		* TimeManager.SECONDS_PER_MINUTE
	)
	var ratio := clampf(float(remaining) / float(total), 0.0, 1.0)
	var progress := 1.0 - ratio
	var world_tint := _get_world_tint(progress)
	var day_alpha := 0.0
	var dusk_alpha := 0.0
	var night_alpha := 0.0

	if ratio >= 0.65:
		day_alpha = 1.0
	elif ratio >= 0.35:
		var dusk_progress := inverse_lerp(0.65, 0.35, ratio)
		day_alpha = 1.0 - dusk_progress
		dusk_alpha = dusk_progress
	else:
		var night_progress := clampf(inverse_lerp(0.35, 0.10, ratio), 0.0, 1.0)
		dusk_alpha = 1.0 - night_progress
		night_alpha = night_progress

	_set_visual_state(
		day_alpha,
		dusk_alpha,
		night_alpha,
		world_tint,
		animate and remaining > 0,
	)
	get_tree().call_group(
		"night_lights",
		"set_day_progress",
		progress,
		transition_duration if animate and remaining > 0 else 0.0,
	)


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


func _set_visual_state(
	day_alpha: float,
	dusk_alpha: float,
	night_alpha: float,
	world_tint: Color,
	animate: bool,
) -> void:
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()

	if not animate or transition_duration <= 0.0:
		for index in _day_sprites.size():
			_day_sprites[index].modulate.a = day_alpha
			_dusk_sprites[index].modulate.a = dusk_alpha
			_night_sprites[index].modulate.a = night_alpha
		for index in _world_items.size():
			_world_items[index].modulate = _world_base_modulates[index] * world_tint
			_world_items[index].modulate.a = _world_base_modulates[index].a
		_counteract_tint_on_lights(world_tint)
		return

	_fade_tween = create_tween().set_parallel(true)
	for index in _day_sprites.size():
		_fade_tween.tween_property(
			_day_sprites[index],
			"modulate:a",
			day_alpha,
			transition_duration,
		)
		_fade_tween.tween_property(
			_dusk_sprites[index],
			"modulate:a",
			dusk_alpha,
			transition_duration,
		)
		_fade_tween.tween_property(
			_night_sprites[index],
			"modulate:a",
			night_alpha,
			transition_duration,
		)
	for index in _world_items.size():
		var target := _world_base_modulates[index] * world_tint
		target.a = _world_base_modulates[index].a
		_fade_tween.tween_property(
			_world_items[index],
			"modulate",
			target,
			transition_duration,
		)
	_counteract_tint_on_lights(world_tint)


func _counteract_tint_on_lights(world_tint: Color) -> void:
	var inverse := Color(
		1.0 / maxf(world_tint.r, 0.01),
		1.0 / maxf(world_tint.g, 0.01),
		1.0 / maxf(world_tint.b, 0.01),
		1.0
	)
	var level_root := get_parent()
	for node in get_tree().get_nodes_in_group("night_lights"):
		var item := node as CanvasItem
		if item == null:
			continue
		if item.get_parent() == level_root:
			continue
		item.modulate = inverse

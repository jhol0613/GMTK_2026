extends Node2D
class_name FireflyField

## Spawns slow drifting fireflies over grass tiles after dusk.
##
## The grass area is read from the TileMapLayers in the "footstep_surfaces"
## group, using the same `footstep_surface` custom data the player uses for
## footstep sounds, so no region has to be painted by hand.
##
## Add this node to a level and put it in the "night_lights" group: the day/night
## background calls `set_day_progress` on that group every time the clock moves.

@export_group("Look")
@export var texture: Texture2D
@export var color := Color("a8ff60")
## Multiplies the tint. Above 1.0 the additive blend pushes the glow brighter.
@export_range(0.5, 3.0, 0.05) var brightness := 1.5
@export var scale_range := Vector2(0.08, 0.16)
@export var sprite_z_index: int = 2

@export_group("Population")
@export var max_count: int = 12
## Fireflies start showing up at this point of the day and peak at the next one.
@export_range(0.0, 1.0, 0.01) var appear_start_progress := 0.55
@export_range(0.0, 1.0, 0.01) var full_strength_progress := 0.85
@export var spawn_check_interval := 1.2
@export var lifetime_range := Vector2(10.0, 22.0)
@export var fade_duration := 1.2
## Chance for a new firefly to appear next to an existing one instead of
## anywhere in the grass, which makes them gather in loose clusters.
@export_range(0.0, 1.0, 0.05) var cluster_chance := 0.3
@export var cluster_radius := 60.0
@export var min_distance_from_player := 60.0

@export_group("Movement")
@export var speed_range := Vector2(6.0, 14.0)
@export var turn_rate := 2.5
@export var bob_amplitude_range := Vector2(2.0, 5.0)
@export var bob_period_range := Vector2(2.0, 4.0)
@export var edge_lookahead := 16.0
@export var player_push_radius := 40.0
@export var player_push_strength := 18.0
## Fireflies keep away from lamps and shop windows, dimming as they get close.
@export var light_avoid_radius := 90.0
@export_range(0.0, 1.0, 0.05) var light_min_brightness := 0.15

@export_group("Blink")
@export var blink_period_range := Vector2(1.6, 4.0)
@export_range(0.0, 1.0, 0.05) var silent_chance := 0.4


class Firefly:
	var sprite: Sprite2D
	var alive := false
	var age := 0.0
	var lifetime := 0.0
	var home := Vector2.ZERO
	var pos := Vector2.ZERO
	var heading := 0.0
	var speed := 0.0
	var noise := FastNoiseLite.new()
	var noise_t := 0.0
	var bob_amplitude := 0.0
	var bob_period := 1.0
	var bob_phase := 0.0
	var blink_period := 2.0
	var blink_t := 0.0
	var blink_cycle := -1
	var silent := false


var _pool: Array[Firefly] = []
var _grass_layers: Array[TileMapLayer] = []
var _spawn_points: PackedVector2Array = PackedVector2Array()
var _night_strength := 0.0
var _target_strength := 0.0
var _spawn_timer := 0.0
var _rng := RandomNumberGenerator.new()
var _light_sources: Array[Node2D] = []


func _ready() -> void:
	_rng.randomize()
	_collect_grass()
	_collect_lights()
	_build_pool()

	var total := (
		TimeManager.HOURS_PER_DAY
		* TimeManager.MINUTES_PER_HOUR
		* TimeManager.SECONDS_PER_MINUTE
	)
	var progress := 1.0 - float(TimeManager.total_seconds()) / float(total)
	set_day_progress(progress, 0.0)
	_night_strength = _target_strength


## Called by the day/night background through the "night_lights" group.
func set_day_progress(progress: float, _duration: float) -> void:
	_target_strength = clampf(
		inverse_lerp(appear_start_progress, full_strength_progress, progress),
		0.0,
		1.0
	)


func _collect_grass() -> void:
	for node in get_tree().get_nodes_in_group("footstep_surfaces"):
		var layer := node as TileMapLayer
		if layer == null:
			continue
		var has_grass := false
		for cell in layer.get_used_cells():
			var data := layer.get_cell_tile_data(cell)
			if data == null:
				continue
			if StringName(data.get_custom_data("footstep_surface")) != &"grass":
				continue
			has_grass = true
			_spawn_points.append(
				layer.to_global(layer.map_to_local(cell))
			)
		if has_grass:
			_grass_layers.append(layer)

	if _spawn_points.is_empty():
		push_warning("FireflyField: no grass tiles found, fireflies stay hidden.")


func _collect_lights() -> void:
	for node in get_tree().get_nodes_in_group("night_lights"):
		if node == self:
			continue
		var light := node as Node2D
		if light != null:
			_light_sources.append(light)


## 1.0 out in the dark, dropping towards `light_min_brightness` near a lamp.
func _light_factor(point: Vector2) -> float:
	if light_avoid_radius <= 0.0:
		return 1.0
	var closest := INF
	for light in _light_sources:
		if not is_instance_valid(light):
			continue
		closest = minf(closest, point.distance_to(light.global_position))
	if closest >= light_avoid_radius:
		return 1.0
	return lerpf(light_min_brightness, 1.0, closest / light_avoid_radius)


func _build_pool() -> void:
	var material := CanvasItemMaterial.new()
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	var tint := Color(
		color.r * brightness,
		color.g * brightness,
		color.b * brightness,
		0.0
	)

	for i in max_count:
		var firefly := Firefly.new()
		firefly.sprite = Sprite2D.new()
		firefly.sprite.texture = texture
		firefly.sprite.material = material
		firefly.sprite.z_index = sprite_z_index
		firefly.sprite.modulate = tint
		firefly.sprite.visible = false
		firefly.noise.noise_type = FastNoiseLite.TYPE_PERLIN
		firefly.noise.seed = _rng.randi()
		firefly.noise.frequency = 0.25
		add_child(firefly.sprite)
		_pool.append(firefly)


func _process(delta: float) -> void:
	_night_strength = move_toward(_night_strength, _target_strength, delta * 0.5)

	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_timer = spawn_check_interval
		_try_spawn()

	for firefly in _pool:
		if firefly.alive:
			_update_firefly(firefly, delta)


func _target_count() -> int:
	return int(round(max_count * _night_strength))


func _alive_count() -> int:
	var count := 0
	for firefly in _pool:
		if firefly.alive:
			count += 1
	return count


func _try_spawn() -> void:
	if _spawn_points.is_empty():
		return
	if _alive_count() >= _target_count():
		return
	var spot := _pick_spawn_point()
	if spot == Vector2.INF:
		return
	for firefly in _pool:
		if not firefly.alive:
			_activate(firefly, spot)
			return


func _pick_spawn_point() -> Vector2:
	var player := get_tree().get_first_node_in_group("player") as Node2D

	# Prefer sitting next to a firefly that is already out.
	if _rng.randf() < cluster_chance:
		var neighbours: Array[Firefly] = []
		for firefly in _pool:
			if firefly.alive:
				neighbours.append(firefly)
		if not neighbours.is_empty():
			var anchor: Firefly = neighbours[_rng.randi() % neighbours.size()]
			var offset := Vector2(
				_rng.randf_range(-cluster_radius, cluster_radius),
				_rng.randf_range(-cluster_radius, cluster_radius)
			)
			var candidate := anchor.pos + offset
			if _is_grass(candidate) and _is_far_enough(candidate, player):
				return candidate

	for attempt in 12:
		var candidate := _spawn_points[_rng.randi() % _spawn_points.size()]
		candidate += Vector2(_rng.randf_range(-8.0, 8.0), _rng.randf_range(-8.0, 8.0))
		if not _is_on_screen(candidate):
			continue
		if not _is_far_enough(candidate, player):
			continue
		return candidate
	return Vector2.INF


func _is_far_enough(point: Vector2, player: Node2D) -> bool:
	if player == null:
		return true
	return point.distance_to(player.global_position) >= min_distance_from_player


func _is_on_screen(point: Vector2) -> bool:
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return true
	var half := get_viewport_rect().size / (2.0 * camera.zoom)
	var view := Rect2(camera.get_screen_center_position() - half, half * 2.0)
	return view.grow(64.0).has_point(point)


func _is_grass(point: Vector2) -> bool:
	for layer in _grass_layers:
		var cell := layer.local_to_map(layer.to_local(point))
		var data := layer.get_cell_tile_data(cell)
		if data == null:
			continue
		if StringName(data.get_custom_data("footstep_surface")) == &"grass":
			return true
	return false


func _activate(firefly: Firefly, spot: Vector2) -> void:
	firefly.alive = true
	firefly.age = 0.0
	firefly.lifetime = _rng.randf_range(lifetime_range.x, lifetime_range.y)
	firefly.home = spot
	firefly.pos = spot
	firefly.heading = _rng.randf() * TAU
	firefly.speed = _rng.randf_range(speed_range.x, speed_range.y)
	firefly.noise_t = _rng.randf() * 100.0
	firefly.bob_amplitude = _rng.randf_range(bob_amplitude_range.x, bob_amplitude_range.y)
	firefly.bob_period = _rng.randf_range(bob_period_range.x, bob_period_range.y)
	firefly.bob_phase = _rng.randf() * TAU
	firefly.blink_period = _rng.randf_range(blink_period_range.x, blink_period_range.y)
	firefly.blink_t = _rng.randf() * firefly.blink_period
	firefly.blink_cycle = -1
	firefly.silent = false

	var sprite_scale := _rng.randf_range(scale_range.x, scale_range.y)
	firefly.sprite.scale = Vector2(sprite_scale, sprite_scale)
	firefly.sprite.global_position = spot
	firefly.sprite.visible = true


func _update_firefly(firefly: Firefly, delta: float) -> void:
	firefly.age += delta
	if firefly.age >= firefly.lifetime:
		firefly.alive = false
		firefly.sprite.visible = false
		return

	# Smooth wandering: noise nudges the heading instead of picking new targets.
	firefly.noise_t += delta
	firefly.heading += firefly.noise.get_noise_1d(firefly.noise_t) * turn_rate * delta

	var direction := Vector2.RIGHT.rotated(firefly.heading)
	var ahead := firefly.pos + direction * edge_lookahead
	if not _is_grass(ahead):
		# Steer back towards where it started rather than leaving the grass.
		firefly.heading = firefly.pos.direction_to(firefly.home).angle()
		direction = Vector2.RIGHT.rotated(firefly.heading)

	firefly.pos += direction * firefly.speed * delta

	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player != null and player_push_radius > 0.0:
		var away := player.global_position.direction_to(firefly.pos)
		var distance := firefly.pos.distance_to(player.global_position)
		if distance < player_push_radius and distance > 0.01:
			var push := 1.0 - distance / player_push_radius
			firefly.pos += away * push * player_push_strength * delta

	firefly.bob_phase += delta * TAU / firefly.bob_period
	var bob := sin(firefly.bob_phase) * firefly.bob_amplitude
	firefly.sprite.global_position = firefly.pos + Vector2(0.0, bob)

	firefly.sprite.modulate.a = _current_alpha(firefly, delta)


func _current_alpha(firefly: Firefly, delta: float) -> float:
	firefly.blink_t += delta
	var cycle := int(firefly.blink_t / firefly.blink_period)
	if cycle != firefly.blink_cycle:
		firefly.blink_cycle = cycle
		firefly.silent = _rng.randf() < silent_chance

	var blink := 0.0
	if not firefly.silent:
		blink = _blink_envelope(
			fmod(firefly.blink_t, firefly.blink_period) / firefly.blink_period
		)

	var fade := 1.0
	if firefly.age < fade_duration:
		fade = firefly.age / fade_duration
	elif firefly.age > firefly.lifetime - fade_duration:
		fade = (firefly.lifetime - firefly.age) / fade_duration

	return blink * clampf(fade, 0.0, 1.0) * _night_strength * _light_factor(firefly.pos)


## Asymmetric flash: snaps on, lingers, then decays. Reads far more organic
## than a sine wave, and the dark stretch hides spawning and despawning.
func _blink_envelope(x: float) -> float:
	const RISE := 0.06
	const HOLD := 0.06
	const DECAY := 0.26
	if x < RISE:
		return x / RISE
	if x < RISE + HOLD:
		return 1.0
	if x < RISE + HOLD + DECAY:
		return 1.0 - (x - RISE - HOLD) / DECAY
	return 0.0

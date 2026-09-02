class_name CoffeeNpc
extends Npc

const GROUND_OBJECT_GROUP := &"coffee_npc_ground_object"
const COFFEE_ANIMATION_PREFIX := "coffee_"
const NORMAL_SPEED := 300.0
const PLAYER_COFFEE_SPEED := 150.0

@export var action_point: Marker2D
@export var spawn_point: Marker2D
@export var shop_point: Marker2D
@export var spawned_object_scene: PackedScene
@export var action_animation: StringName = &"coffee_throw"
@export var shop_animation: StringName = &"coffee_drink"
@export var release_frame: int = 1
@export var trigger_distance: float = 4.0
@export var round_trips_before_drop: int = 16

var _busy := false
var _has_coffee := true
var _patrol_forward := true
var _completed_round_trips := 0
var _spawned_object: DroppedCoffee
func _ready() -> void:
	super._ready()
	TimeManager.time_scale_changed.connect(_on_time_scale_changed)
	_on_time_scale_changed(TimeManager.time_scale)


func _on_time_scale_changed(scale: float) -> void:
	walk_speed = PLAYER_COFFEE_SPEED if scale < 1.0 else NORMAL_SPEED


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if (
		_state != State.PATROL
		or _busy
		or _ground_object_exists()
		or _completed_round_trips < round_trips_before_drop
		or action_point == null
	):
		return
	if global_position.distance_to(action_point.global_position) <= trigger_distance:
		_busy = true
		_drop_and_visit_shop()


func _patrol(delta: float) -> void:
	if patrol_path == null or patrol_path.curve == null:
		_state = State.IDLE
		return
	var curve := patrol_path.curve
	if curve.point_count < 2:
		_state = State.IDLE
		return
	var index := curve.point_count - 1 if _patrol_forward else 0
	var target := patrol_path.to_global(curve.get_point_position(index))
	var before := global_position
	var arrived := _walk_towards(target, delta)
	if before.is_equal_approx(global_position) and _blocked_by_player():
		velocity = Vector2.ZERO
		_animate(Vector2.ZERO)
		return
	if arrived:
		if not _patrol_forward:
			_completed_round_trips += 1
		_patrol_forward = not _patrol_forward


func _animate(direction: Vector2) -> void:
	_sprite.speed_scale = 1.0 if direction == Vector2.ZERO else maxf(walk_speed / 80.0, 0.1)
	super._animate(direction)


func _drop_and_visit_shop() -> void:
	await go_to(action_point.global_position, false)
	_state = State.ACTING
	velocity = Vector2.ZERO
	_set_interactable(false)
	_face_spawn_point()
	_sprite.speed_scale = 1.0 if TimeManager.time_scale < 1.0 else 1.3
	
	_sprite.play(action_animation)
	await _sprite.animation_finished
	_sprite.speed_scale = 1.0
	# _wait_for_release_frame()
	_has_coffee = not _spawn_object()
	# await _finish_action_animation()
	
	
	await go_to(_left_patrol_point(), false)
	_set_interactable(false)
	if shop_point != null:
		await go_to(shop_point.global_position, false)
		_set_interactable(false)
		await _play_shop_action()
		_has_coffee = true
		_on_time_scale_changed(TimeManager.time_scale)
		await go_to(_left_patrol_point(), false)
	
	_patrol_forward = true
	_completed_round_trips = 0
	_busy = false
	_set_interactable(true)
	_start_patrol()


func _play_shop_action() -> void:
	_state = State.ACTING
	velocity = Vector2.ZERO
	_sprite.speed_scale = 1.0 if TimeManager.time_scale < 1.0 else 2.0
	
	_sprite.play(shop_animation)
	await _sprite.animation_finished
	_sprite.speed_scale = 1.0



#func _wait_for_release_frame() -> void:
#	var count := _sprite.sprite_frames.get_frame_count(action_animation)
#	var target := clampi(release_frame, 0, count - 1)
#	while _sprite.frame < target:
#		await _sprite.frame_changed


#func _finish_action_animation() -> void:
#	await _finish_animation(action_animation)


#func _finish_animation(animation: StringName) -> void:
#	if not _sprite.sprite_frames.get_animation_loop(animation):
#		await _sprite.animation_finished
#		return
#	var fps := maxf(_sprite.sprite_frames.get_animation_speed(animation), 0.01)
#	var duration := _sprite.sprite_frames.get_frame_count(animation) / fps
#	await get_tree().create_timer(duration).timeout
#	_sprite.stop()


func _spawn_object() -> bool:
	if spawned_object_scene == null or spawn_point == null or _ground_object_exists():
		return false
	_spawned_object = spawned_object_scene.instantiate() as DroppedCoffee
	if _spawned_object == null:
		return false
	get_tree().current_scene.add_child(_spawned_object)
	_spawned_object.global_position = spawn_point.global_position
	_spawned_object.collected.connect(_on_object_collected.bind(_spawned_object), CONNECT_ONE_SHOT)
	return true


func _on_object_collected(object: DroppedCoffee) -> void:
	if object != _spawned_object:
		return
	_spawned_object = null


func _ground_object_exists() -> bool:
	for object in get_tree().get_nodes_in_group(GROUND_OBJECT_GROUP):
		if is_instance_valid(object) and not object.is_queued_for_deletion():
			return true
	return false


func _play(animation: StringName) -> void:
	var selected := animation
	match animation:
		&"idle", &"idle_up":
			selected = &"idle_right"
		&"walk_down", &"walk_up":
			selected = &"walk_right"
	if _has_coffee:
		var coffee_animation := StringName( COFFEE_ANIMATION_PREFIX + String(selected) )
		if _sprite.sprite_frames.has_animation(coffee_animation):
			selected = coffee_animation
	super._play(selected)


func _left_patrol_point() -> Vector2:
	return patrol_path.to_global(patrol_path.curve.get_point_position(0))


func _face_spawn_point() -> void:
	if spawn_point == null:
		return
	var direction := spawn_point.global_position - global_position
	if direction == Vector2.ZERO:
		return
	_facing = direction.normalized()
	if direction.x != 0.0:
		_sprite.flip_h = direction.x < 0.0 and not _sprite.sprite_frames.has_animation(&"idle_left")

class_name Npc
extends CharacterBody2D

const STUCK_GRACE: float = 0.75

enum State { IDLE, PATROL, GOTO, ACTING, TALKING, FOLLOWING }
enum Facing { DOWN, UP, LEFT, RIGHT }

const FACING_VECTORS := [Vector2.DOWN, Vector2.UP, Vector2.LEFT, Vector2.RIGHT]

@export var walk_speed: float = 40.0
@export var patrol_path: Path2D
@export var destination: Node2D
@export var facing: Facing = Facing.DOWN

@onready var _sprite: AnimatedSprite2D = $Sprite
@onready var _panel: DialoguePanel = $DialoguePanel
@onready var _interactable: DialogueInteractable = $DialogueInteractable
@onready var _collision_shape: CollisionShape2D = $CollisionShape2D

@onready var _player = get_tree().get_first_node_in_group("player") as PlayerCharacter

var _state: State = State.IDLE:
	set(new_state):
		_state = new_state
		_collision_shape.disabled = _state == State.FOLLOWING
var _progress: float = 0.0
var _goto_target: Vector2 = Vector2.ZERO
var _goto_resume: bool = true
var _stuck_time: float = 0.0
var _facing: Vector2 = Vector2.DOWN


func _ready() -> void:
	_facing = FACING_VECTORS[facing]
	_sprite.flip_h = _facing.x < 0.0
	_panel.opened.connect(_on_panel_opened)
	_panel.closed.connect(_on_panel_closed)
	_start_patrol()


func _physics_process(delta: float) -> void:
	match _state:
		State.FOLLOWING:
			if _player:
				var dif = _player.trail_marker.global_position - global_position
				_animate(dif)
				global_position = _player.trail_marker.global_position
		State.PATROL:
			_patrol(delta)
		State.GOTO:
			_goto(delta)
		State.ACTING:
			pass
		_:
			_animate(Vector2.ZERO)


func go(resume := true) -> void:
	if destination != null:
		await go_to(destination.global_position, resume)


func go_to(target_global: Vector2, resume := true) -> void:
	_goto_target = target_global
	_goto_resume = resume
	_stuck_time = 0.0
	_state = State.GOTO
	_set_interactable(false)
	while _state == State.GOTO:
		await get_tree().physics_frame
	_set_interactable(true)


func play_once(anim: StringName, fallback_seconds := 1.0) -> void:
	_state = State.ACTING
	_set_interactable(false)
	if _sprite.sprite_frames != null and _sprite.sprite_frames.has_animation(anim):
		_sprite.play(anim)
		await _sprite.animation_finished
	else:
		await get_tree().create_timer(fallback_seconds).timeout
	_state = State.IDLE
	_set_interactable(true)


func _set_interactable(enabled: bool) -> void:
	_interactable.active = enabled
	#_interactable.set_deferred("monitoring", enabled)
	#_interactable.set_process_unhandled_input(enabled)

func _start_patrol() -> void:
	if patrol_path == null or patrol_path.curve == null:
		_state = State.IDLE
		return
	_progress = patrol_path.curve.get_closest_offset(patrol_path.to_local(global_position))
	_state = State.PATROL


func _patrol(delta: float) -> void:
	var curve := patrol_path.curve
	var length := curve.get_baked_length()
	if length <= 0.0:
		_state = State.IDLE
		return
	var before := global_position
	_walk_towards(patrol_path.to_global(curve.sample_baked(_progress)), delta)
	_progress = fmod(_progress + before.distance_to(global_position), length)


func _goto(delta: float) -> void:
	var before := global_position
	if _walk_towards(_goto_target, delta):
		_finish_goto()
		return
	if before.distance_to(global_position) < walk_speed * delta * 0.25 and not _blocked_by_player():
		_stuck_time += delta
		if _stuck_time >= STUCK_GRACE:
			_finish_goto()
	else:
		_stuck_time = 0.0


func _blocked_by_player() -> bool:
	for i in get_slide_collision_count():
		if get_slide_collision(i).get_collider().is_in_group("player"):
			return true
	return false


func _finish_goto() -> void:
	if _goto_resume:
		_start_patrol()
	else:
		_state = State.IDLE


func _walk_towards(target: Vector2, delta: float) -> bool:
	var to_target := target - global_position
	var arrived := to_target.length() <= walk_speed * delta
	velocity = to_target / delta if arrived else to_target.normalized() * walk_speed
	move_and_slide()
	_animate(Vector2.ZERO if arrived else velocity)
	return arrived


func _animate(dir: Vector2) -> void:
	if dir == Vector2.ZERO:
		_play(_idle_animation())
		return
	_facing = dir
	if dir.x != 0.0:
		_sprite.flip_h = dir.x < 0.0
	if absf(dir.x) > absf(dir.y):
		_play(&"walk_right")
	elif dir.y > 0.0:
		_play(&"walk_down")
	else:
		_play(&"walk_up")


func _idle_animation() -> StringName:
	if absf(_facing.x) > absf(_facing.y):
		return &"idle_right"
	return &"idle_up" if _facing.y < 0.0 else &"idle"


func _play(anim: StringName) -> void:
	if _sprite.animation != anim or not _sprite.is_playing():
		_sprite.play(anim)


func _on_panel_opened() -> void:
	_state = State.TALKING
	_face_player()


func _on_panel_closed() -> void:
	_start_patrol()


func _face_player() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	_facing = (player.global_position - global_position).normalized()
	if _facing.x != 0.0:
		_sprite.flip_h = _facing.x < 0.0
	_play(_idle_animation())

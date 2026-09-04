extends Npc
class_name Technician

## Animations during which the fixing sound should be heard.
const FIXING_ANIMS: Array[StringName] = [&"fix_loop", &"fix_start"]
const FLIGHT_BOB_HEIGHT := 2.0
const FLIGHT_CYCLE_SECONDS := 0.8

@onready var _fixing_sfx: AudioStreamPlayer2D = $FixingSfx

var _flight_visual_enabled := false
var _flight_phase := 0.0
var _sprite_rest_position: Vector2


func _ready():
	super._ready()
	_sprite_rest_position = _sprite.position
	_state = State.ACTING
	setup_fixing_sfx()


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if not _flight_visual_enabled:
		return
	_flight_phase = fmod(_flight_phase + TAU * delta / FLIGHT_CYCLE_SECONDS, TAU)
	_sprite.position = _sprite_rest_position + Vector2(0.0, sin(_flight_phase) * FLIGHT_BOB_HEIGHT)
	var frame_count := _sprite.sprite_frames.get_frame_count(_sprite.animation)
	_sprite.frame = mini(0 if cos(_flight_phase) < 0.0 else 1, frame_count - 1)


func _animate(direction: Vector2) -> void:
	if not _flight_visual_enabled:
		super._animate(direction)
		return
	if direction != Vector2.ZERO:
		super._animate(direction)
	elif not String(_sprite.animation).begins_with("walk_"):
		super._animate(_facing)
	_sprite.pause()


func _face_player() -> void:
	if not _flight_visual_enabled:
		super._face_player()
		return
	if _player:
		_facing = (_player.global_position - global_position).normalized()
	_animate(_facing)


func set_flight_visual(enabled: bool) -> void:
	if _flight_visual_enabled == enabled:
		return
	_flight_visual_enabled = enabled
	if enabled:
		_flight_phase = PI
		_animate(_facing)
	else:
		_sprite.position = _sprite_rest_position
		_animate(Vector2.ZERO)

func _idle_animation() -> StringName:
	var animation := super._idle_animation()
	if animation == &"idle_left":
		_sprite.flip_h = false
	return animation


## Called from _ready, and separately by subclasses that do not call super.
func setup_fixing_sfx() -> void:
	_sprite.animation_changed.connect(_on_fixing_anim_changed)
	_fixing_sfx.finished.connect(_on_fixing_sfx_finished)
	_on_fixing_anim_changed()


func _on_fixing_anim_changed() -> void:
	if _sprite.animation in FIXING_ANIMS:
		if not _fixing_sfx.playing:
			_fixing_sfx.play()
	else:
		_fixing_sfx.stop()


## fix_loop is continuous; fix_start is a one-shot lead-in to the explosion.
func _on_fixing_sfx_finished() -> void:
	if _sprite.animation == &"fix_loop":
		_fixing_sfx.play()

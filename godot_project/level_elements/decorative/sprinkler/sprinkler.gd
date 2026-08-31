extends Node2D

enum AnimationPhase {
	HIDDEN,
	RISING,
	SPRAYING,
	RETRACTING,
}

const DUSK_PROGRESS := 0.4
const WATERING_GAME_UNITS := 12
const WET_HOLD_GAME_UNITS := 10
const WET_FADE_GAME_UNITS := 8
const ANIMATION_FPS := 8.0
const WET_MULTIPLIER := Vector3(0.92, 0.92, 0.92)
const RISE_END_FRAME := 9
const SPRAY_START_FRAME := 10
const SPRAY_END_FRAME := 15

@onready var sprite: Sprite2D = $Sprite2D
@onready var wet_ground: Polygon2D = find_child("WetGround", true, false) as Polygon2D

var _last_progress := 0.0
var _running := false
var _watering_end_remaining := -1
var _wet_fade_start_remaining := -1
var _wet_end_remaining := -1
var _animation_phase := AnimationPhase.HIDDEN
var _frame_accumulator := 0.0
var _wet_material: ShaderMaterial


func _ready() -> void:
	y_sort_enabled = true
	sprite.hframes = 4
	sprite.vframes = 4
	sprite.frame = 0
	if wet_ground == null:
		push_error("Sprinkler is missing WetGround")
		set_process(false)
		return
	_wet_material = wet_ground.material as ShaderMaterial
	wet_ground.color = Color.WHITE
	_set_wet_strength(0.0)
	if _wet_material != null:
		_wet_material.set_shader_parameter("wet_multiplier", WET_MULTIPLIER)
	_last_progress = _get_day_progress()
	TimeManager.time_changed.connect(_on_time_changed)


func _process(delta: float) -> void:
	_frame_accumulator += delta * ANIMATION_FPS
	while _frame_accumulator >= 1.0:
		_frame_accumulator -= 1.0
		_advance_animation()


func _on_time_changed(_hour: int, _minute: int, _second: int) -> void:
	var progress := _get_day_progress()
	if progress < DUSK_PROGRESS:
		_reset_cycle()
	elif _last_progress < DUSK_PROGRESS:
		_begin_cycle()
	if _running:
		_update_cycle()
	_last_progress = progress


func _get_day_progress() -> float:
	var total := (
		TimeManager.HOURS_PER_DAY
		* TimeManager.MINUTES_PER_HOUR
		* TimeManager.SECONDS_PER_MINUTE
	)
	return 1.0 - clampf(float(TimeManager.total_seconds()) / float(total), 0.0, 1.0)

func _begin_cycle() -> void:
	_running = true
	var remaining := TimeManager.total_seconds()
	_watering_end_remaining = maxi(remaining - WATERING_GAME_UNITS, 0)
	_wet_fade_start_remaining = maxi(
		_watering_end_remaining - WET_HOLD_GAME_UNITS,
		0,
	)
	_wet_end_remaining = maxi(
		_wet_fade_start_remaining - WET_FADE_GAME_UNITS,
		0,
	)
	_animation_phase = AnimationPhase.RISING
	_frame_accumulator = 0.0
	sprite.frame = 0
	_set_wet_strength(0.0)


func _update_cycle() -> void:
	var remaining := TimeManager.total_seconds()
	if remaining > _watering_end_remaining:
		return

	if _animation_phase == AnimationPhase.RISING or _animation_phase == AnimationPhase.SPRAYING:
		_animation_phase = AnimationPhase.RETRACTING
		_frame_accumulator = 0.0
		sprite.frame = RISE_END_FRAME

	if remaining > _wet_fade_start_remaining:
		_set_wet_strength(1.0)
		return

	if remaining > _wet_end_remaining:
		_set_wet_strength(
			inverse_lerp(
				float(_wet_end_remaining),
				float(_wet_fade_start_remaining),
				float(remaining),
			)
		)
		return

	_set_wet_strength(0.0)
	_running = false


func _advance_animation() -> void:
	match _animation_phase:
		AnimationPhase.RISING:
			if sprite.frame < RISE_END_FRAME:
				sprite.frame += 1
				return
			_animation_phase = AnimationPhase.SPRAYING
			sprite.frame = SPRAY_START_FRAME
			_set_wet_strength(1.0)
		AnimationPhase.SPRAYING:
			sprite.frame = (
				SPRAY_START_FRAME
				if sprite.frame >= SPRAY_END_FRAME
				else sprite.frame + 1
			)
		AnimationPhase.RETRACTING:
			sprite.frame = maxi(sprite.frame - 1, 0)
			if sprite.frame == 0:
				_animation_phase = AnimationPhase.HIDDEN


func _reset_cycle() -> void:
	_running = false
	_watering_end_remaining = -1
	_wet_fade_start_remaining = -1
	_wet_end_remaining = -1
	_animation_phase = AnimationPhase.HIDDEN
	_frame_accumulator = 0.0
	sprite.frame = 0
	_set_wet_strength(0.0)


func _set_wet_strength(value: float) -> void:
	if _wet_material != null:
		_wet_material.set_shader_parameter("wet_strength", value)

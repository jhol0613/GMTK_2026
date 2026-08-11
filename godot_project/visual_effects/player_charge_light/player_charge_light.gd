extends PointLight2D

## The charge cell the player carries lights their way at night. It burns
## brightest on a full battery, dims as tokens are spent, and flickers when the
## cell is nearly empty.

@export_range(0.0, 4.0, 0.05) var max_energy := 0.9
## Charge fraction below which the light starts to stutter.
@export_range(0.0, 1.0, 0.05) var flicker_threshold := 0.25
@export var flicker_speed := 9.0
@export var full_color := Color("ffc46b")
@export var empty_color := Color("d1663a")
## Matches night_light_2d so the lamp fades in over the same part of the day.
@export_range(0.0, 1.0, 0.01) var start_progress := 0.25
@export_range(0.0, 1.0, 0.01) var full_strength_progress := 0.75

var _night_strength := 0.0
var _charge := 1.0
var _flicker_time := 0.0
var _tween: Tween


func _ready() -> void:
	add_to_group("night_lights")
	Wallet.tokens_changed.connect(_on_tokens_changed)
	_on_tokens_changed(Wallet.tokens, Wallet.MAX_TOKENS)

	var total := (
		TimeManager.HOURS_PER_DAY
		* TimeManager.MINUTES_PER_HOUR
		* TimeManager.SECONDS_PER_MINUTE
	)
	set_day_progress(1.0 - float(TimeManager.total_seconds()) / float(total), 0.0)


func _on_tokens_changed(current: int, maximum: int) -> void:
	_charge = float(current) / float(maxi(maximum, 1))
	color = empty_color.lerp(full_color, _charge)


## Called through the "night_lights" group by the day/night background.
func set_day_progress(progress: float, duration: float) -> void:
	var target := clampf(
		inverse_lerp(start_progress, full_strength_progress, progress),
		0.0,
		1.0
	)
	if _tween != null and _tween.is_valid():
		_tween.kill()
	if duration <= 0.0:
		_night_strength = target
		return
	_tween = create_tween()
	_tween.tween_method(_set_night_strength, _night_strength, target, duration)


func _set_night_strength(value: float) -> void:
	_night_strength = value


func _process(delta: float) -> void:
	var target := max_energy * _night_strength * lerpf(0.25, 1.0, _charge)

	if _charge <= flicker_threshold:
		_flicker_time += delta * flicker_speed
		target *= 0.65 + 0.35 * absf(sin(_flicker_time))

	energy = target

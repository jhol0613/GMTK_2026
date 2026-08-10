extends Node

signal time_changed(hour: int, minute: int, second: int)
signal flash_requested
signal time_up
signal time_scale_changed(scale: float)

const SECONDS_PER_MINUTE: int = 8
const MINUTES_PER_HOUR: int = 8
const HOURS_PER_DAY: int = 8

var hour: int = HOURS_PER_DAY
var minute: int = 0
var second: int = 0

var _preserve_across_reload: bool = false
var _skip_intro_on_reload: bool = false
var _pending_wrong_train_dialogue: bool = false

var _pending_flash: bool = false
var _time_up_emitted: bool = false
var _run_active: bool = false

## Multiplier applied to time spent by walking and interacting. 1.0 is normal,
## 0.5 makes everything cost half as much time. Penalties ignore it.
var time_scale: float = 1.0
var _scale_accumulator: float = 0.0
var _scaled_units_left: int = 0


func _ready() -> void:
	SignalBus.minutes_passed.connect(advance)


func _unhandled_input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_T:
			advance(MINUTES_PER_HOUR)
		elif event.physical_keycode == KEY_1:
			# Debug: jump to dusk (halfway through the day).
			reset(HOURS_PER_DAY / 2, 0, 0)
		elif event.physical_keycode == KEY_2:
			# Debug: jump to night, stopping just short of running out of time.
			reset(0, 1, 0)


func reset(start_hour: int = HOURS_PER_DAY, start_minute: int = 0, start_second: int = 0) -> void:
	hour = start_hour
	minute = start_minute
	second = start_second
	_time_up_emitted = total_seconds() <= 0
	time_changed.emit(hour, minute, second)


func begin_new_run() -> void:
	_preserve_across_reload = false
	_skip_intro_on_reload = false
	_pending_wrong_train_dialogue = false
	_pending_flash = false
	_run_active = true
	clear_time_scale()
	reset(HOURS_PER_DAY - 1, MINUTES_PER_HOUR - 1, SECONDS_PER_MINUTE - 1)


## `scaled` is false for penalties, which always cost their full amount.
func advance(amount: int = 1, scaled: bool = true) -> void:
	if total_seconds() <= 0:
		return

	if scaled and time_scale != 1.0:
		# Fractional costs are accumulated so that halving a cost of 1 still
		# advances the clock every other step instead of rounding away.
		_scale_accumulator += amount * time_scale
		amount = int(floor(_scale_accumulator))
		_scale_accumulator -= amount
		if amount <= 0:
			return

	if _scaled_units_left > 0:
		_scaled_units_left -= amount
		if _scaled_units_left <= 0:
			clear_time_scale()

	second -= amount
	while second < 0:
		minute -= 1
		second += SECONDS_PER_MINUTE
	while minute < 0:
		hour -= 1
		minute += MINUTES_PER_HOUR
	if hour < 0 or total_seconds() <= 0:
		hour = 0
		minute = 0
		second = 0
		time_changed.emit(hour, minute, second)
		_emit_time_up()
		return
	time_changed.emit(hour, minute, second)


func advance_minutes(amount: int = 1) -> void:
	advance(amount * SECONDS_PER_MINUTE)


func _emit_time_up() -> void:
	if _time_up_emitted:
		return
	_time_up_emitted = true
	time_up.emit()


func total_seconds() -> int:
	return hour * MINUTES_PER_HOUR * SECONDS_PER_MINUTE + minute * SECONDS_PER_MINUTE + second


## Countdown "now + offset" → remaining time after offset minutes elapse.
func remaining_after_offset(
	offset_hours: int,
	offset_minutes: int,
	offset_seconds: int,
) -> Vector3i:
	var total := total_seconds() - (offset_hours * MINUTES_PER_HOUR * SECONDS_PER_MINUTE
	+ offset_minutes * SECONDS_PER_MINUTE + offset_seconds)
	total = maxi(total, 0)
	var seconds_per_hour := MINUTES_PER_HOUR * SECONDS_PER_MINUTE
	return Vector3i(
		total / seconds_per_hour,
		(total % seconds_per_hour) / SECONDS_PER_MINUTE,
		(total % seconds_per_hour) % SECONDS_PER_MINUTE,
	)


## Countdown comparison: true while remaining time is still at/above the target.
## (Higher remaining = earlier)
func has_at_least(target_hour: int, target_minute: int, target_second: int) -> bool:
	return total_seconds() >= (
		target_hour * MINUTES_PER_HOUR * SECONDS_PER_MINUTE
		+ target_minute * SECONDS_PER_MINUTE + target_second
	)


## Apply a time penalty in-place and flash the clock. Penalties are never scaled.
func apply_penalty(amount: int) -> void:
	advance(amount, false)
	flash_requested.emit()


## Slow time down for `duration_minutes` of clock time. Re-applying refreshes
## the duration instead of stacking the effect.
func set_time_scale(scale: float, duration_minutes: int) -> void:
	time_scale = scale
	_scaled_units_left = duration_minutes * SECONDS_PER_MINUTE
	_scale_accumulator = 0.0
	time_scale_changed.emit(time_scale)


func clear_time_scale() -> void:
	if time_scale == 1.0 and _scaled_units_left == 0:
		return
	time_scale = 1.0
	_scaled_units_left = 0
	_scale_accumulator = 0.0
	time_scale_changed.emit(time_scale)


## Stash the current time before reloading the game.
func stash_before_reload(penalty_seconds: int) -> void:
	advance(penalty_seconds)
	_pending_flash = true
	_preserve_across_reload = true
	_skip_intro_on_reload = true
	_pending_wrong_train_dialogue = true


## Call from the clock UI on ready. Skips reset after a penalty reload.
func sync_from_ui(start_hour: int, start_minute: int, start_second: int) -> void:
	if _preserve_across_reload:
		_preserve_across_reload = false
		_time_up_emitted = total_seconds() <= 0
		time_changed.emit(hour, minute, second)
		return
	if not _run_active:
		_run_active = true
		reset(start_hour, start_minute, start_second)
		return
	_time_up_emitted = total_seconds() <= 0
	time_changed.emit(hour, minute, second)


## True once after a wrong-train reload; consumes the flag.
func consume_skip_intro() -> bool:
	if not _skip_intro_on_reload:
		return false
	_skip_intro_on_reload = false
	return true


## True once after a wrong-train reload; consumes the flag.
func consume_wrong_train_dialogue() -> bool:
	if not _pending_wrong_train_dialogue:
		return false
	_pending_wrong_train_dialogue = false
	return true


func consume_flash() -> bool:
	if not _pending_flash:
		return false
	_pending_flash = false
	return true

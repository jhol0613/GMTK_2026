extends Node

signal time_changed(hour: int, minute: int, second: int)
signal flash_requested

const SECONDS_PER_MINUTE: int = 8
const MINUTES_PER_HOUR: int = 8
const HOURS_PER_DAY: int = 8

var hour: int = HOURS_PER_DAY
var minute: int = 0
var second: int = 0

var _preserve_across_reload: bool = false

var _pending_flash: bool = false


func _ready() -> void:
	SignalBus.minutes_passed.connect(advance)


func _unhandled_input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_T:
			advance(MINUTES_PER_HOUR)


func reset(start_hour: int = HOURS_PER_DAY, start_minute: int = 0, start_second: int = 0) -> void:
	hour = start_hour
	minute = start_minute
	second = start_second
	time_changed.emit(hour, minute, second)


func advance(amount: int = 1) -> void:
	second -= amount
	while second < 0:
		minute -= 1
		second += SECONDS_PER_MINUTE
	while minute < 0:
		hour -= 1
		minute += MINUTES_PER_HOUR
	if hour < 0:
		hour = 0
		minute = 0
	time_changed.emit(hour, minute, second)


func total_seconds() -> int:
	return hour * MINUTES_PER_HOUR * SECONDS_PER_MINUTE + minute * SECONDS_PER_MINUTE + second


## Countdown "now + offset" → remaining time after offset minutes elapse.
func remaining_after_offset(offset_hours: int, offset_minutes: int, offset_seconds: int) -> Vector3i:
	var total := total_seconds() - (offset_hours * MINUTES_PER_HOUR * SECONDS_PER_MINUTE + offset_minutes * SECONDS_PER_MINUTE + offset_seconds)
	total = maxi(total, 0)
	var seconds_per_hour := MINUTES_PER_HOUR * SECONDS_PER_MINUTE
	return Vector3i(
		total / seconds_per_hour,
		(total % seconds_per_hour) / SECONDS_PER_MINUTE,
		total % SECONDS_PER_MINUTE,
	)


## Countdown comparison: true while remaining time is still at/above the target.
## (Higher remaining = earlier)
func has_at_least(target_hour: int, target_minute: int, target_second: int) -> bool:
	return total_seconds() >= (
		target_hour * MINUTES_PER_HOUR * SECONDS_PER_MINUTE
		+ target_minute * SECONDS_PER_MINUTE
		+ target_second
	)



## Stash the current time before reloading the game.
func stash_before_reload(penalty_seconds: int) -> void:
	advance(penalty_seconds)
	_pending_flash = true
	_preserve_across_reload = true


## Call from the clock UI on ready. Skips reset after a penalty reload.
func sync_from_ui(start_hour: int, start_minute: int, start_second: int) -> void:
	if _preserve_across_reload:
		_preserve_across_reload = false
		time_changed.emit(hour, minute, second)
		return
	reset(start_hour, start_minute, start_second)


func consume_flash() -> bool:
	if not _pending_flash:
		return false
	_pending_flash = false
	return true

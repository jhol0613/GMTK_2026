extends Node

signal time_changed(hour: int, minute: int)
signal flash_requested

const MINUTES_PER_HOUR: int = 8
const HOUR_PER_DAY: int = 8

var hour: int = HOUR_PER_DAY
var minute: int = 0

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


func reset(start_hour: int = HOUR_PER_DAY, start_minute: int = 0) -> void:
	hour = start_hour
	minute = start_minute
	time_changed.emit(hour, minute)


func advance(amount: int = 1) -> void:
	minute -= amount
	while minute < 0:
		hour -= 1
		minute += MINUTES_PER_HOUR
	if hour < 0:
		hour = 0
		minute = 0
	time_changed.emit(hour, minute)


func total_minutes() -> int:
	return hour * MINUTES_PER_HOUR + minute


## Countdown "now + offset" → remaining time after offset minutes elapse.
func remaining_after_offset(offset_hours: int, offset_minutes: int) -> Vector2i:
	var total := total_minutes() - (offset_hours * MINUTES_PER_HOUR + offset_minutes)
	total = maxi(total, 0)
	return Vector2i(total / MINUTES_PER_HOUR, total % MINUTES_PER_HOUR)


## Countdown comparison: true while remaining time is still at/above the target.
## (Higher remaining = earlier)
func has_at_least(target_hour: int, target_minute: int) -> bool:
	return total_minutes() >= target_hour * MINUTES_PER_HOUR + target_minute



## Stash the current time before reloading the game.
func stash_before_reload(penalty_minutes: int) -> void:
	advance(penalty_minutes)
	_pending_flash = true
	_preserve_across_reload = true


## Call from the clock UI on ready. Skips reset after a penalty reload.
func sync_from_ui(start_hour: int, start_minute: int) -> void:
	if _preserve_across_reload:
		_preserve_across_reload = false
		time_changed.emit(hour, minute)
		return
	reset(start_hour, start_minute)


func consume_flash() -> bool:
	if not _pending_flash:
		return false
	_pending_flash = false
	return true

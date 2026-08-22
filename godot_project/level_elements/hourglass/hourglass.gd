extends Node2D
class_name Hourglass

@onready var hourglass_top: AnimatedSprite2D = $HourglassTop
@onready var hourglass_bottom: AnimatedSprite2D = $HourglassBottom
@onready var _time_label: ResshanLabel = $TimeDisplay/TimeLabel

var _start_total: int = 0

func _ready() -> void:
	hourglass_top.stop()
	hourglass_bottom.stop()
	_start_total = (
		TimeManager.HOURS_PER_DAY
		* TimeManager.MINUTES_PER_HOUR
		* TimeManager.SECONDS_PER_MINUTE
	)

	TimeManager.time_changed.connect(_on_time_changed)
	_sync_frames(TimeManager.hour, TimeManager.minute, TimeManager.second)
	_update_label(TimeManager.hour, TimeManager.minute, TimeManager.second)

func _on_time_changed(hour: int, minute: int, second: int) -> void:
	_advance_frame(hourglass_top)
	_advance_frame(hourglass_bottom)
	_update_label(hour, minute, second)

## Sync the frames of the hourglass to the current time
func _sync_frames(hour: int, minute: int, second: int) -> void:
	var remaining_seconds := (
		hour * TimeManager.MINUTES_PER_HOUR * TimeManager.SECONDS_PER_MINUTE
		+ minute * TimeManager.SECONDS_PER_MINUTE
		+ second
	)
	var top_count := hourglass_top.sprite_frames.get_frame_count(hourglass_top.animation)
	var bottom_count := hourglass_bottom.sprite_frames.get_frame_count(hourglass_bottom.animation)
	if top_count <= 0 or bottom_count <= 0:
		return

	var elapsed_seconds := maxi(_start_total - 1 - remaining_seconds, 0)
	hourglass_top.frame = elapsed_seconds % top_count
	hourglass_bottom.frame = elapsed_seconds % bottom_count

func _advance_frame(sprite: AnimatedSprite2D) -> void:
	var count := sprite.sprite_frames.get_frame_count(sprite.animation)
	if count <= 0:
		return
	sprite.frame = (sprite.frame + 1) % count

func _update_label(hour: int, minute: int, second: int) -> void:
	_time_label.text = "<<%s>> : <<%s>> : <<%s>>" % [hour, minute, second]

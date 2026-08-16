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
	_sync_frames(hour, minute, second)
	_update_label(hour, minute, second)

## Sync the frames of the hourglass to the current time
func _sync_frames(hour: int, minute: int, second: int) -> void:
	var remaining_seconds := (
		hour * TimeManager.MINUTES_PER_HOUR * TimeManager.SECONDS_PER_MINUTE
		+ minute * TimeManager.SECONDS_PER_MINUTE
		+ second
	)
	var progress := 1.0 - float(remaining_seconds) / float(_start_total) # 1.0 is empty top / full bottom
	progress = clampf(progress, 0.0, 1.0)

	_set_frame_from_progress(hourglass_top, progress)
	_set_frame_from_progress(hourglass_bottom, progress)

func _update_label(hour: int, minute: int, second: int) -> void:
	_time_label.text = "<<%s>> : <<%s>> : <<%s>>" % [hour, minute, second]

## Set the frame of an animated sprite based on a progress value
func _set_frame_from_progress(sprite: AnimatedSprite2D, progress: float) -> void:
	var count := sprite.sprite_frames.get_frame_count(sprite.animation)
	if count <= 0:
		return

	sprite.frame = mini(int(progress * count), count - 1) # Clamp to the last frame

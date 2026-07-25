extends Node2D
class_name Hourglass

@onready var hourglass_top: AnimatedSprite2D = $HourglassTop
@onready var hourglass_bottom: AnimatedSprite2D = $HourglassBottom

var _start_total: int = 0

func _ready() -> void:
	hourglass_top.stop()
	hourglass_bottom.stop()
	_start_total = TimeManager.HOURS_PER_DAY * TimeManager.MINUTES_PER_HOUR

	TimeManager.time_changed.connect(_on_time_changed)
	_sync_frames(TimeManager.hour, TimeManager.minute)

func _on_time_changed(hour: int, minute: int) -> void:
	_sync_frames(hour, minute)

## Sync the frames of the hourglass to the current time
func _sync_frames(hour: int, minute: int) -> void:
	var remaining_minutes := hour * TimeManager.MINUTES_PER_HOUR + minute
	var progress := 1.0 - float(remaining_minutes) / float(_start_total) # 1.0 is full, 0.0 is empty
	progress = clamp(progress, 0.0, 1.0)

	_set_frame_from_progress(hourglass_top, progress)
	_set_frame_from_progress(hourglass_bottom, progress)

## Set the frame of an animated sprite based on a progress value
func _set_frame_from_progress(sprite: AnimatedSprite2D, progress: float) -> void:
	var count := sprite.sprite_frames.get_frame_count(sprite.animation)
	if count <= 0:
		return

	sprite.frame = mini(int(progress * count), count - 1) # Clamp to the last frame

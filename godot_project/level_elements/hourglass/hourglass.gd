extends Node2D
class_name Hourglass

@onready var hourglass_top: AnimatedSprite2D = $HourglassTop
@onready var hourglass_bottom: AnimatedSprite2D = $HourglassBottom
@onready var _time_label: ResshanLabel = $TimeDisplay/TimeLabel


func _ready() -> void:
	hourglass_top.stop()
	hourglass_bottom.stop()

	TimeManager.time_changed.connect(_on_time_changed)
	_sync_frames()
	_update_label(TimeManager.hour, TimeManager.minute, TimeManager.second)


func _on_time_changed(hour: int, minute: int, second: int) -> void:
	_sync_frames()
	_update_label(hour, minute, second)


func _sync_frames() -> void:
	var elapsed := TimeManager.run_total_seconds - TimeManager.total_seconds()
	hourglass_top.frame = _frame_for(elapsed, hourglass_top)
	hourglass_bottom.frame = _frame_for(elapsed, hourglass_bottom)


func _frame_for(elapsed: int, sprite: AnimatedSprite2D) -> int:
	var last := sprite.sprite_frames.get_frame_count(sprite.animation) - 1
	if last <= 0:
		return 0
	return clampi(roundi(float(elapsed) * last / TimeManager.run_total_seconds), 0, last)


func _update_label(hour: int, minute: int, second: int) -> void:
	_time_label.text = "<<%s>> : <<%s>> : <<%s>>" % [hour, minute, second]

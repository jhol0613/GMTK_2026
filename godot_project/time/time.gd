extends Control

const HOUR_PER_DAY: int = 8

@export_category("Clock Sounds")
@export var second_change_sound: AudioStream
@export var minute_change_sound: AudioStream

@onready var label: ResshanLabel = $Label
@onready var highlight: Panel = $Highlight
@onready var sfx_player: AudioStreamPlayer = $SFXPlayer

## Countdown starts here and ticks down towards 0:0
@export var start_hour: int = HOUR_PER_DAY
@export var start_minute: int = 8
@export var start_second: int = 8

var tween: Tween

var _previous_hour: int
var _previous_minute: int
var _previous_second: int
var _has_previous_time: bool = false


func _ready() -> void:
	TimeManager.time_changed.connect(_on_time_changed)
	TimeManager.sync_from_ui(start_hour, start_minute, start_second)
	_update_label(TimeManager.hour, TimeManager.minute, TimeManager.second)

	if TimeManager.consume_flash():
		_flash_timer()



func _on_time_changed(
	hour: int,
	minute: int,
	second: int
) -> void:
	_update_label(hour, minute, second)

	if _has_previous_time:
		# Minute 变化的优先级更高。
		# 即使此时 Second 也从 0 变成 7，也只播放 Minute 音效。
		if minute != _previous_minute or hour != _previous_hour:
			_play_clock_sound(minute_change_sound)

		elif second != _previous_second:
			_play_clock_sound(second_change_sound)

	_previous_hour = hour
	_previous_minute = minute
	_previous_second = second
	_has_previous_time = true

	if tween and tween.is_running():
		tween.kill()

	tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_BACK)

	tween.tween_property(self, "scale:x", 1.2, 0.2)
	tween.parallel().tween_property(self, "scale:y", 1.2, 0.2)

	tween.tween_property(self, "scale:x", 1.0, 0.2)
	tween.parallel().tween_property(self, "scale:y", 1.0, 0.2)


func _update_label(hour: int, minute: int, second: int) -> void:
	label.text = "<<%s>> : <<%s>> : <<%s>>" % [hour, minute, second]


func _flash_timer(flashes: int = 3, interval: float = 0.5) -> void:
	for i in flashes:
		label.modulate = Color.RED
		await get_tree().create_timer(interval).timeout
		label.modulate = Color.WHITE
		await get_tree().create_timer(interval).timeout
		
func _play_clock_sound(stream: AudioStream) -> void:
	if stream == null:
		return

	sfx_player.stream = stream
	sfx_player.play()

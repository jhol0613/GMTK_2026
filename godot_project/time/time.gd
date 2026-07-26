extends Control

const HOUR_PER_DAY: int = 8

@export_category("Clock Sounds")
@export var second_change_sound: AudioStream
@export_range(-40.0, 6.0, 0.5) var second_volume_db: float = -3.0
@export var minute_change_sound: AudioStream
@export_range(-40.0, 6.0, 0.5) var minute_volume_db: float = -0.0

@onready var label: ResshanLabel = $Label
@onready var highlight: Panel = $Highlight
@onready var sfx_player: AudioStreamPlayer = $SFXPlayer

@export var start_hour: int = HOUR_PER_DAY
@export var start_minute: int = 8
@export var start_second: int = 8



var tween: Tween

var _previous_hour: int
var _previous_minute: int
var _previous_second: int
var _has_previous_time: bool = false


func _ready() -> void:
	sfx_player.bus = AudioManager.SFX_BUS
	TimeManager.time_changed.connect(_on_time_changed)
	TimeManager.flash_requested.connect(_flash_timer)
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
		if minute != _previous_minute or hour != _previous_hour:
			_play_clock_sound(
				minute_change_sound,
				minute_volume_db
			)

		elif second != _previous_second:
			_play_clock_sound(
				second_change_sound,
				second_volume_db
			)

	_previous_hour = hour
	_previous_minute = minute
	_previous_second = second
	_has_previous_time = true

	if tween and tween.is_running():
		tween.kill()

	tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_BACK)

	tween.tween_property(
		self,
		"scale:x",
		1.2,
		0.2
	)
	tween.parallel().tween_property(
		self,
		"scale:y",
		1.2,
		0.2
	)

	tween.tween_property(
		self,
		"scale:x",
		1.0,
		0.2
	)
	tween.parallel().tween_property(
		self,
		"scale:y",
		1.0,
		0.2
	)


func _update_label(hour: int, minute: int, second: int) -> void:
	label.text = "<<%s>> : <<%s>> : <<%s>>" % [hour, minute, second]


func _flash_timer(flashes: int = 3, interval: float = 0.5) -> void:
	for i in flashes:
		label.modulate = Color.RED
		await get_tree().create_timer(interval).timeout
		label.modulate = Color.WHITE
		await get_tree().create_timer(interval).timeout
		
func _play_clock_sound(
	stream: AudioStream,
	volume_db: float
) -> void:
	if stream == null:
		return

	sfx_player.stream = stream
	sfx_player.volume_db = volume_db
	sfx_player.play()

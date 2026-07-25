extends Control

const HOUR_PER_DAY: int = 8

@onready var label: ResshanLabel = $Label

## Countdown starts here and ticks down towards 0:0
@export var start_hour: int = HOUR_PER_DAY
@export var start_minute: int = 0


func _ready() -> void:
	TimeManager.time_changed.connect(_on_time_changed)
	TimeManager.sync_from_ui(start_hour, start_minute)
	_update_label(TimeManager.hour, TimeManager.minute)

	if TimeManager.consume_flash():
		_flash_timer()


func _on_time_changed(hour: int, minute: int) -> void:
	_update_label(hour, minute)


func _update_label(hour: int, minute: int) -> void:
	label.text = "<<%s>> : <<%s>>" % [hour, minute]


func _flash_timer(flashes: int = 3, interval: float = 0.5) -> void:
	for i in flashes:
		label.modulate = Color.RED
		await get_tree().create_timer(interval).timeout
		label.modulate = Color.WHITE
		await get_tree().create_timer(interval).timeout

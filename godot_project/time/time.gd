extends Control

const MINUTES_PER_HOUR: int = 8
const HOUR_PER_DAY: int = 8

@onready var label: ResshanLabel = $Label
@onready var timer: Timer = $Timer

## Countdown starts here and ticks down towards 0:0
@export var start_hour: int = HOUR_PER_DAY
@export var start_minute: int = 0

var rhour: int = 0
var rminute: int = 0


func _ready() -> void:
	add_to_group("time")
	SignalBus.minutes_passed.connect(_advance_time)

	rhour = start_hour
	rminute = start_minute

	if GameManager.restore_time:
		rhour = GameManager.restore_hour
		rminute = GameManager.restore_minute
		GameManager.restore_time = false

	_update_label()

	if GameManager.flash_timer:
		GameManager.flash_timer = false
		_flash_timer()


func _advance_time(amount: int = 1) -> void:
	rminute -= amount
	while rminute < 0:
		rhour -= 1
		rminute += MINUTES_PER_HOUR
	if rhour < 0:
		rhour = 0
		rminute = 0
	_update_label()


func _update_label() -> void:
	label.text = "<<%s>> : <<%s>>" % [rhour, rminute]


func _flash_timer(flashes: int = 3, interval: float = 0.5) -> void:
	for i in flashes:
		label.modulate = Color.RED
		await get_tree().create_timer(interval).timeout
		label.modulate = Color.WHITE
		await get_tree().create_timer(interval).timeout

extends Control

const MINUTES_PER_HOUR: int = 8
const HOUR_PER_DAY: int = 8

@onready var label: ResshanLabel = $Label
@onready var timer: Timer = $Timer

var rhour: int = 0
var rminute: int = 0
var train_leave_rhour: int = 7
var _train_departed: bool = false


func _ready() -> void:
	add_to_group("time")
	SignalBus.minutes_passed.connect(_advance_time)
	if GameManager.restore_time:
		rhour = GameManager.restore_hour
		rminute = GameManager.restore_minute
		GameManager.restore_time = false

	_update_label()

	if GameManager.flash_timer:
		GameManager.flash_timer = false
		_flash_timer()

func _advance_time(amount: int = 1) -> void:
	rminute += amount
	while rminute >= MINUTES_PER_HOUR:
		rhour += 1
		rminute -= MINUTES_PER_HOUR
		if rhour >= HOUR_PER_DAY:
			rhour = 0
			rminute = 0
	_update_label()
	_check_train_departure()


func _check_train_departure() -> void:
	if _train_departed:
		return
	if rhour >= train_leave_rhour:
		_train_departed = true
		SignalBus.train_departed.emit()


func _update_label() -> void:
	label.text = "<<%s>> : <<%s>>" % [rhour, rminute]

func _flash_timer(flashes: int = 3, interval: float = 0.5) -> void:
	for i in flashes:
		label.modulate = Color.RED
		await get_tree().create_timer(interval).timeout
		label.modulate = Color.WHITE
		await get_tree().create_timer(interval).timeout

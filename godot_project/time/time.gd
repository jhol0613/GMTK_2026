extends Control

const MINUTES_PER_HOUR: int = 8
const HOUR_PER_DAY: int = 8

@onready var label: ResshanLabel = $Label
@onready var timer: Timer = $Timer

var rhour: int = 0
var rminutes: int = 0
var train_leave_rhour: int = 7
var _train_departed: bool = false


func _ready() -> void:
	SignalBus.minutes_passed.connect(_advance_time)
	_update_label()


func _advance_time(amount: int = 1) -> void:
	rminutes += amount
	while rminutes >= MINUTES_PER_HOUR:
		rhour += 1
		rminutes -= MINUTES_PER_HOUR
		if rhour >= HOUR_PER_DAY:
			rhour = 0
			rminutes = 0
	_update_label()
	_check_train_departure()


func _check_train_departure() -> void:
	if _train_departed:
		return
	if rhour >= train_leave_rhour:
		_train_departed = true
		SignalBus.train_departed.emit()


func _update_label() -> void:
	label.text = "<<%s>> : <<%s>>" % [rhour, rminutes]

extends Control

const MINUTES_PER_HOUR: int = 8

@onready var label: ResshanLabel2D = $Label
@onready var timer: Timer = $Timer

var rhour: int = 0
var rminutes: int = 0
var train_leave_rhour: int = 20


func _ready() -> void:
	SignalBus.interaction_started.connect(_on_interaction_started)
	SignalBus.player_moved.connect(_on_player_moved)
	_update_label()


func _process(delta: float) -> void:
	if rhour >= train_leave_rhour:
		SignalBus.timer_end.emit()


func _advance_time(amount: int = 1) -> void:
	rminutes += amount
	while rminutes >= MINUTES_PER_HOUR:
		rhour += 1
		rminutes -= MINUTES_PER_HOUR
	_update_label()


func _update_label() -> void:
	label.string = "<<%s>> : <<%s>>" % [rhour, rminutes]


func _on_interaction_started(minutes: int) -> void:
	_advance_time(minutes)


func _on_player_moved() -> void:
	_advance_time()

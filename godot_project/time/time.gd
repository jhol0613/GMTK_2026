extends Control

const MINUTES_PER_HOUR: int = 8

@onready var label: ResshanLabel2D = $Label
@onready var timer: Timer = $Timer

var rhour: int = 0
var rminutes: int = 0


func _ready() -> void:
	SignalBus.interaction_started.connect(_on_interaction_started)
	SignalBus.player_moved.connect(_on_player_moved)
	_update_label()


func _advance_time() -> void:
	rminutes += 1
	if rminutes >= MINUTES_PER_HOUR:
		rhour += 1
		rminutes = 0
	_update_label()


func _update_label() -> void:
	label.string = "<<%s>> : <<%s>>" % [rhour, rminutes]


func _on_interaction_started() -> void:
	_advance_time()


func _on_player_moved() -> void:
	_advance_time()

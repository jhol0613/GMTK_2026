extends Control

@onready var label: Label = $Label
@onready var timer: Timer = $Timer

var countdown_time_hour: int = 14
var countdown_time_min: int = 0


func _ready() -> void:
	timer.start(1)


func _process(delta: float) -> void:
	pass


func _on_timer_timeout() -> void:
	countdown_time_min -= 1
	if countdown_time_min == -1:
		countdown_time_hour -= 1
		countdown_time_min = 7
	if countdown_time_hour == 9:
		countdown_time_hour = 7
	label.text = str(countdown_time_hour) + ":" + str(countdown_time_min)
	timer.start(1)

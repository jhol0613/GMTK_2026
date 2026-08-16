class_name ScheduleData
extends Resource

signal train_aproaching 


@export var color: Enums.TrainColor
##the direction the train is going
@export var direction: Enums.TrainDirection
@export var destination: String
@export var arrival_interval_minutes: int
##trains can be randomly scheduled to arrive within this amount of time from
##the interval. Leave at 0 for trains to always arrive on set interval. Note
##that this is for building the train schedule and does not mean that trains are
##early or late
@export var arrival_variation_minutes: int

#var expired: = false

#func connect_to_time() -> void:
	#TimeManager.time_changed.connect(_check_arrival)

#func _check_arrival(h:int, m:int, s:int) -> void:
	#train_aproaching.emit()

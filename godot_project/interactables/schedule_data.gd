class_name ScheduleData
extends Resource

signal train_aproaching 

##the direction the train is going
@export var direction: Enums.TrainDirection
@export var hour: int
@export var minute: int
@export var seconds: int

var expired: = false

func connect_to_time() -> void:
	TimeManager.time_changed.connect(_check_arrival)

func _check_arrival(h:int, m:int, s:int) -> void:
	train_aproaching.emit()

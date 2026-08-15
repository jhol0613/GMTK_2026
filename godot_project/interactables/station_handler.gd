class_name StationHandler
extends Node

@export var trains: Array[Train] = []
@export var schedule: Dictionary[Enums.TrainColor, ScheduleData] = {} :
	set(value):
		# This thing is called when loaded. No _ready needed
		var new_data: Array[ScheduleData] = value.values().filter(func(item):
			return not schedule.values().has(item)
		)
		for data: ScheduleData in new_data:
			data.connect_to_time()
			data.train_aproaching.connect(_handle_aproaching_train.bind(data))
		schedule = value

func get_fair_ticket(for_train: Train) -> TicketData:
	return

func get_next_train_time(for_color: Enums.TrainColor) -> Vector3i:
	return Vector3i()

func _handle_aproaching_train(data: ScheduleData) -> void:
	pass

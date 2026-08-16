class_name StationHandler
extends Node

#@export var trains: Array[Train] = []
##Every train color and direction should have a schedule data entry
@export var schedule: Array[ScheduleData]
##How long before departure each train should pull in
@export var pull_in_seconds_before_departure := 8
##No train can pull in for this long after a train departs
@export var post_departure_buffer_seconds := 4

#@onready var post_departure_buffer_seconds := \
	#post_departure_buffer_minutes * TimeManager.SECONDS_PER_MINUTE

var departure_list: Array[DepartureData]
##indices should match those for the departure list
var departure_assignments: Array[Train]
var arrival_times: Array[int]
##sets of available trains grouped by direction
var train_pool: Dictionary[Enums.TrainDirection, TrainSet]
#@export var schedule: Dictionary[Enums.TrainColor, ScheduleData] = {} :
	#set(value):
		## This thing is called when loaded. No _ready needed
		#var new_data: Array[ScheduleData] = value.values().filter(func(item):
			#return not schedule.values().has(item)
		#)
		#for data: ScheduleData in new_data:
			#data.connect_to_time()
			#data.train_aproaching.connect(_handle_aproaching_train.bind(data))
		#schedule = value

func _ready() -> void:
	#need to wait for trains to initialize
	call_deferred("build_schedule")

func build_schedule():
	#builds schedule from 0 out to the current time minus buffer
	var current_time = TimeManager.total_seconds() - pull_in_seconds_before_departure - 1
	
	for schedule_item: ScheduleData in schedule:
		var time = 0 + randi_range(0, schedule_item.arrival_variation_minutes * TimeManager.SECONDS_PER_MINUTE)
		while time < current_time:
			#copy basic schedule data to departures
			var departure_data = DepartureData.new()
			departure_data.color_line = schedule_item.color
			departure_data.direction = schedule_item.direction
			departure_data.destination = schedule_item.destination

			#calculate arrival and departure times
			departure_data.departure_time_seconds = time
			departure_data.arrival_time_seconds = time + pull_in_seconds_before_departure
			
			#update times for next pass
			var time_offset = randi_range(-schedule_item.arrival_variation_minutes,
				schedule_item.arrival_variation_minutes)
			time_offset *= TimeManager.SECONDS_PER_MINUTE
			time += schedule_item.arrival_interval_minutes * TimeManager.SECONDS_PER_MINUTE
			time += time_offset
			

			departure_list.append(departure_data)

	#sort departure list from soonest to latest departure
	departure_list.sort_custom(
		func(a: DepartureData, b: DepartureData): 
			return a.departure_time_seconds > b.departure_time_seconds
	)

	_pair_departures_with_trains()

#if there are no available platforms for a train at a given time,
#that particular departure will be null and should not happen
func _pair_departures_with_trains():
	_refresh_train_pool()
	##A train that was reserved and its reservation limit.
	##reservation limit is the time that the train will no longer be reserved
	var unavailable_trains: Dictionary[Train, int]
	#departure list is sorted soonest to latest (i.e. high times to low times)
	for departure in departure_list:
		
		#put trains back in the pool if they hit their reservation limit before this departure
		for train: Train in unavailable_trains.keys():
			if unavailable_trains[train] > departure.arrival_time_seconds:
				train_pool[train.direction].push_unique(train)
			unavailable_trains.erase(train)

		#randomly reserve a new train
		var assigned_train = train_pool[departure.direction].pop_rand()
		if assigned_train:
			unavailable_trains.get_or_add(assigned_train, 
				departure.arrival_time_seconds + post_departure_buffer_seconds)
		#a departure assignment can be null if no train was available
		departure_assignments.append(assigned_train)

func _refresh_train_pool():
	train_pool = {
		Enums.TrainDirection.NORTH: TrainSet.new(),
		Enums.TrainDirection.SOUTH: TrainSet.new(),
		Enums.TrainDirection.EAST: TrainSet.new(),
		Enums.TrainDirection.WEST: TrainSet.new(),
	}
	for train: Train in get_tree().get_nodes_in_group("trains"):
		train_pool[train.direction].push_unique(train)

#func get_fair_ticket(for_train: Train) -> TicketData:
	#return
#
#func get_next_train_time(for_color: Enums.TrainColor) -> Vector3i:
	#return Vector3i()
#
#func _handle_aproaching_train(data: ScheduleData) -> void:
	#pass

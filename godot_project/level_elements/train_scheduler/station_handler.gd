class_name StationHandler
extends Node

#@export var trains: Array[Train] = []
##Every train color and direction should have a schedule data entry
@export var train_schedule: TrainSchedule
##How long before departure each train should pull in
@export var pull_in_seconds_before_departure := 8
##No train can pull in for this long after a train departs
@export var post_departure_buffer_seconds := 4

#@onready var post_departure_buffer_seconds := \
	#post_departure_buffer_minutes * TimeManager.SECONDS_PER_MINUTE
@onready var schedule = train_schedule.schedule
var departure_list: Array[DepartureData]
##indices should match those for the departure list
var departure_assignments: Array[Train]
##sets of available trains for building the schedule grouped by direction
var train_pool: Dictionary[Enums.TrainDirection, TrainSet]
##All the trains that are currently in the station with their departure time
var trains_in_station := 0

##All departure boards in the level. These are grabbed automatically during initialization
var departure_boards: Array[DepartureBoard]

func _ready() -> void:
	#need to wait for trains and departure boards to initialize
	call_deferred("_connect_to_departure_boards")
	call_deferred("build_schedule")
	TimeManager.time_changed.connect(_on_time_changed)

func _connect_to_departure_boards():
	var nodes = get_tree().get_nodes_in_group("departure_boards")
	for node in nodes:
		if node is DepartureBoard:
			departure_boards.append(node)
			node.highlight_seconds_before_departure = pull_in_seconds_before_departure

#region build schdule
func build_schedule():
	#builds schedule from 0 out to the current time minus buffer
	var current_time = TimeManager.total_seconds() - pull_in_seconds_before_departure - 1
	
	for schedule_item: ScheduleData in schedule:
		var time = schedule_item.initial_offset + \
			randi_range(0, schedule_item.arrival_variation_minutes * TimeManager.SECONDS_PER_MINUTE)
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
	_initialize_boards()

#if there are no available platforms for a train at a given time,
#that particular departure will be null and should not happen
func _pair_departures_with_trains():
	_refresh_train_pool()
	##A train that was reserved and its reservation limit.
	##reservation limit is the time that the train will no longer be reserved
	var unavailable_trains: Dictionary[Train, int]
	var canceled_departures : Array[DepartureData]
	
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
				departure.departure_time_seconds - post_departure_buffer_seconds)
			#a departure assignment can be null if no train was available
			departure.platform = assigned_train.platform_number
			departure_assignments.append(assigned_train)
		else:
			canceled_departures.append(departure)

	#Remove any departures that were canceled due to platform conflicts.
	#If the number of lines equals the number of platforms, cancelations should be rare
	for departure in canceled_departures:
		departure_list.erase(departure)
	print(canceled_departures.size(), " departures canceled for platform conflicts")

func _refresh_train_pool():
	train_pool = {
		Enums.TrainDirection.NORTH: TrainSet.new(),
		Enums.TrainDirection.SOUTH: TrainSet.new(),
		Enums.TrainDirection.EAST: TrainSet.new(),
		Enums.TrainDirection.WEST: TrainSet.new(),
	}
	for train: Train in get_tree().get_nodes_in_group("trains"):
		train_pool[train.direction].push_unique(train)

func _initialize_boards():
	for board in departure_boards:
		for i in range(board.MAX_ENTRIES):
			if departure_list.size() >= i-1:
				board.add(departure_list[i])
			else:
				board.add(null)
#endregion

#region execute schedule
func _on_time_changed(hour, minute, second):
	var time = TimeManager.time_to_seconds_remaining(hour, minute, second)
	
	#Old trains depart
	while not departure_list.is_empty() and time <= departure_list[0].departure_time_seconds:
		departure_assignments[0].train_depart(true)
		for board in departure_boards:
			if departure_list.size() > board.MAX_ENTRIES:
				await board.pop_and_add(departure_list[board.MAX_ENTRIES])
			else:
				await board.pop_and_add(null)
		#inefficient. could change the sorting order and work from the back but probably not worth it
		departure_list.pop_front()
		departure_assignments.pop_front()
		trains_in_station -= 1

	#new trains arrive
	while departure_list.size() > trains_in_station and time <= departure_list[trains_in_station].arrival_time_seconds:
		var departure := departure_list[trains_in_station]
		var train := departure_assignments[trains_in_station]
		train.color = departure.color_line
		train.call_train()
		trains_in_station += 1
#endregion

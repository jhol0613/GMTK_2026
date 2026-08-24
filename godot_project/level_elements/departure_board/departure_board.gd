class_name DepartureBoard
extends Node2D

const MAX_ENTRIES: = 7

##During animation of entries moving up, this is how long to pause between each entry moving
@export var board_update_animation_pause := 0.1

@onready var _highlight_sound: AudioStreamPlayer2D = $TrainAtPlatformSound
@onready var _update_board_sound: AudioStreamPlayer2D = $BoardUpdateSound
@onready var _entry_holder := $EntryHolder

##The number of seconds before departure to highlight an entry
var highlight_seconds_before_departure

var _new_data_queue : Array[DepartureData]
var _data_queue_processing = false

func _ready() -> void:
	add_to_group("departure_boards")
	TimeManager.time_changed.connect(_on_time_changed)

##Adds a new entry without popping the oldest one
func add(new_entry_data: DepartureData):
	var entry: BoardEntry = preload("uid://bpwbcd1m6uugt").instantiate()
	entry.set_data(new_entry_data)
	_entry_holder.add_child(entry)

##Removes top entry and adds a new one to the bottom. Can pass null departure
##data if there are no more departures for the night
func pop_and_add(new_entry_data: DepartureData):
	_new_data_queue.append(new_entry_data)
	if not _data_queue_processing:
		_process_data_queue()

func _process_data_queue():
	_data_queue_processing = true
	while _new_data_queue.size() > 0:
		#just add the data without popping if there's more room on the board
		if _entry_holder.get_children().size() < MAX_ENTRIES:
			add(_new_data_queue[0])
			_new_data_queue.pop_front()
			continue
		_entry_holder.get_child(0).set_data(null)
		_update_board_sound.play()
		await get_tree().create_timer(board_update_animation_pause).timeout
		for i in range(MAX_ENTRIES - 1):
			_entry_holder.move_child(_entry_holder.get_child(i+1), i)
			_update_board_sound.play()
			await get_tree().create_timer(board_update_animation_pause).timeout
		_entry_holder.get_child(MAX_ENTRIES-1).set_data(_new_data_queue[0])
		_entry_holder.get_child(MAX_ENTRIES-1).highlighted = false
		_new_data_queue.pop_front()
	_data_queue_processing = false

func _update_board_animated(new_entry_data):
	_entry_holder.get_child(0).set_data(null)
	_update_board_sound.play()
	get_tree().create_timer(board_update_animation_pause).timeout.connect(_slide_entry_up)
	for i in range(MAX_ENTRIES - 1):
		_entry_holder.move_child(_entry_holder.get_child(i+1), i)
		_update_board_sound.play()
		get_tree().create_timer(board_update_animation_pause).timeout.connect(_slide_entry_up)
	_entry_holder.get_child(MAX_ENTRIES-1).set_data(new_entry_data)
	_entry_holder.get_child(MAX_ENTRIES-1).highlighted = false

func _slide_entry_up(index: int):
	_entry_holder.move_child(_entry_holder.get_child(index+1), index)
	_update_board_sound.play()

func remove_entry(entry: BoardEntry) -> void:
	entry.queue_free()

func _on_time_changed(_h, _m, _s):
	var time_seconds = TimeManager.total_seconds()
	for entry: BoardEntry in _entry_holder.get_children():
		# departure time + highlight offset > current time
		if entry.time_seconds  + highlight_seconds_before_departure > time_seconds:
			if entry.highlighted:
				continue
			if _highlight_sound.stream != null:
				_highlight_sound.play()
			entry.highlighted = true

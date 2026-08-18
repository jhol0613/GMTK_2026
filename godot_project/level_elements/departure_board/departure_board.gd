class_name DepartureBoard
extends Node2D

const MAX_ENTRIES: = 6

@onready var _update_sound: AudioStreamPlayer2D = $UpdateSound

func _ready() -> void:
	add_to_group("departure_boards")

##Adds a new entry without popping the oldest one
func add(new_entry_data: DepartureData):
	var entry: BoardEntry = preload("uid://bpwbcd1m6uugt").instantiate()
	entry.set_data(new_entry_data)
	$EntryHolder.add_child(entry)

##Removes top entry and adds a new one to the bottom. Can pass null departure
##data if there are no more departures for the night
func pop_and_add(new_entry_data: DepartureData) -> bool:
	if $EntryHolder.get_children().size() >= MAX_ENTRIES:
		remove_entry($EntryHolder.get_child(0))

	var entry: BoardEntry = preload("uid://bpwbcd1m6uugt").instantiate()
	entry.set_data(new_entry_data)
	$EntryHolder.add_child(entry)
	
	if _update_sound.stream != null:
		_update_sound.play()
	
	return true

# Right now, entries will be removed when ScheduleData "rings"
# But probably should be tweaked to be removed later
func remove_entry(entry: BoardEntry) -> void:
	entry.queue_free()

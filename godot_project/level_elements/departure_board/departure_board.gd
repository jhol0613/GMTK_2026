extends Node2D

const MAX_ENTRIES: = 6

@onready var _update_sound: AudioStreamPlayer2D = $UpdateSound

# Destination is in <<***>> format
# Could be called directly or via signal. 
# It's up to who is gonna connect board to the trains (or trains to the board)
func add_entry(data: ScheduleData, destination: String, platform: int) -> bool:
	if $EntryHolder.get_children().size() >= MAX_ENTRIES:
		print("Max amount of board entries")
		return false
	
	var entry: BoardEntry = preload("uid://bpwbcd1m6uugt").instantiate()
	entry.set_data(Vector3i(data.hour, data.minute, data.seconds), destination, platform)
	data.train_aproaching.connect(remove_entry.bind(entry))
	$EntryHolder.add_child(entry)
	
	if _update_sound.stream != null:
		_update_sound.play()
	
	return true

# Right now, entries will be removed when ScheduleData "rings"
# But probably should be tweaked to be removed later
func remove_entry(entry: BoardEntry) -> void:
	entry.queue_free()
	
	if _update_sound.stream != null:
		_update_sound.play()

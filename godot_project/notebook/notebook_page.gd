class_name NotebookPage
extends Control

signal limit_reached
signal entry_removed
signal entry_updated(encoded:String, new_text:String)

const LIMIT: = 5


var entries_count: int = 0


func _new_entry(encoded:String, initial_text = "") -> NotebookEntry:
	var entry:NotebookEntry = preload('uid://s4gdpvpyayn0').instantiate()
	
	$Holder.add_child(entry)
	entry.player_input.text = initial_text
	entry.add_resshan(encoded)
	entry.player_input.text_changed.connect(_handle_entry_update.bind(encoded))
	entries_count += 1
	if entries_count == LIMIT:
		limit_reached.emit()
	
	return entry

# This WILL cause memory leak, if entry isn't properly handled 
func remove_entry(entry:NotebookEntry) -> void:
	$Holder.remove_child(entry)
	entries_count -= 1
	entry_removed.emit()


func _handle_entry_update(new_text:String, encoded:String) -> void:
	entry_updated.emit(encoded, new_text)


func get_entries() -> Array[NotebookEntry]:
	var arr: Array[NotebookEntry] = []
	arr.append_array($Holder.get_children())
	return arr
	

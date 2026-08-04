class_name NotebookPage
extends Control

signal limit_reached
signal entry_removed
signal entry_updated(encoded:String, new_text:String)

const LIMIT: = 5


var entries_count: int = 0
var entries: Array[NotebookEntry] = []


func _new_entry(encoded:String, initial_text = "") -> void:
	var entry:NotebookEntry = preload('uid://s4gdpvpyayn0').instantiate()
	
	$Holder.add_child(entry)
	entry.player_input.text = initial_text
	entry.add_resshan(encoded)
	entry.tree_exiting.connect(_remove_entry.bind(entry))
	entry.player_input.text_changed.connect(_handle_entry_update.bind(encoded))
	entries_count += 1
	entries.append(entry)
	if entries_count == LIMIT:
		limit_reached.emit()

func _remove_entry(entry:NotebookEntry) -> void:
	entries_count -= 1
	entries.erase(entry)
	entry_removed.emit()

func _handle_entry_update(new_text:String, encoded:String) -> void:
	entry_updated.emit(encoded, new_text)

class_name NotebookPage
extends Node2D

signal limit_reached
signal entry_removed

const LIMIT: = 10

var entries_count: int = 0
var entries: Array[NotebookEntry] = []

func _new_entry(encoded:String) -> void:
	var entry:NotebookEntry = preload('uid://s4gdpvpyayn0').instantiate()
	
	$Holder.add_child(entry)
	entry.add_resshan(encoded)
	entry.tree_exiting.connect(_remove_entry.bind(entry))
	entries_count += 1
	entries.append(entry)
	if entries_count == LIMIT:
		limit_reached.emit()

func _remove_entry(entry:NotebookEntry) -> void:
	entries_count -= 1
	entries.erase(entry)
	entry_removed.emit()

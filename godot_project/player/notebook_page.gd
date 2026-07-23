class_name NotebookPage
extends Node2D

signal limit_reached

const LIMIT: = 10

var _entries_count: int = 0

func _draw() -> void:
	$Holder/Entry.add_resshan("0.1.2")


func _new_entry(encoded:String) -> void:
	var entry:NotebookEntry = preload('res://player/notebook_entry.tscn').instantiate()
	
	$Holder.add_child(entry)
	entry.add_resshan(encoded)
	entry.tree_exiting.connect(_remove_entry.bind(entry))
	_entries_count += 1
	if _entries_count == LIMIT:
		limit_reached.emit()

func _remove_entry(_entry:NotebookEntry) -> void:
	_entries_count -= 1

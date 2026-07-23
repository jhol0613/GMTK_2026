class_name NotebookPage
extends Node2D


func _draw() -> void:
	$Holder/Entry.add_resshan("0.1.2")


func _new_entry(encoded:String) -> void:
	var entry:NotebookEntry = preload('res://player/notebook_entry.tscn').instantiate()
	
	$Holder.add_child(entry)
	entry.add_resshan(encoded)

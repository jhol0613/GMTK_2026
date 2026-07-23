class_name Notebook
extends Node2D

var _current_page: int = 0

func _ready() -> void:
	for i:Node2D in $Pages.get_children():
		(i as NotebookPage).limit_reached.connect(_handle_limit_reached)

func _handle_limit_reached() -> void:
	_current_page += 1

func _add_entry_to_the_page(encoded:String) -> void:
	if _current_page == $Pages.get_children().size():
		return
	var page: = ($Pages.get_child(_current_page) as NotebookPage)
	page._new_entry(encoded)

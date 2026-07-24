class_name Notebook
extends Node2D

signal notebook_is_full

const PAGE_COUNT: int = 6

var _current_page: int = 0
var _free_page: int = 0
var _pages: Array[NotebookPage] = []

func _ready() -> void:
	SignalBus.resshan_clicked.connect(_add_entry_to_the_page)
	for i:Node2D in $Pages.get_children():
		(i as NotebookPage).limit_reached.connect(_handle_limit_reached)
		(i as NotebookPage).entry_removed.connect(_handle_entry_removed)
		_pages.append(i)
	
	if _current_page == 0:
		%PreviousPage.disabled = true
	if _current_page == PAGE_COUNT:
		%NextPage.disabled = true


func _handle_entry_removed() -> void:
	for i:NotebookPage in _pages:
		if i.entries_count < NotebookPage.LIMIT:
			_free_page = _pages.find(i)
			return


func _handle_limit_reached() -> void:
	for i:NotebookPage in _pages:
		if i.entries_count < NotebookPage.LIMIT:
			_free_page = _pages.find(i)
			return


func _add_entry_to_the_page(encoded:String) -> void:
	if _free_page == -1:
		notebook_is_full.emit()
	var page: = _pages[_free_page]
	page._new_entry(encoded)


func _on_next_page_pressed() -> void:
	_current_page -= 1
	for i:NotebookPage in _pages:
		i.hide()
	_pages[_current_page].show()
	
	%NextPage.disabled = false
	if _current_page == 0:
		%PreviousPage.disabled = true
		return
	


func _on_previous_page_pressed() -> void:
	_current_page += 1
	for i:NotebookPage in _pages:
		i.hide()
	_pages[_current_page].show()
	
	%PreviousPage.disabled = false
	if _current_page == PAGE_COUNT - 1:
		%NextPage.disabled = true
		return

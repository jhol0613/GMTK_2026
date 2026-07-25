class_name Notebook
extends Node2D

signal notebook_is_full

const PAGE_COUNT: int = 6

var _current_page: int = 0
var _free_page: int = 0
var _pages: Array[NotebookPage] = []

var _first_entry := true

@onready var _page_turn_sound: AudioStreamPlayer = $PageTurnSound

func _ready() -> void:
	SignalBus.resshan_clicked.connect(_add_entry_to_the_page)
	SignalBus.resshan_note_requested.connect(_handle_note_requested)
	for i:Node2D in $Pages.get_children():
		(i as NotebookPage).limit_reached.connect(_handle_limit_reached)
		(i as NotebookPage).entry_removed.connect(_handle_entry_removed)
		_pages.append(i)
	
	if _current_page == 0:
		%PreviousPage.disabled = true
	if _current_page == PAGE_COUNT:
		%NextPage.disabled = true

	# Tutorialize the notebook
	_first_entry = false
	_add_entry_to_the_page("58", "The place I'm trying to go")
	_first_entry = true


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


func _handle_note_requested(resshan:ResshanInteractable) -> void:
	for page:NotebookPage in _pages:
		for entry:NotebookEntry in page.entries:
			if entry._resshan_string == resshan._encoded_string:
				resshan.display_note(entry.get_note())


func _add_entry_to_the_page(encoded:String, initial_text = "") -> void:
	for page:NotebookPage in _pages:
		for entry:NotebookEntry in page.entries:
			if entry._resshan_string == encoded:
				return
	if _free_page == -1:
		notebook_is_full.emit()
	var page: = _pages[_free_page]
	if _first_entry:
		initial_text = "I can take notes here!"
	page._new_entry(encoded, initial_text)


func _on_next_page_pressed() -> void:
	_current_page -= 1

	for i: NotebookPage in _pages:
		i.hide()

	_pages[_current_page].show()
	_page_turn_sound.play()

	%NextPage.disabled = false

	if _current_page == 0:
		%PreviousPage.disabled = true
		return
	


func _on_previous_page_pressed() -> void:
	_current_page += 1

	for i: NotebookPage in _pages:
		i.hide()

	_pages[_current_page].show()
	_page_turn_sound.play()

	%PreviousPage.disabled = false

	if _current_page == PAGE_COUNT - 1:
		%NextPage.disabled = true
		return

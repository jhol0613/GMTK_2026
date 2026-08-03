class_name Notebook
extends Node2D

signal notebook_is_full
signal close_requested

const PAGE_COUNT: int = 6


static var player_vocab: Dictionary[String,String] = {
	"59": "The place I am trying to go",
}

var pen = load("uid://c8yj5np7nrak6")
var _current_page: int = 0
var _free_page: int = 0
var _pages: Array[NotebookPage] = []


@onready var _page_turn_sound: AudioStreamPlayer = $PageTurnSound
@onready var _entry_added_sound: AudioStreamPlayer = $EntryAdded

func _ready() -> void:
	add_to_group("world_interaction_blocker")
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
	
	for i:String in player_vocab:
		_add_entry_to_the_page(i, player_vocab[i])


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
	_entry_added_sound.play()
	SignalBus.new_unique_resshan_note_added_to_notebook.emit()
	page._new_entry(encoded, initial_text)
	
	player_vocab[encoded] = initial_text


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


func _on_notebook_mouse_entered() -> void:
	Input.set_custom_mouse_cursor(pen)


func _on_close_button_pressed() -> void:
	close_requested.emit()

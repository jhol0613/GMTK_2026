class_name Notebook
extends Node2D

signal close_requested

static var player_vocab: JSON = preload('res://resshan_systems/player_vocab.json')

var pen = load("uid://c8yj5np7nrak6")
var _current_section: int = 0
var _sections: Array[NotebookSection] = []


@onready var _page_turn_sound: AudioStreamPlayer = $PageTurnSound
@onready var _entry_added_sound: AudioStreamPlayer = $EntryAdded

func _ready() -> void:
	add_to_group("world_interaction_blocker")
	for i in $Sections.get_children():
		_sections.append(i)
	SignalBus.resshan_clicked.connect(_add_entry_to_the_section)
	
	for section:String in player_vocab.data:
		for encoded:String in player_vocab.data[section]:
			_add_entry_to_the_section(
				encoded, player_vocab.data[section][encoded], section, false)


func _handle_entry_removed() -> void:
	pass


func _handle_limit_reached() -> void:
	pass


func _handle_moving_entry(to_section:int, entry:NotebookEntry) -> void:
	for section: NotebookSection in _sections:
		for page: NotebookPage in section.get_pages():
			if page.get_entries().has(entry):
				page.remove_entry(entry)
				_add_entry_to_the_section(
					entry.resshan_string,entry.get_note(), _sections[to_section].section_name
				)
				entry.queue_free()


func _add_entry_to_the_section(
	encoded: String,
	initial_text = "",
	section: String = "Unsorted",
	play_feedback: bool = true,
) -> void:
	var indx: int = -1
	for _section: NotebookSection in _sections:
		if _section.section_name == section:
			indx = _sections.find(_section)
		for page:NotebookPage in _section.get_pages():
			for entry:NotebookEntry in page.get_entries():
				if entry.resshan_string == encoded:
					return
	assert(indx >= 0, 'Section %s does not exist' % [section])
	if _sections[indx].get_pages().is_empty():
		_sections[indx]._new_page()
	var page: = _sections[indx].get_pages()[-1]
	if play_feedback:
		_entry_added_sound.play()
		SignalBus.new_unique_resshan_note_added_to_notebook.emit()
	var entry: = page._new_entry(encoded, initial_text)
	entry.move_requested.connect(_handle_moving_entry.bind(entry))
	
	player_vocab.data[section][encoded] = initial_text


static func get_note(resshan:String) -> ResshanPopUp:
	for section: String in player_vocab.data:
		for encoded: String in player_vocab.data[section]:
			if encoded == resshan:
				var pop: = preload('res://resshan_systems/resshan_pop_up.tscn').instantiate()
				pop.add_note(player_vocab.data[section][encoded])
				return pop
	return null


func _on_next_page_pressed() -> void:
	_sections[_current_section].switch_page(1)
	_page_turn_sound.play()


func _on_previous_page_pressed() -> void:
	_sections[_current_section].switch_page(-1)
	_page_turn_sound.play()


func _on_notebook_mouse_entered() -> void:
	Input.set_custom_mouse_cursor(pen)


func _on_close_button_pressed() -> void:
	close_requested.emit()


func _on_section_switch_pressed(section_indx: int) -> void:
	_sections[_current_section].hide()
	_current_section = section_indx
	_sections[_current_section].show()

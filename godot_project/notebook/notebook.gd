class_name Notebook
extends Node2D

signal close_requested

static var player_vocab: JSON = preload('res://resshan_systems/player_vocab.json')

const TOP_TAB_Z_INDEX = 1

var pen = load("uid://c8yj5np7nrak6")
var _current_section: int = 0
var _sections: Array[NotebookSection] = []


@onready var _page_turn_sound: AudioStreamPlayer = $PageTurnSound
@onready var _entry_added_sound: AudioStreamPlayer = $EntryAdded
@onready var _section_selector_holder := $SectionSelector/Holder

func _ready() -> void:
	add_to_group("world_interaction_blocker")
	for i in $Sections.get_children():
		_sections.append(i)
	SignalBus.resshan_clicked.connect(_add_entry_to_the_section)
	SignalBus.show_resshan_entry.connect(_handle_show_resshan)
	
	for section:String in player_vocab.data:
		for encoded:String in player_vocab.data[section]:
			_add_entry_to_the_section(
				encoded, player_vocab.data[section][encoded], section, false)
	
	for section: NotebookSection in _sections:
		section.header_changed.connect(_on_section_header_changed)
	
	_section_selector_holder.get_child(0).z_index = TOP_TAB_Z_INDEX

#func _process(delta):
	#for section in _sections:
		#if section.get_pages().size() == 0:
			#pass

func _on_section_header_changed(index: int, text: String):
	var tab = _section_selector_holder.get_child(index) as SectionTab
	tab.label.text = text

func _handle_show_resshan(encoded: String) -> void:
	var overlay := get_parent()
	if overlay != null and overlay.has_method("on_notebook_button_pressed"):
		overlay.on_notebook_button_pressed()
	else:
		show()
	var pages: = _sections[0].get_pages()
	for page: NotebookPage in pages:
		for entry: NotebookEntry in page.get_entries():
			if entry.resshan_string == encoded:
				_sections[0].show_page(pages.find(page))

func _handle_entry_removed() -> void:
	pass

func _handle_limit_reached() -> void:
	pass

func _handle_moving_entry(to_section:int, remove_old_entry: bool, entry:NotebookEntry) -> void:
	for section: NotebookSection in _sections:
		for page: NotebookPage in section.get_pages():
			if page.get_entries().has(entry):
				if remove_old_entry:
					page.remove_entry(entry)
				entry = _add_entry_to_the_section(
					entry.resshan_string,entry.get_note(), _sections[to_section].section_name
				)
				#if remove_old_entry:
					#entry.queue_free()
				return

func _on_switch_section_requested(to_section, dragged_data: NotebookEntry = null):
	_on_section_switch_pressed(to_section)
	if dragged_data:
		dragged_data.reparent(_sections[_current_section].get_pages()[-1].holder, false)

func _add_entry_to_the_section(
	encoded: String,
	initial_text = "",
	section: String = "Unsorted",
	play_feedback: bool = true,
) -> NotebookEntry:
	var indx: int = -1
	for _section: NotebookSection in _sections:
		if _section.section_name == section:
			indx = _sections.find(_section)
		for page:NotebookPage in _section.get_pages():
			for entry:NotebookEntry in page.get_entries():
				if entry.resshan_string == encoded:
					return
	assert(indx >= 0, 'Section %s does not exist' % [section])
	var page := _sections[indx].get_entry_page()
	if play_feedback:
		_entry_added_sound.play()
		SignalBus.new_unique_resshan_note_added_to_notebook.emit()
	var entry: = page._new_entry(encoded, initial_text)
	entry.move_requested.connect(_handle_moving_entry.bind(entry))
	entry.request_switch_section_view.connect(_on_switch_section_requested.bind(entry))
	entry.reordered.connect(_on_entry_reordered)
	
	player_vocab.data[section][encoded] = initial_text
	
	return entry


static func get_note(resshan:String) -> ResshanPopUp:
	for section: String in player_vocab.data:
		for encoded: String in player_vocab.data[section]:
			if encoded == resshan:
				var pop: = preload('res://resshan_systems/resshan_pop_up.tscn').instantiate()
				pop.add_note(player_vocab.data[section][encoded])
				return pop
	return null


static func has_note(resshan: String) -> bool:
	for section: String in player_vocab.data:
		if player_vocab.data[section].has(resshan):
			return true
	return false

func _on_entry_reordered() -> void:
	_entry_added_sound.play()

func _on_next_page_pressed() -> void:
	_sections[_current_section].switch_page(1)
	_page_turn_sound.play()


func _on_previous_page_pressed() -> void:
	_sections[_current_section].switch_page(-1)
	_page_turn_sound.play()


func _on_notebook_mouse_entered() -> void:
	Input.set_custom_mouse_cursor(pen, Input.CURSOR_ARROW, Vector2(0, 32) )

func _on_notebook_mouse_exited() -> void:
	var section = _sections[_current_section] as NotebookSection
	var page = section.get_pages()[section.current_page] as NotebookPage
	page.hide_drop_indicator()

func _on_close_button_pressed() -> void:
	close_requested.emit()

func _on_section_switch_pressed(section_indx: int) -> void:
	_page_turn_sound.play()
	_sections[_current_section].hide()
	var tab: SectionTab = _section_selector_holder.get_child(_current_section)
	tab.sticker.visible = false
	tab.z_index = tab.original_z_index

	_current_section = section_indx
	_sections[_current_section].show()
	tab = _section_selector_holder.get_child(_current_section)
	tab.sticker.visible = true
	tab.z_index = TOP_TAB_Z_INDEX

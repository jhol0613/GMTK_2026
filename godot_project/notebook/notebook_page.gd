class_name NotebookPage
extends Control


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.double_click and event.button_index == MOUSE_BUTTON_LEFT:
			_new_text_entry()
		if event.double_click and event.button_index == MOUSE_BUTTON_RIGHT:
			_new_resshan_entry()

func _new_resshan_entry() -> void:
	var entry: = Control.new()
	entry.size = Vector2.ZERO
	
	add_child(entry)
	entry.position = get_local_mouse_position()
	entry.draw.connect(LanguageRenderer.draw_text.bind("<<train>>", entry))
	entry.queue_redraw()

func _new_text_entry() -> void:
	var entry:LineEdit = LineEdit.new()
	
	add_child(entry)
	entry.grab_focus()
	entry.size.x = 2000
	entry.mouse_filter = Control.MOUSE_FILTER_IGNORE
	entry.add_theme_stylebox_override('focus', StyleBoxEmpty.new())
	entry.add_theme_color_override('font_color', Color.BLACK)
	entry.add_theme_color_override('caret_color', Color.BLACK)
	entry.add_theme_font_size_override('font_size', 45)
	entry.add_theme_font_override('font', preload("res://resources/fonts/Embolism Spark.ttf"))
	entry.flat = true
	entry.position = get_local_mouse_position()
	entry.editing_toggled.connect(_lock_entry.bind(entry))

func _lock_entry(entry:LineEdit, editing:bool) -> void:
	if not editing:
		entry.editable = false

func _handle_entry_update(new_text:String, encoded:String) -> void:
	Notebook.player_vocab[encoded] = new_text

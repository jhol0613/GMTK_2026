class_name ResshanInteractable
extends Control

const TIME_TO_HOVER: = .4

@export var _string: String = '' :
	set(new_value):
		_string = new_value
		if not _string.is_empty():
			_encoded_string = LanguageRenderer.encode(_string)
		
var _encoded_string: String = ''
var note_popup_scale_multiplier := 1.0

var _hovered: = false
var note: ResshanPopUp = null
var noted: = false

var magnifying_glass_hover = load("uid://rwsmjgconr7m")
var magnifying_glass_hover_known = load("uid://b8iogjde6ylvv")
var magnifying_glass = load("uid://c8n3by2cmh20k")
var shader: ShaderMaterial = preload('uid://b6orlsmg3aep5')
var _shine_cover: ColorRect

func _ready() -> void:
	if not _string.is_empty():
		_encoded_string = LanguageRenderer.encode(_string)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	_shine_cover = ColorRect.new()
	_shine_cover.hide()
	_shine_cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shine_cover.size = size
	_shine_cover.material = shader
	_shine_cover.z_index = 10
	add_child(_shine_cover)
	


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if shader:
		shader.set_shader_parameter('time', shader.get_shader_parameter('time') + .05 * delta)


func _gui_input(event: InputEvent) -> void:
	if (
		event is InputEventMouseButton
		and not event.pressed
		and event.button_index == MOUSE_BUTTON_LEFT
	):
		if Notebook.has_note(_encoded_string):
			SignalBus.show_resshan_entry.emit(_encoded_string)
		else:
			noted = true
			Input.set_custom_mouse_cursor(magnifying_glass_hover_known, Input.CURSOR_ARROW, Vector2(0,0) )
			shader.set_shader_parameter('color', Color.WHITE)
			SignalBus.resshan_clicked.emit(_encoded_string)
		accept_event()


func _on_mouse_entered() -> void:
	if get_tree().get_first_node_in_group("ui_overlay").dragging_item:
		return
	var pop: = Notebook.get_note(_encoded_string)
	
	if pop:
		noted = true
		if note:
			note.add_note(pop.get_note())
			pop.queue_free()
		else:
			note = pop
			note.scale *= note_popup_scale_multiplier
	_shine_cover.show()
	if noted:
		Input.set_custom_mouse_cursor(magnifying_glass_hover_known, Input.CURSOR_ARROW, Vector2(0,0) )
		shader.set_shader_parameter('color', Color.WHITE)
	else:
		Input.set_custom_mouse_cursor(magnifying_glass_hover, Input.CURSOR_ARROW, Vector2(0,0) )
		shader.set_shader_parameter('color', Color(1.0, 0.922, 0.569))
	
	shader.set_shader_parameter('time', -0.5)
	
	
	_hovered = true
	display_note()


func _on_mouse_exited() -> void:
	if get_tree().get_first_node_in_group("ui_overlay").dragging_item:
		return
	_shine_cover.hide()
	Input.set_custom_mouse_cursor(magnifying_glass, Input.CURSOR_ARROW, Vector2(0,0) )
	_hovered = false
	if note:
		note.hide()


func display_note() -> void:
	if note: 
		if not note.get_parent():
			add_child(note)
		note.position.x = size.x * 0.5
		note.show()

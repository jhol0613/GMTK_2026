class_name ResshanInteractable
extends Control

const TIME_TO_HOVER: = .4

@export var _string: String = '' :
	set(new_value):
		_string = new_value
		if not _string.is_empty():
			_encoded_string = LanguageRenderer.encode(_string)
		
var _encoded_string: String = ''
@export var note_popup_scale_multiplier := 1.0
@export var enabled := true

var _hovered: = false
var _left_pressed := false
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
	if _hovered and not _can_interact():
		_clear_hover()
	elif not _hovered and get_viewport().gui_get_hovered_control() == self and _can_interact():
		_on_mouse_entered()
	if shader:
		shader.set_shader_parameter('time', shader.get_shader_parameter('time') + .05 * delta)


func _gui_input(event: InputEvent) -> void:
	if not _can_interact():
		_left_pressed = false
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_left_pressed = true
		accept_event()
		return
	if (
		event is InputEventMouseButton
		and not event.pressed
		and event.button_index == MOUSE_BUTTON_LEFT
		and enabled
		and _left_pressed
	):
		_left_pressed = false
		if Notebook.has_note(_encoded_string):
			SignalBus.show_resshan_entry.emit(_encoded_string)
		else:
			noted = true
			Input.set_custom_mouse_cursor(magnifying_glass_hover_known, Input.CURSOR_ARROW, Vector2(0,0) )
			shader.set_shader_parameter('color', Color.WHITE)
			SignalBus.resshan_clicked.emit(_encoded_string)
		accept_event()
	


func _on_mouse_entered() -> void:
	if not _can_interact():
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
	_clear_hover()


func _clear_hover() -> void:
	_left_pressed = false
	_shine_cover.hide()
	var hovered_control := get_viewport().gui_get_hovered_control()
	var another_word_hovered: bool = (
		hovered_control is ResshanInteractable
		and hovered_control != self
		and hovered_control._hovered
	)
	if _hovered and not another_word_hovered:
		Input.set_custom_mouse_cursor(magnifying_glass, Input.CURSOR_ARROW, Vector2.ZERO)
	_hovered = false
	if is_instance_valid(note):
		note.queue_free()
	note = null


func _can_interact() -> bool:
	if not enabled or not is_visible_in_tree():
		return false
	var ui := get_tree().get_first_node_in_group("ui_overlay")
	if ui != null and ui.dragging_item:
		return false
	var ancestor := get_parent()
	while ancestor != null:
		if ancestor is InteractionPanelBase:
			return ancestor.is_open()
		if ancestor == ui:
			return true
		ancestor = ancestor.get_parent()
	if ui != null and (ui._has_open_panel(false) or ui._item_popup.visible):
		return false
	for panel in get_tree().get_nodes_in_group("interaction_panel"):
		if panel.is_open():
			return false
	for blocker in get_tree().get_nodes_in_group("world_interaction_blocker"):
		# Notebook only blocks words under its GUI, not exposed world text.
		# Keep its blocker group for ordinary NPC / E-key interactions.
		if blocker is Notebook:
			continue
		if blocker is CanvasItem and blocker.is_visible_in_tree():
			return false
	return true


func display_note() -> void:
	if not _can_interact():
		return
	if note:
		var parent := get_tree().get_first_node_in_group( "popup_layer" )
		if not note.get_parent():
			parent.add_child(note)
		else:
			note.reparent(parent)
		
		#cursor -> viewport position -> local position relative to Level scene. As long as Level is
		#at global (0,0) this converts viewport position into global position. Required because mouse
		#global position is not accurate when in Dialog
		note.global_position = get_tree().get_first_node_in_group( "level" ).make_canvas_position_local( get_viewport().get_mouse_position() ) + Vector2(0,-16)
		
		note.constrain()
		note.show()

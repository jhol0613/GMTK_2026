class_name ResshanInteractable
extends Area2D

const TIME_TO_HOVER: = 1.0

@export var _string: String = ''
var _encoded_string: String = ''

var _hovered: = false
var note: ResshanPopUp = null

func _ready() -> void:
	if not _string.is_empty():
		_encoded_string = LanguageRenderer.encode(_string)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			SignalBus.resshan_clicked.emit(_encoded_string)


func _on_mouse_entered() -> void:
	_hovered = true
	get_tree().create_timer(TIME_TO_HOVER).timeout.connect( func ():
		SignalBus.resshan_note_requested.emit(self)
	)


func _on_mouse_exited() -> void:
	_hovered = false
	if note:
		note.queue_free()
	note = null


func display_note(text:String) -> void:
	if note or not _hovered:
		return
	var pop_up: ResshanPopUp = preload("uid://bvunhdmuxhfji").instantiate()
	pop_up.add_note(text)
	note = pop_up
	add_child(pop_up)

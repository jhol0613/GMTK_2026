class_name ResshanPopUp
extends Control

func _process(delta: float) -> void:
	$CanvasLayer.offset = get_global_mouse_position()

func add_note(note:String) -> void:
	$CanvasLayer/PanelContainer/MarginContainer/Note.text = note

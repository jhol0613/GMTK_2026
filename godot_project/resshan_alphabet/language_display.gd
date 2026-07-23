@tool
class_name ResshanLabel2D
extends Node2D

@export_multiline() var string:String :
	set(value):
		string = value
		queue_redraw()

func _draw() -> void:
	LanguageRenderer.draw_text(string, self)

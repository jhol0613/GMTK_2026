extends Node2D

@export_multiline() var string:String

func _draw() -> void:
	LanguageRenderer.draw_text(string, self)

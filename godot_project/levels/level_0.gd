extends "res://levels/level_template.gd"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()
	var _intro_conversation_scene = preload("uid://b40aq7wt2wqcs").instantiate()
	add_child(_intro_conversation_scene)

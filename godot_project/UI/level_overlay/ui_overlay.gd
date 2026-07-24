extends Node2D


@export var mouse_hover_offset := Vector2(0, -8)

@onready var _notebook := $Notebook
@onready var _notebook_button := $NotebookButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_notebook.visible = false
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_notebook_button_mouse_entered() -> void:
	_notebook_button.position += mouse_hover_offset


func _on_notebook_button_mouse_exited() -> void:
	_notebook_button.position -= mouse_hover_offset


func _on_notebook_button_pressed() -> void:
	_notebook.visible = true


func _on_exit_button_pressed() -> void:
	_notebook.visible = false

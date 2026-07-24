extends CanvasLayer

@export var mouse_hover_offset := Vector2(0, -8)

@onready var _notebook := $Notebook
@onready var _notebook_button := $NotebookButton
@onready var _ticket_button := $TicketButton
@onready var _ticket := $Ticket


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_notebook.visible = false
	_ticket.visible = false
	_refresh_ticket()
	Inventory.inventory_changed.connect(_refresh_ticket)
	


func _refresh_ticket() -> void:
	var ticket := Inventory.get_ticket()
	_ticket_button.visible = ticket != null
	if ticket == null:
		_ticket.visible = false
	else:
		_ticket.set_ticket(ticket)


func _on_notebook_button_mouse_entered() -> void:
	_notebook_button.position += mouse_hover_offset


func _on_notebook_button_mouse_exited() -> void:
	_notebook_button.position -= mouse_hover_offset


func _on_notebook_button_pressed() -> void:
	_notebook.visible = true


func _on_exit_button_pressed() -> void:
	_notebook.visible = false


func _on_ticket_button_mouse_entered():
	_ticket_button.position += mouse_hover_offset


func _on_ticket_button_mouse_exited():
	_ticket_button.position -= mouse_hover_offset


func _on_ticket_button_pressed():
	if Inventory.get_ticket() == null:
		return
	_ticket.visible = not _ticket.visible

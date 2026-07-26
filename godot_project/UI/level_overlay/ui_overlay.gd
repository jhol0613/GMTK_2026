extends CanvasLayer

@export var mouse_hover_offset := Vector2(0, -8)

@onready var _notebook := $Notebook
@onready var _notebook_button := $NotebookButton
@onready var _ticket_button := $TicketButton
@onready var _ticket := $Ticket
@onready var _notebook_hover_sound: AudioStreamPlayer = $NotebookHoverSound
@onready var _notebook_click_sound: AudioStreamPlayer = $NotebookClickSound
@onready var _notebook_exit_sound: AudioStreamPlayer = $NotebookCloseSound
@onready var _ticket_hover_sound: AudioStreamPlayer = $TicketHoverSound
@onready var _ticket_click_sound: AudioStreamPlayer = $TicketClickSound



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
	_notebook_hover_sound.play()

func _on_notebook_button_mouse_exited() -> void:
	_notebook_button.position -= mouse_hover_offset


func _on_notebook_button_pressed() -> void:
	if _notebook.visible:
		_close_notebook()
	else:
		_open_notebook()

func _on_ticket_button_mouse_entered():
	_ticket_button.position += mouse_hover_offset
	_notebook_hover_sound.play()


func _on_ticket_button_mouse_exited():
	_ticket_button.position -= mouse_hover_offset


func _on_ticket_button_pressed():
	_ticket_click_sound.play()
	if Inventory.get_ticket() == null:
		return
	_ticket.visible = not _ticket.visible
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("escape"):
		if _ticket.visible:
			_ticket_click_sound.play()
		if _notebook.visible:
			_notebook_click_sound.play()
		_ticket.visible = false
		_notebook.visible = false
		
		# Enable player movement if closing the notebook
		for player in get_tree().get_nodes_in_group("player"):
			player.movement_disabled = false
			
func _open_notebook() -> void:
	if _notebook.visible:
		return

	_notebook_click_sound.play()
	_notebook.visible = true

	for player in get_tree().get_nodes_in_group("player"):
		player.movement_disabled = true

	SignalBus.notebook_opened.emit()


func _close_notebook() -> void:
	if not _notebook.visible:
		return

	_notebook_exit_sound.play()
	_notebook.visible = false

	for player in get_tree().get_nodes_in_group("player"):
		player.movement_disabled = false

	SignalBus.notebook_closed.emit()

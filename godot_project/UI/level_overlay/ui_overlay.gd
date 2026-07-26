extends CanvasLayer

@export var mouse_hover_offset := Vector2(0, -8)
var magnifying_glass = load("uid://c8n3by2cmh20k")
var pen = load("uid://c8yj5np7nrak6")

@onready var _notebook := $Notebook
@onready var _notebook_button := $NotebookButton
@onready var _ticket_button := $TicketButton
@onready var _ticket := $Ticket
@onready var _inventory_button := $InventoryButton
@onready var _inventory := $InventoryPanel
@onready var _notebook_hover_sound: AudioStreamPlayer = $NotebookHoverSound
@onready var _notebook_click_sound: AudioStreamPlayer = $NotebookClickSound
@onready var _notebook_exit_sound: AudioStreamPlayer = $NotebookCloseSound
@onready var _ticket_hover_sound: AudioStreamPlayer =$TicketHoverSound
@onready var _ticket_click_sound: AudioStreamPlayer = $TicketClickSound
@onready var _inventory_hover_sound: AudioStreamPlayer = $InventoryHoverSound
@onready var _inventory_click_sound: AudioStreamPlayer = $InventoryClickSound

@onready var _initial_notebook_button_scale = _notebook_button.scale



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_notebook.visible = false
	_ticket.visible = false
	_inventory.visible = false
	_refresh_ticket()
	Inventory.inventory_changed.connect(_refresh_ticket)
	Inventory.inventory_changed.connect(_inventory.refresh)
	SignalBus.new_unique_resshan_note_added_to_notebook.connect(_emphasize_notebook_icon)

func _refresh_ticket() -> void:
	var ticket := Inventory.get_ticket()
	_ticket_button.visible = ticket != null
	if ticket == null:
		_ticket.visible = false
	else:
		_ticket.set_ticket(ticket)

func _emphasize_notebook_icon():
	var tween = create_tween()
	tween.tween_property(_notebook_button, "scale", (_initial_notebook_button_scale * 1.1), .08)
	await tween.finished
	tween.kill()
	tween = create_tween()
	tween.tween_property(_notebook_button, "scale", (_initial_notebook_button_scale), .08)

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
	_ticket_hover_sound.play()


func _on_ticket_button_mouse_exited():
	_ticket_button.position -= mouse_hover_offset


func _on_ticket_button_pressed() -> void:
	if Inventory.get_ticket() == null:
		return

	if _ticket.visible:
		_close_ticket()
	else:
		_open_ticket()

func _on_inventory_button_mouse_entered() -> void:
	_inventory_button.position += mouse_hover_offset
	_inventory_hover_sound.play()


func _on_inventory_button_mouse_exited() -> void:
	_inventory_button.position -= mouse_hover_offset


func _on_inventory_button_pressed() -> void:
	if _inventory.visible:
		_close_inventory()
	else:
		_open_inventory()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("escape"):
		if _ticket.visible:
			_ticket_click_sound.play()
		if _notebook.visible:
			_notebook_click_sound.play()
		if _inventory.visible:
			_inventory_click_sound.play()
		_ticket.visible = false
		_notebook.visible = false
		_inventory.visible = false
		
		# Enable player movement if closing the notebook
		for player in get_tree().get_nodes_in_group("player"):
			player.movement_disabled = false
			
func _open_notebook() -> void:
	if _notebook.visible:
		return
	
	Input.set_custom_mouse_cursor(pen)
	
	_notebook_click_sound.play()
	_notebook.visible = true

	for player in get_tree().get_nodes_in_group("player"):
		player.movement_disabled = true

	SignalBus.notebook_opened.emit()


func _close_notebook() -> void:
	if not _notebook.visible:
		return
	
	Input.set_custom_mouse_cursor(magnifying_glass)
	
	_notebook_exit_sound.play()
	_notebook.visible = false

	for player in get_tree().get_nodes_in_group("player"):
		player.movement_disabled = false

	SignalBus.notebook_closed.emit()

func _open_ticket() -> void:
	if _ticket.visible:
		return

	_ticket_click_sound.play()
	_ticket.visible = true


func _close_ticket() -> void:
	if not _ticket.visible:
		return

	_ticket_click_sound.play()
	_ticket.visible = false

func _open_inventory() -> void:
	if _inventory.visible:
		return

	_inventory_click_sound.play()
	_inventory.refresh()
	_inventory.visible = true


func _close_inventory() -> void:
	if not _inventory.visible:
		return

	_inventory_click_sound.play()
	_inventory.visible = false

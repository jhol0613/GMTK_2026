extends CanvasLayer

@export var mouse_hover_offset := Vector2(0, -8)
@export var notebook_dock_x := 1568.0
@export var notebook_offscreen_x := 2272.0
@export var notebook_slide_time := 0.3

var magnifying_glass = load("uid://c8n3by2cmh20k")
var pen = load("uid://c8yj5np7nrak6")

var _notebook_home := Vector2.ZERO
var _notebook_docked := false
var _notebook_tween: Tween

@onready var _time := $Time
@onready var _animation_player: AnimationPlayer = $AnimationPlayer
@onready var _notebook: Notebook = $Notebook
@onready var _notebook_button : TextureButton = $NotebookButton
@onready var _ticket_button : TextureButton = $TicketButton
@onready var _ticket: Ticket = $Ticket
@onready var _inventory_button : TextureButton = $InventoryButton
@onready var _inventory: InventoryPanel = $InventoryPanel
@onready var _options_button: Button = $OptionsButton
@onready var _notebook_hover_sound: AudioStreamPlayer = $NotebookHoverSound
@onready var _notebook_click_sound: AudioStreamPlayer = $NotebookClickSound
@onready var _notebook_exit_sound: AudioStreamPlayer = $NotebookCloseSound
@onready var _ticket_hover_sound: AudioStreamPlayer =$TicketHoverSound
@onready var _ticket_click_sound: AudioStreamPlayer = $TicketClickSound
@onready var _ticket_close_sound: AudioStreamPlayer = $TicketCloseSound
@onready var _inventory_hover_sound: AudioStreamPlayer = $InventoryHoverSound
@onready var _inventory_click_sound: AudioStreamPlayer = $InventoryClickSound
@onready var _inventory_close_sound: AudioStreamPlayer = $InventoryCloseSound
@onready var _item_popup: Control = $ItemPopup
@onready var _item_popup_icon: TextureRect = $ItemPopup/Icon

@onready var _initial_notebook_button_scale: Vector2 = _notebook_button.scale
@onready var _initial_inventory_button_scale: Vector2 = _inventory_button.scale
@onready var _initial_ticket_button_scale: Vector2 = _ticket_button.scale

const TICKET_BUTTON_SHOW_DELAY := 2.0

var _item_popup_tween: Tween
var _ticket_button_show_tween: Tween


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameManager.pause_enabled = true
	_notebook_home = _notebook.position
	_notebook.visible = false
	_ticket.visible = false
	_inventory.visible = false
	_item_popup.visible = false
	_ticket_button.visible = false
	_refresh_ticket()
	Inventory.inventory_changed.connect(_refresh_ticket)
	Inventory.inventory_changed.connect(_inventory.refresh)
	Inventory.item_added.connect(_on_item_added)
	SignalBus.new_unique_resshan_note_added_to_notebook.connect( _emphasize_icon.bind(_notebook_button,_initial_notebook_button_scale) )
	TimeManager.time_up.connect(_on_time_up)
	
	SignalBus.ticket_consumed.connect(_on_ticket_consumed)
	_notebook.close_requested.connect(close_notebook)
	_ticket.close_requested.connect(_close_ticket)
	_inventory.close_requested.connect(_close_inventory)


func _on_time_up() -> void:
	# Keep the overlay (clock tick + time_up anim) alive while the world freezes.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_animation_player.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true

	if _time.has_method("tick_second"):
		_time.tick_second()

	_animation_player.play(&"time_up")
	await _animation_player.animation_finished
	GameManager.load_scene(Enums.Scenes.BAD_ENDING)


func _refresh_ticket() -> void:
	var ticket := Inventory.get_ticket()
	if _ticket_button_show_tween != null and _ticket_button_show_tween.is_valid():
		_ticket_button_show_tween.kill()
		_ticket_button_show_tween = null

	if ticket == null:
		_ticket_button.visible = false
		_ticket.visible = false
		return

	_ticket.set_ticket(ticket)
	if _ticket_button.visible:
		return

	_ticket_button_show_tween = create_tween()
	_ticket_button_show_tween.tween_interval(TICKET_BUTTON_SHOW_DELAY)
	_ticket_button_show_tween.tween_callback(func() -> void:
		_ticket_button.visible = true
	)


func _emphasize_icon( button:TextureButton, initial_scale:Vector2 ):
	var tween = create_tween()
	tween.tween_property(button, "scale", (initial_scale * 1.5), .08)
	await tween.finished
	tween.kill()
	tween = create_tween()
	tween.tween_property(button, "scale", initial_scale, .08)


func _on_notebook_button_mouse_entered() -> void:
	_notebook_button.position += mouse_hover_offset
	_notebook_hover_sound.play()


func _on_notebook_button_mouse_exited() -> void:
	_notebook_button.position -= mouse_hover_offset


func _on_notebook_button_pressed() -> void:
	if _notebook.visible:
		close_notebook()
	else:
		open_notebook()


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
		if _has_open_panel():
			_close_all_panels()
			get_viewport().set_input_as_handled()
		return

	var pointer_position := _get_pressed_pointer_position(event)
	if pointer_position == Vector2.INF:
		return

	if _is_over_launcher_button(pointer_position):
		return

	var closed_something := false

	var over_notebook := (
		_sprite_contains_point($Notebook/Sprite2D, pointer_position)
		or _control_contains_point($Notebook/SectionSelector/Holder, pointer_position)
	)
	if _notebook.visible and not over_notebook:
		close_notebook()
		closed_something = true

	if _ticket.visible and not _sprite_contains_point($Ticket/Background, pointer_position):
		_close_ticket()
		closed_something = true

	if _inventory.visible and not _control_contains_point(_inventory, pointer_position):
		_close_inventory()
		closed_something = true

	if closed_something:
		get_viewport().set_input_as_handled()
		


func open_notebook() -> void:
	if _notebook.visible:
		return

	_close_ticket()
	_close_inventory()
	
	Input.set_custom_mouse_cursor(pen)

	_notebook_click_sound.play()

	_notebook_docked = _is_dialogue_open()
	if _notebook_docked:
		_notebook.position = Vector2(notebook_offscreen_x, _notebook_home.y)
		_notebook.visible = true
		_slide_notebook(notebook_dock_x)
	else:
		_notebook.position = _notebook_home
		_notebook.visible = true

	for player in get_tree().get_nodes_in_group("player"):
		player.movement_disabled = true

	SignalBus.notebook_opened.emit()


func _is_dialogue_open() -> bool:
	for panel in get_tree().get_nodes_in_group("interaction_panel"):
		if panel.has_method("is_open") and panel.is_open():
			return true
	return false


func _slide_notebook(target_x: float) -> Tween:
	if _notebook_tween != null and _notebook_tween.is_valid():
		_notebook_tween.kill()
	_notebook_tween = create_tween()
	_notebook_tween.set_ease(Tween.EASE_OUT)
	_notebook_tween.set_trans(Tween.TRANS_CUBIC)
	_notebook_tween.tween_property(
		_notebook, "position:x", target_x, notebook_slide_time
	)
	return _notebook_tween


func close_notebook() -> void:
	if not _notebook.visible:
		return

	Input.set_custom_mouse_cursor(magnifying_glass)

	_notebook_exit_sound.play()

	if _notebook_docked:
		_notebook_docked = false
		var tween := _slide_notebook(notebook_offscreen_x)
		tween.tween_callback(func() -> void: _notebook.visible = false)
	else:
		_notebook.visible = false

	if not _is_dialogue_open():
		for player in get_tree().get_nodes_in_group("player"):
			player.movement_disabled = false

	SignalBus.notebook_closed.emit()


func _open_ticket() -> void:
	if _ticket.visible:
		return

	close_notebook()
	_close_inventory()

	_ticket_click_sound.play()
	_ticket.visible = true


func _close_ticket() -> void:
	if not _ticket.visible:
		return

	_ticket_close_sound.play()
	_ticket.visible = false


func _open_inventory() -> void:
	if _inventory.visible:
		return

	close_notebook()
	_close_ticket()

	_inventory_click_sound.play()
	_inventory.refresh()
	_inventory.visible = true


func _close_inventory() -> void:
	if not _inventory.visible:
		return

	_inventory_close_sound.play()
	_inventory.visible = false


func _close_all_panels() -> void:
	close_notebook()
	_close_ticket()
	_close_inventory()


func _has_open_panel() -> bool:
	return _notebook.visible or _ticket.visible or _inventory.visible


func _get_pressed_pointer_position(event: InputEvent) -> Vector2:
	if (
		event is InputEventMouseButton
		and event.button_index == MOUSE_BUTTON_LEFT
		and event.pressed
	):
		return event.position

	if event is InputEventScreenTouch and event.pressed:
		return event.position

	return Vector2.INF


func _is_over_launcher_button(point: Vector2) -> bool:
	for button: Control in [
		_notebook_button,
		_ticket_button,
		_inventory_button,
		_options_button,
	]:
		if button.visible and _control_contains_point(button, point):
			return true

	return false


func _control_contains_point(control: Control, point: Vector2) -> bool:
	var local_point := (
		control.get_global_transform_with_canvas().affine_inverse()
		* point
	)
	return Rect2(Vector2.ZERO, control.size).has_point(local_point)


func _sprite_contains_point(sprite: Sprite2D, point: Vector2) -> bool:
	var local_point := (
		sprite.get_global_transform_with_canvas().affine_inverse()
		* point
	)
	return sprite.get_rect().has_point(local_point)


func _on_item_added(item: ItemData) -> void:
	var icon: Texture2D = item.item_icon
	if item is TicketData:
	# if icon == null and item is TicketData:
		icon = _ticket_button.texture_normal
	if icon == null:
		return
	_show_item_popup(icon, item)


func _show_item_popup(icon: Texture2D, item: ItemData) -> void:
	if _item_popup_tween != null and _item_popup_tween.is_valid():
		_item_popup_tween.kill()

	_item_popup_icon.texture = icon
	_item_popup.visible = true
	_item_popup_icon.modulate = Color(1, 1, 1, 0)
	_item_popup_icon.scale = Vector2(0.6, 0.6)

	_item_popup_tween = create_tween()
	_item_popup_tween.set_parallel(true)
	_item_popup_tween.tween_property(_item_popup_icon, "modulate:a", 1.0, 0.2)
	_item_popup_tween.tween_property(_item_popup_icon, "scale", Vector2.ONE, 0.25)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_item_popup_tween.set_parallel(false)
	_item_popup_tween.tween_interval(1.2)
	_item_popup_tween.tween_property(_item_popup_icon, "modulate:a", 0.0, 0.35)
	_item_popup_tween.tween_callback(_hide_item_popup.bind(item))


func _hide_item_popup(item : ItemData):
	_item_popup.visible = false
	if item is TicketData: _emphasize_icon(_ticket_button, _initial_ticket_button_scale)
	else: _emphasize_icon(_inventory_button, _initial_inventory_button_scale)
	

func _on_ticket_consumed():
	_animation_player.play("ticket_consumed")

func _on_options_button_pressed() -> void:
	if _notebook.visible:
		close_notebook()

	if _ticket.visible:
		_close_ticket()

	if _inventory.visible:
		_close_inventory()

	GameManager.pause_game()

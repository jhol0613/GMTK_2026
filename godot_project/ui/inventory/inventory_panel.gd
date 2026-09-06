class_name InventoryPanel
extends Control

signal close_requested

const SLOT_COUNT: int = 4

@export var _slots: Array[InventorySlot]
@export var slot_h_box: HBoxContainer

var hand_open = load("uid://xuaolfjqb2gn")
var hand_closed = load("uid://w4yu8aix4u4b")
var magnifying_glass = load("uid://c8n3by2cmh20k")

var _items: Array[ItemData] = []
var _drag_item: ItemData
var _drag_ghost: TextureRect
var _hovered_bin: Node2D


func _ready() -> void:
	refresh()


func refresh() -> void:
	_items.clear()
	for item in Inventory.items:
		if item is TicketData:
			continue
		_items.append(item)

	for i in SLOT_COUNT:
		var icon := _slots[i].slut_icon
		var name_label := _slots[i].slut_name
		if i < _items.size():
			icon.texture = _items[i].item_icon
			icon.visible = icon.texture != null
			name_label.text = _items[i].item_name
			name_label.visible = not _items[i].item_name.is_empty()
		else:
			icon.texture = null
			icon.visible = false
			name_label.text = ""
			name_label.visible = false


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_start_drag(event.position)
		elif _drag_item != null:
			_finish_drag()
	elif event is InputEventMouseMotion:
		_update_cursor(event.position)
		if _drag_item:
			_drag_ghost.global_position = event.position - _drag_ghost.size * 0.5
			_update_hovered_bin(event.position)


func _start_drag(pos: Vector2) -> void:
	
	for i in mini(_items.size(), SLOT_COUNT):
		#if not _slots[i].slut_icon.get_global_rect().has_point(pos):
		if not _slots[i].slut_icon.get_global_rect().has_point(pos):
			continue
		Input.set_custom_mouse_cursor(hand_closed, Input.CURSOR_ARROW, Vector2(16,16) )
		get_tree().get_first_node_in_group("ui_overlay").dragging_item = true
		_drag_item = _items[i]
		_drag_ghost = TextureRect.new()
		_drag_ghost.texture = _drag_item.item_icon
		_drag_ghost.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_drag_ghost.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_drag_ghost.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_drag_ghost.size = _slots[i].slut_icon.size
		_drag_ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_drag_ghost.z_index = 100
		add_child(_drag_ghost)
		_drag_ghost.global_position = pos - _drag_ghost.size * 0.5
		_slots[i].slut_icon.visible = false
		_slots[i].slut_name.visible = false
		return


func _update_hovered_bin(pos: Vector2) -> void:
	var bin: Node2D = null
	for node in get_tree().get_nodes_in_group("recycle_bin"):
		var candidate := node as Node2D
		var screen_pos := candidate.get_global_transform_with_canvas().origin
		if pos.distance_to(screen_pos) <= candidate.drop_radius:
			bin = candidate
			break

	if bin == _hovered_bin:
		return
	if _hovered_bin != null:
		_hovered_bin.set_lid_open(false)
	_hovered_bin = bin
	if _hovered_bin != null:
		_hovered_bin.set_lid_open(true)


func _finish_drag() -> void:
	get_tree().get_first_node_in_group("ui_overlay").dragging_item = false
	Input.set_custom_mouse_cursor(magnifying_glass, Input.CURSOR_ARROW, Vector2(0.0,0.0) )
	if _hovered_bin != null:
		_hovered_bin.recycle(_drag_item)
	_hovered_bin = null
	_drag_item = null
	
	if _drag_ghost:
		_drag_ghost.queue_free()
		_drag_ghost = null
	refresh()


func _on_close_button_pressed() -> void:
	close_requested.emit()


func _update_cursor(pos: Vector2):
	if _drag_item:
		return
	
	for i in mini( _items.size(), SLOT_COUNT ):
		if not _slots[i].slut_icon.get_global_rect().has_point( pos ):
			continue
		Input.set_custom_mouse_cursor(hand_open, Input.CURSOR_ARROW, Vector2(16,16) )
		return
	
	#Input.set_custom_mouse_cursor(magnifying_glass, Input.CURSOR_ARROW, Vector2(0.0,0.0) )


func _on_slots_mouse_exited() -> void:
	
	if _drag_item or slot_h_box.get_global_rect().has_point(get_global_mouse_position()) :
		return
	Input.set_custom_mouse_cursor( magnifying_glass, Input.CURSOR_ARROW, Vector2(0.0,0.0) )

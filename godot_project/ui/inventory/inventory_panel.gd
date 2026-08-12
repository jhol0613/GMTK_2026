class_name InventoryPanel
extends Control

signal close_requested

const SLOT_COUNT: int = 4

@onready var _slot_icons: Array[TextureRect] = [
	%Slot1Icon, %Slot2Icon, %Slot3Icon, %Slot4Icon,
]
@onready var _slot_names: Array[ResshanLabel] = [
	%Slot1Name, %Slot2Name, %Slot3Name, %Slot4Name,
]

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
		var icon := _slot_icons[i]
		var name_label := _slot_names[i]
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
	elif event is InputEventMouseMotion and _drag_item != null:
		_drag_ghost.global_position = event.position - _drag_ghost.size * 0.5
		_update_hovered_bin(event.position)


func _start_drag(pos: Vector2) -> void:
	for i in _items.size():
		if not _slot_icons[i].get_global_rect().has_point(pos):
			continue
		_drag_item = _items[i]
		_drag_ghost = TextureRect.new()
		_drag_ghost.texture = _drag_item.item_icon
		_drag_ghost.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_drag_ghost.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_drag_ghost.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_drag_ghost.size = _slot_icons[i].size
		_drag_ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_drag_ghost.z_index = 100
		add_child(_drag_ghost)
		_drag_ghost.global_position = pos - _drag_ghost.size * 0.5
		_slot_icons[i].visible = false
		_slot_names[i].visible = false
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
	if _hovered_bin != null:
		_hovered_bin.recycle(_drag_item)
	_hovered_bin = null
	_drag_item = null
	_drag_ghost.queue_free()
	_drag_ghost = null
	refresh()


func _on_close_button_pressed() -> void:
	close_requested.emit()

extends Node

signal item_added(item: ItemData)
signal item_removed(item: ItemData)
signal inventory_changed

var items: Array[ItemData] = []

func add_item(item: ItemData) -> void:
	items.append(item)
	item_added.emit(item)
	inventory_changed.emit()

func remove_item(item: ItemData) -> void:
	items.erase(item)
	item_removed.emit(item)
	inventory_changed.emit()

func has_item(id: StringName) -> bool:
	return get_item(id) != null

func get_item(id: StringName) -> ItemData:
	for item in items:
		if item.id == id:
			return item
	return null

func get_ticket() -> TicketData:
	for item in items:
		if item is TicketData:
			return item as TicketData
	return null

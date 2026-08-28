extends Node

signal item_added(item: ItemData)
signal item_removed(item: ItemData)
signal inventory_changed

## Non-ticket capacity. Must match InventoryPanel.SLOT_COUNT.
const MAX_ITEMS: int = 4

var items: Array[ItemData] = []

## False when the bag was full and the item was not taken.
func add_item(item: ItemData) -> bool:
	if item is TicketData:
		_replace_ticket(item as TicketData)
		return true
	if owns_item(item):
		item_added.emit(item)
		return true
	if is_full():
		SignalBus.inventory_full.emit()
		return false
	items.append(item)
	item_added.emit(item)
	inventory_changed.emit()
	return true


func item_count() -> int:
	var count := 0
	for item in items:
		if not item is TicketData:
			count += 1
	return count


func is_full() -> bool:
	return item_count() >= MAX_ITEMS


func _replace_ticket(ticket: TicketData) -> void:
	var existing := get_ticket()
	if existing != null:
		items.erase(existing)
		item_removed.emit(existing)
	items.append(ticket)
	item_added.emit(ticket)
	inventory_changed.emit()

func remove_item(item: ItemData) -> void:
	items.erase(item)
	item_removed.emit(item)
	inventory_changed.emit()

func has_item(id: StringName) -> bool:
	return get_item(id) != null

## True if a non-ticket with the same identity is already owned.
func owns_item(item: ItemData) -> bool:
	if item == null or item is TicketData:
		return false
	if item.id != &"":
		return has_item(item.id)
	for existing in items:
		if existing is TicketData:
			continue
		if existing.item_name == item.item_name and existing.item_icon == item.item_icon:
			return true
	return false

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

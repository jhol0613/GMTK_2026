class_name InventoryPanel
extends Control

const SLOT_COUNT: int = 4

@onready var _slot_icons: Array[TextureRect] = [
	%Slot1Icon, %Slot2Icon, %Slot3Icon, %Slot4Icon,
]


func _ready() -> void:
	refresh()


func refresh() -> void:
	var items: Array[ItemData] = []
	for item in Inventory.items:
		if item is TicketData:
			continue
		items.append(item)

	for i in SLOT_COUNT:
		var icon := _slot_icons[i]
		if i < items.size():
			icon.texture = items[i].item_icon
			icon.visible = icon.texture != null
		else:
			icon.texture = null
			icon.visible = false

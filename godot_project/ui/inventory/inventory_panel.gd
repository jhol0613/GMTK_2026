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
		var name_label := _slot_names[i]
		if i < items.size():
			icon.texture = items[i].item_icon
			icon.visible = icon.texture != null
			name_label.text = items[i].item_name
			name_label.visible = not items[i].item_name.is_empty()
		else:
			icon.texture = null
			icon.visible = false
			name_label.text = ""
			name_label.visible = false


func _on_close_button_pressed() -> void:
	close_requested.emit()

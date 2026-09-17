class_name InventorySlot
extends VBoxContainer

@export var slut_icon : TextureRect
@export var slut_name : ResshanLabel

@onready var stack_count: Label = $SlotBg/StackCount


func show_stack(item: ItemData) -> void:
	stack_count.visible = item != null and item.id == Inventory.COFFEE_CUP_ID
	if stack_count.visible:
		stack_count.text = "%d/%d" % [item.quantity, Inventory.COFFEE_CUP_LIMIT]


#func _on_mouse_entered() -> void:
	#slut_name.visible = slut_name != null


#func _on_mouse_exited() -> void:
#	if not get_global_rect().has_point(get_global_mouse_position()):
#		slut_name.visible = false

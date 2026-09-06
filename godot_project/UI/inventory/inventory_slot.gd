class_name InventorySlot
extends VBoxContainer

@export var slut_icon : TextureRect
@export var slut_name : ResshanLabel


#func _on_mouse_entered() -> void:
	#slut_name.visible = slut_name != null


#func _on_mouse_exited() -> void:
#	if not get_global_rect().has_point(get_global_mouse_position()):
#		slut_name.visible = false

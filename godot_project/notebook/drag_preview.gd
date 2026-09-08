extends Control
class_name DragPreview


func _ready() -> void:
	# Connect deferred so the call to the visibility change happens
	# at the end of the frame when all notifications have been processed
	visibility_changed.connect(_block_change_visibility, Object.CONNECT_DEFERRED)


func _block_change_visibility() -> void:
	_force_visible(self)


# Force visible by toggling it directly in the RenderingServer
# for itself and its children
func _force_visible(node:CanvasItem) -> void:
	RenderingServer.canvas_item_set_visible(node.get_canvas_item(), true)
	for child in node.get_children():
		_force_visible(child)

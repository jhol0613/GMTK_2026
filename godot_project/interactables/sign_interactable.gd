class_name SignInteractable
extends Interactable

@export var title: String = "Sign"
@export var panel_path: NodePath
@export var minutes_cost: int = 1


func interact() -> void:
	if panel_path.is_empty():
		return
	var panel := get_node_or_null(panel_path) as SignPanel
	if panel == null:
		return
	panel.show_sign(title, minutes_cost)

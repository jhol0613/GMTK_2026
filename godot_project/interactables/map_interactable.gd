class_name MapInteractable
extends Interactable

@export var title: String = "Map"
@export var map_texture: Texture2D
@export var panel_path: NodePath


func interact() -> void:
	if panel_path.is_empty():
		return
	var panel := get_node_or_null(panel_path) as MapPanel
	if panel == null:
		return
	panel.show_map(title, map_texture, minutes_cost)

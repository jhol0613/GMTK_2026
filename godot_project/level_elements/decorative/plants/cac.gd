class_name Cac
extends DialoguePanel


func _on_interact_while_open() -> void:
	if _index == 0:
		var camera = get_tree().get_first_node_in_group("cameras") as ShakeCamera
		if camera:
			camera.apply_shake()
			
	super._on_interact_while_open()

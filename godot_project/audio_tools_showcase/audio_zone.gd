extends Area3D
class_name AudioZone

## Base class for audio zones. Fires callbacks when a "listener" (the player)
## enters or leaves the area. Put the player in the group named by
## `listener_group` so that props and walls do not trigger zones.
##
## Subclasses override `_on_listener_entered` / `_on_listener_exited`.

@export var listener_group: StringName = &"listener"

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group(listener_group):
		_on_listener_entered(body)

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group(listener_group):
		_on_listener_exited(body)

# --- Override in subclasses ---
func _on_listener_entered(_body: Node3D) -> void:
	pass

func _on_listener_exited(_body: Node3D) -> void:
	pass

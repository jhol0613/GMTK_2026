extends Technician
class_name Station2Technician

#var _player: PlayerCharacter

func _ready():
	_state = State.ACTING
	_interactable.interacted.connect(_on_first_interaction)
	#_player = get_tree().get_first_node_in_group("player") as PlayerCharacter
	#destination = 

#func _physics_process(_delta: float) -> void:
	#
	#pass
	#if not _player or not _player.trail_marker:
		#return
	#global_position = _player.trail_marker.global_position

func _on_first_interaction():
	_state = State.FOLLOWING
	pass

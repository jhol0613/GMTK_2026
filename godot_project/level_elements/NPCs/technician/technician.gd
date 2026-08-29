extends Npc
class_name Technician

func _ready():
	_state = State.ACTING
	_interactable.interacted.connect(_on_first_dialogue)

func _on_first_dialogue():
	pass

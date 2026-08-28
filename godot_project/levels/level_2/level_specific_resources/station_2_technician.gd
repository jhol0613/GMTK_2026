extends Npc

func _ready():
	_state = State.ACTING
	_interactable.interacted.connect(_on_first_interaction)

func _on_first_interaction():
	pass

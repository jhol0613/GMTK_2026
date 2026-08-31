extends Npc
class_name Technician

func _ready():
	super._ready()
	_state = State.ACTING

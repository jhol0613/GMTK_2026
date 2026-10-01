extends Npc


func _ready():
	_state = State.ACTING

func _start_patrol() -> void:
	_play(&"idle")

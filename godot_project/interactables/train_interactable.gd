class_name TrainInteractable
extends Interactable

@export var id: StringName = "berlin_s5"

@onready var train: Train = get_parent() as Train


func interact() -> void:
	if train == null:
		return
	train.try_board(self)


## Checks if the player can board the train
func can_board(ticket: TicketData) -> bool:
	var time_node: Control = get_tree().get_first_node_in_group("time")
	if time_node == null:
		return false

	# Check if the time is after the ticket's departure time
	if time_node.rhour > ticket.departure_hour:
		return false
	if time_node.rhour == ticket.departure_hour and time_node.rminute > ticket.departure_minute:
		return false

	return true

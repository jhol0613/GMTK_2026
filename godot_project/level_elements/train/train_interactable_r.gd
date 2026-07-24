class_name TrainInteractableR
extends Interactable

@export var id: StringName = "berlin_s5"

@onready var train: Train = get_parent() as Train


func interact() -> void:
	if train == null:
		return
	train.try_board(self)


## Evaluates whether the player can board the train
func evaluate_board(ticket: TicketData) -> Enums.BoardResult:
	if ticket == null:
		return Enums.BoardResult.REJECTED
	if not _is_on_time(ticket):
		return Enums.BoardResult.REJECTED
	if not _is_correct_train(ticket):
		return Enums.BoardResult.WRONG_TRAIN
	return Enums.BoardResult.SUCCESS


## Checks if the ticket is on time
func _is_on_time(ticket: TicketData) -> bool:
	var time_node: Control = get_tree().get_first_node_in_group("time")
	if time_node == null:
		return false
	if time_node.rhour > ticket.departure_hour:
		return false
	if time_node.rhour == ticket.departure_hour and time_node.rminute > ticket.departure_minute:
		return false
	return true


## Checks if the ticket is for the correct train
func _is_correct_train(ticket: TicketData) -> bool:
	return ticket.train_line == String(id)

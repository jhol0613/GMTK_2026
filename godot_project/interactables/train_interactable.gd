class_name TrainInteractable
extends Interactable

@export var l_or_r: String

@onready var train: Train = get_parent() as Train


func interact() -> void:
	if train == null:
		return
	train.try_board(self, l_or_r)


## Evaluates whether the player can board the train
func evaluate_board(ticket: TicketData) -> Enums.BoardResult:
	if ticket == null:
		return Enums.BoardResult.REJECTED
	if not _is_correct_train(ticket):
		return Enums.BoardResult.WRONG_TRAIN
	if not _is_on_time(ticket):
		return Enums.BoardResult.TOO_LATE
	return Enums.BoardResult.SUCCESS


func _is_on_time(ticket: TicketData) -> bool:
	return TimeManager.has_at_least(ticket.departure_hours, ticket.departure_minutes, ticket.departure_seconds)


## Checks if the ticket is for the correct train
func _is_correct_train(ticket: TicketData) -> bool:
	return train != null and ticket.id == train.ticket_id

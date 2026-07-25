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
	# No ticket, or ticket is for a different train.
	if ticket == null or not _is_correct_train(ticket):
		return Enums.BoardResult.REJECTED
	# Ticket matches this train, but is on the wrong line for the level.
	if not _is_correct_line(ticket):
		return Enums.BoardResult.WRONG_TRAIN
	if not _is_on_time(ticket):
		return Enums.BoardResult.TOO_LATE
	return Enums.BoardResult.SUCCESS


func _is_on_time(ticket: TicketData) -> bool:
	return TimeManager.has_at_least(ticket.departure_hours, ticket.departure_minutes, ticket.departure_seconds)


## Checks if the ticket is for the correct train
func _is_correct_train(ticket: TicketData) -> bool:
	return train != null and ticket.id == train.ticket_id


## Checks if the ticket is on this level's correct line
func _is_correct_line(ticket: TicketData) -> bool:
	var level := _get_level()
	if level == null or level.correct_line.is_empty():
		return true
	return ticket.train_line == level.correct_line


func _get_level() -> LevelTemplate:
	var node: Node = self
	while node != null:
		if node is LevelTemplate:
			return node as LevelTemplate
		node = node.get_parent()
	return null

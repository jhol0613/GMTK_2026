class_name TrainInteractable
extends Interactable

@export var id: StringName = "ber"
@export var time_path: NodePath


func interact() -> void:
	if not can_board():
		print("Cannot board train to ", id)
		return
	SignalBus.interaction_started.emit(minutes_cost)
	# TODO: Transition to the next scene
	print("Boarding train to ", id)


## Checks if the player can board the train
func can_board() -> bool:
	var ticket: TicketData = Inventory.get_ticket()
	if ticket == null:
		return false

	if ticket.id != id:
		return false

	var time_node: Control = get_node_or_null(time_path)
	if time_node == null:
		return false

	# Check if the time is after the ticket's departure time
	if time_node.rhour > ticket.departure_hour:
		return false
	if time_node.rhour == ticket.departure_hour and time_node.rminute > ticket.departure_minute:
		return false

	return true

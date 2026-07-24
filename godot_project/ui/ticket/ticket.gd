class_name Ticket
extends Control

@export var ticket_data: TicketData

@onready var _line_label: ResshanLabel = %LineValue
@onready var _departure_label: ResshanLabel = %DepartureValue
@onready var _destination_label: ResshanLabel = %DestinationValue


func _ready() -> void:
	if ticket_data != null:
		set_ticket(ticket_data)


func set_ticket(data: TicketData) -> void:
	ticket_data = data
	_line_label.text = data.train_line
	_departure_label.text = "<<%s>> : <<%s>>" % [data.departure_hour, data.departure_minute]
	_destination_label.text = data.destination

class_name Ticket
extends Node2D

signal ticket_expired
signal close_requested

@export var ticket_data: TicketData

@onready var _line_label: ResshanLabel = %LineValue
@onready var _departure_label: ResshanLabel = %DepartureValue
@onready var _direction_label: ResshanLabel = %DestinationValue


func _ready() -> void:
	TimeManager.time_changed.connect(check_ticket)
	if ticket_data != null:
		set_ticket(ticket_data)


func set_ticket(data: TicketData) -> void:
	ticket_data = data
	_line_label.text = data.train_line
	_departure_label.text = "<<%s>> : <<%s>> : <<%s>>" % [data.departure_hours, data.departure_minutes, data.departure_seconds]
	_direction_label.text = data.direction

func check_ticket(h, m, s) -> void:
	if not ticket_data:
		return
	if ticket_data._is_expired(h, m, s):
		ticket_expired.emit()


func _on_close_button_pressed() -> void:
	close_requested.emit()

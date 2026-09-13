class_name Ticket
extends Node2D

#signal ticket_expired
signal close_requested

@export var ticket_data: TicketData
@export var num_followon_times_to_display := 4

@onready var _line_label: ResshanLabel = %LineValue
@onready var _departure_label: ResshanLabel = %DepartureValue
@onready var _next_departure_label: ResshanLabel = %NextDepartureValue
@onready var _direction_label: ResshanLabel = %DirectionValue


func _ready() -> void:
	#TimeManager.time_changed.connect(check_ticket)
	if ticket_data != null:
		set_ticket(ticket_data)


func set_ticket(data: TicketData) -> void:
	ticket_data = data
	
	_line_label.text = Enums.train_color_to_resshan(data.train_line)
	_direction_label.text = Enums.train_direction_to_resshan(data.direction)
	
	var departures = ticket_data.departures
	_departure_label.text = ""
	_next_departure_label.text = ""
	
	if departures.size() <= 0:
		_departure_label.text = "<<train>> <<closed>>"
		return
	
	var time = TimeManager.seconds_to_hms(departures[0].departure_time_seconds)
	_departure_label.text += "<<%s>> : <<%s>> : <<%s>>" % [time.x, time.y, time.z]
	
	for i in range(1, departures.size()):
		if i >= num_followon_times_to_display: 
			break
		time = TimeManager.seconds_to_hms(departures[i].departure_time_seconds)
		_next_departure_label.text += "<<%s>> : <<%s>> : <<%s>>     " % [time.x, time.y, time.z]
		i += 1

func _on_close_button_pressed() -> void:
	close_requested.emit()

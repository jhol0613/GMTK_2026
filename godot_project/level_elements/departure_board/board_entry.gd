class_name BoardEntry
extends HBoxContainer

var time_seconds

@export var unhighlighted_color := Color.WHITE
@export var highlight_color : Color

@onready var highlighted = false:
	set(new_highlighted):
		highlighted = new_highlighted
		var new_color = highlight_color if highlighted else unhighlighted_color
		$Time.modulate = new_color
		$Station.modulate = new_color
		$Platform.modulate = new_color
	

##adding null departures is allowed to make an empty spot on the board
func set_data(departure: DepartureData) -> void:
	if departure == null:
		$Time.text = " "
		$Station.text = " "
		$Platform.text = " "
		return
	time_seconds = departure.departure_time_seconds
	var time_hms = TimeManager.seconds_to_hms(time_seconds)
	$Time.text = "<<%s>> : <<%s>> : <<%s>>" % [time_hms.x, time_hms.y, time_hms.z]
	$Station.text = "<<to>> %s" % [departure.destination]
	$Platform.text = "<<platform>> <<%s>>" % [departure.platform]

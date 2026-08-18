class_name BoardEntry
extends HBoxContainer

##adding null departures is allowed to make an empty spot on the board
func set_data(departure: DepartureData) -> void:
	if departure == null:
		$Time.text = " "
		$Station.text = " "
		$Platform.text = " "
		return
	var time = TimeManager.seconds_to_hms(departure.departure_time_seconds)
	$Time.text = "<<%s>> : <<%s>> : <<%s>>" % [time.x, time.y, time.z]
	$Station.text = departure.destination
	$Platform.text = "<<platform>> <<%s>>" % [departure.platform]

class_name BoardEntry
extends HBoxContainer

func set_data(time: Vector3i, destination: String, platform: int) -> void:
	$Time.text = "<<%s>> : <<%s>> : <<%s>>" % [time.x, time.y, time.z]
	$Station.text = destination
	$Platform.text = "<<platform>> <<%s>>" % [platform]

@tool
class_name TrainTimer
extends ResshanLabel

var _destination:String
var _hours:String
var _minutes:String
var _color:String


## Write strings in <<***>> format
func set_time(hours:String, minutes:String) -> void:
	text = "<<Train>> %s %s %s <<to>> %s" %[_color ,hours , minutes, _destination]


## Write strings in <<***>> format
func set_destination(destination:String) -> void:
	text = "<<Train>> %s %s %s <<to>> %s" %[_color ,_hours , _minutes, destination]


func set_train_color(color: Enums.TrainColor) -> void:
	var color_string:String = ''
	
	match color:
		Enums.TrainColor.BLUE:
			color_string = '<<blue>>'
		Enums.TrainColor.BROWN:
			color_string = '<<brown>>'
		Enums.TrainColor.GRAY:
			color_string = '<<gray>>'
		Enums.TrainColor.GREEN:
			color_string = '<<green>>'
		Enums.TrainColor.MAROON:
			color_string = '<<maroon>>'
		Enums.TrainColor.PINK:
			color_string = '<<pink>>'
		Enums.TrainColor.PURPLE:
			color_string = '<<purple>>'
		Enums.TrainColor.RED:
			color_string = '<<red>>'
		Enums.TrainColor.TEAL:
			color_string = '<<teal>>'
		Enums.TrainColor.YELLOW:
			color_string = '<<yellow>>'
	
	assert(color_string.is_empty(), "Unhandeled %s train color" %[color])
	
	text = "<<Train>> %s %s %s <<to>> %s" %[color_string ,_hours , _minutes, _destination]

extends Node

enum TransitionStyle {
	NONE,
	FADEINOUT,
}

enum Scenes {
	PAUSE,
	UI_OVERLAY,
	LEVEL_0,
	LEVEL_1,
	LEVEL_2,
	TITLE,
	GOOD_ENDING,
	BAD_ENDING,
	OPTIONS,
	MAIN
}

# unfortunately alphabetical order here matters. Sorry
enum TrainColor {
	BLUE = 0,
	BROWN = 1,
	GRAY = 2,
	GREEN = 3,
	MAROON = 4,
	PINK = 5,
	PURPLE = 6,
	RED = 7,
	TEAL = 8,
	YELLOW = 9,
}

func train_color_to_resshan(color: TrainColor) -> String:
	match color:
		TrainColor.BLUE:
			return "<<blue>>"
		TrainColor.BROWN:
			return "<<brown>>"
		TrainColor.GRAY:
			return "<<gray>>"
		TrainColor.GREEN:
			return "<<green>>"
		TrainColor.MAROON:
			return "<<maroon>>"
		TrainColor.PINK:
			return "<<pink>>"
		TrainColor.PURPLE:
			return "<<purple>>"
		TrainColor.RED:
			return "<<red>>"
		TrainColor.TEAL:
			return "<<teal>>"
		TrainColor.YELLOW:
			return "<<yellow>>"
		_:
			return ""

enum TrainDirection {
	NORTH,
	SOUTH,
	EAST,
	WEST
}

func train_direction_to_resshan(direction: TrainDirection) -> String:
	match direction:
		TrainDirection.NORTH:
			return "<<north>>"
		TrainDirection.SOUTH:
			return "<<south>>"
		TrainDirection.EAST:
			return "<<east>>"
		TrainDirection.WEST:
			return "<<west>>"
		_:
			return ""

enum BoardResult {
	REJECTED, ## No ticket, or ticket does not match this train
	TOO_LATE, ## Matching ticket, but the departure deadline has passed
	WRONG_TRAIN, ## Ticket matches this train, but line is wrong for the level
	SUCCESS, ## Correct train, correct line, and still on time
}

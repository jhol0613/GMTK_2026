extends Node

enum TransitionStyle {
	NONE,
	FADEINOUT
}

enum Scenes {
	PAUSE,
	UI_OVERLAY,
	LEVEL_0,
	LEVEL_1,
	LEVEL_2,
	TITLE
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
	YELLOW = 9
}

enum BoardResult {
	REJECTED,	## No ticket, or not enough time is left on the countdown to board
	WRONG_TRAIN,	## Valid ticket, but the train is the wrong color
	SUCCESS,	## Valid ticket, time and train is the correct color
}

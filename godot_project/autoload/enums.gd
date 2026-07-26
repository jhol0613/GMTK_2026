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
	ENDING
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

enum BoardResult {
	REJECTED, ## No ticket, or ticket does not match this train
	TOO_LATE, ## Matching ticket, but the departure deadline has passed
	WRONG_TRAIN, ## Ticket matches this train, but line is wrong for the level
	SUCCESS, ## Correct train, correct line, and still on time
}

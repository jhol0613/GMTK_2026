class_name TicketData
extends ItemData

@export var destination: String = ""
@export var train_line: String = ""
## Remaining time left on the countdown clock when this train departs.
## Boarding is valid as long as the clock still shows at least this much time.
@export var departure_hour: int = 0
@export var departure_minute: int = 0

class_name TicketData
extends ItemData

@export var destination: String = ""
@export var train_line: String = ""

## How far ahead the train departs from the current time.
@export var departure_hours_offset: int = 1
@export var departure_minutes_offset: int = 0
@export var departure_seconds_offset: int = 0

## Resolved at purchase from current time + offset.
var departure_hours: int = 0
var departure_minutes: int = 0
var departure_seconds: int = 0


func resolve_departure() -> void:
	var t : Vector3i = TimeManager.remaining_after_offset(
		departure_hours_offset, departure_minutes_offset, departure_seconds_offset
		)
	departure_hours = t.x
	departure_minutes = t.y
	departure_seconds = t.z


func _is_expired(h: int, m: int, s: int) -> bool:
	return h <= departure_hours and m <= departure_minutes and s <= departure_seconds

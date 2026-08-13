extends StaticBody2D

@export var rest_units_per_second := 10.0

@onready var _panel: DialoguePanel = $DialoguePanel

var _seated := false
var _accumulator := 0.0


func _ready() -> void:
	_panel.option_confirmed.connect(_on_option_confirmed)


func _on_option_confirmed(outcome_id: StringName) -> void:
	_panel.hide_popup.call_deferred()
	if outcome_id != &"rest":
		return
	_seated = true
	_accumulator = 0.0
	_set_player_movement(false)


func _process(delta: float) -> void:
	if not _seated:
		return
	_accumulator += delta * rest_units_per_second
	var units := int(_accumulator)
	if units > 0:
		_accumulator -= units
		TimeManager.advance(units, false)


func _input(event: InputEvent) -> void:
	if not _seated or _panel.is_open() or not event.is_pressed():
		return
	_seated = false
	_set_player_movement(true)
	get_viewport().set_input_as_handled()


func _set_player_movement(enabled: bool) -> void:
	for player in get_tree().get_nodes_in_group("player"):
		player.movement_disabled = not enabled

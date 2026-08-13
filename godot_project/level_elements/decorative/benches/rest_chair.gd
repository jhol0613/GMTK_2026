extends StaticBody2D

@export var rest_units_per_second := 10.0

@onready var _panel: DialoguePanel = $DialoguePanel
@onready var _chair_sprite: CanvasItem = get_node_or_null("Sprite")
@onready var _seated_sprite: CanvasItem = get_node_or_null("SeatedSprite")

var _seated := false
var _accumulator := 0.0
var _hidden_players: Array[CanvasItem] = []


func _ready() -> void:
	_panel.option_confirmed.connect(_on_option_confirmed)
	tree_exiting.connect(_on_tree_exiting)


func _on_option_confirmed(outcome_id: StringName) -> void:
	_panel.hide_popup.call_deferred()
	if outcome_id != &"rest":
		return
	_seated = true
	_accumulator = 0.0
	_set_player_movement(false)
	_set_seated_pose(true)
	SignalBus.rest_started.emit()


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
	_end_rest()
	get_viewport().set_input_as_handled()


func _end_rest() -> void:
	if not _seated:
		return
	_seated = false
	_set_seated_pose(false)
	_set_player_movement(true)
	SignalBus.rest_ended.emit()


func _on_tree_exiting() -> void:
	if _seated:
		_set_seated_pose(false)
		_set_player_movement(true)
		SignalBus.rest_ended.emit()


func _set_player_movement(enabled: bool) -> void:
	for player in get_tree().get_nodes_in_group("player"):
		player.movement_disabled = not enabled


func _set_seated_pose(active: bool) -> void:
	if _seated_sprite == null:
		return
	_seated_sprite.visible = active
	if _chair_sprite != null:
		_chair_sprite.visible = not active
	if active:
		_hidden_players.clear()
		for player in get_tree().get_nodes_in_group("player"):
			if player is CanvasItem and player.visible:
				_hidden_players.append(player)
				player.visible = false
	else:
		for player in _hidden_players:
			if is_instance_valid(player):
				player.visible = true
		_hidden_players.clear()

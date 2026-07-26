class_name DialoguePanel
extends InteractionPanelBase

## Emitted when an option is confirmed, can be used to trigger actions based on the outcome
signal option_confirmed(outcome_id: StringName)

@export var player_name: String = "You"
@export var player_icon: Texture2D

@onready var _speaker: ResshanLabel = $Root/Popup/MarginContainer/HBoxContainer/VBox/Speaker
@onready var _body: ResshanLabel = $Root/Popup/MarginContainer/HBoxContainer/VBox/Body
@onready var _options: VBoxContainer = $Root/Popup/MarginContainer/HBoxContainer/VBox/Options
@onready var _speaker_icon: TextureRect = %SpeakerIcon
@onready var _lines_sfx: AudioStreamPlayer = %LinesSFX

var _lines: Array[DialogueLine] = []
var _index: int = 0
var _choices: Array[DialogueChoice] = []

var _showing_options: bool
var _selected_option: int
var _reward: ItemData
var _awaiting_close: bool
var _awaiting_reward: bool

signal dialogue_complete


## Initialize the dialogue panel
func show_dialogue(
	speaker: String,
	lines: Array[DialogueLine],
	choices: Array[DialogueChoice],
	minutes: int = 1,
) -> void:
	_showing_options = false
	_selected_option = 0
	_options.visible = false
	_speaker.text = speaker
	_lines = lines
	_index = 0
	_choices = choices
	_awaiting_close = false
	_awaiting_reward = false
	_reward = null

	_rebuild_option_labels()
	_update_line()
	_open(minutes)


func _rebuild_option_labels() -> void:
	for child in _options.get_children():
		child.free()
	for choice in _choices:
		var label := ResshanLabel.new()
		label.text = choice.player_text
		label.font_size = 42
		_options.add_child(label)


func _update_line() -> void:
	_lines_sfx.stop()

	if _lines.is_empty():
		_speaker.text = ""
		_body.text = ""
		_speaker_icon.texture = null
		return

	var line: DialogueLine = _lines[_index]
	_speaker.text = line.speaker
	_body.text = line.text
	_speaker_icon.texture = line.speaker_icon

	if line.sfx != null:
		_lines_sfx.stream = line.sfx
		_lines_sfx.play()


func _on_interact_while_open() -> void:
	if _awaiting_close:
		if _awaiting_reward:
			_give_reward()
		_awaiting_reward = false
		_awaiting_close = false
		hide_popup()
		dialogue_complete.emit()
		return

	if _showing_options:
		_confirm_option()
		return

	if _index < _lines.size() - 1:
		_index += 1
		_update_line()
	elif _choices.is_empty():
		_awaiting_close = true
	else:
		_enter_options_mode()


func _enter_options_mode() -> void:
	_showing_options = true
	_body.text = ""
	_speaker.text = player_name
	_speaker_icon.texture = player_icon
	_options.visible = true
	_refresh_options_visual()


func _unhandled_input(event: InputEvent) -> void:
	if not _is_open:
		return
	if _showing_options and not _choices.is_empty():
		if event.is_action_pressed("move_up"):
			_selected_option = (_selected_option - 1 + _choices.size()) % _choices.size()
			_refresh_options_visual()
			get_viewport().set_input_as_handled()
			return
		if event.is_action_pressed("move_down"):
			_selected_option = (_selected_option + 1) % _choices.size()
			_refresh_options_visual()
			get_viewport().set_input_as_handled()
			return
	super._unhandled_input(event)


func _confirm_option() -> void:
	if _choices.is_empty():
		return
	var choice: DialogueChoice = _choices[_selected_option]

	_reward = choice.reward
	option_confirmed.emit(choice.outcome_id)
	if _reward != null:
		_give_reward()
		_awaiting_close = false
		_awaiting_reward = false
		hide_popup()
		dialogue_complete.emit()
	else:
		_awaiting_close = true
		_awaiting_reward = false


func _refresh_options_visual() -> void:
	for i in _options.get_child_count():
		var label := _options.get_child(i) as ResshanLabel
		if label == null:
			continue
		var prefix := "> " if i == _selected_option else "  "
		label.text = prefix + _choices[i].player_text
		label.modulate = Color.WHITE if i == _selected_option else Color.GRAY


func _give_reward() -> void:
	if _reward == null:
		return

	var item := _reward.duplicate() as ItemData
	if item is TicketData:
		(item as TicketData).resolve_departure()
		SignalBus.ticket_purchased.emit(item.departure_hours, item.departure_minutes)
	Inventory.add_item(item)

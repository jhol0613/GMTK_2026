class_name DialoguePanel
extends InteractionPanelBase

## Emitted when an option is confirmed, can be used to trigger actions based on the outcome
signal option_confirmed(outcome_id: StringName)

@onready var _speaker: ResshanLabel = $Root/HBoxContainer/Popup/MarginContainer/VBox/Speaker
@onready var _body: ResshanLabel = $Root/HBoxContainer/Popup/MarginContainer/VBox/Body
@onready var _options: VBoxContainer = $Root/HBoxContainer/Popup/MarginContainer/VBox/Options

var _lines: PackedStringArray = []
var _index: int = 0
var _choices: Array[DialogueChoice] = []

var _showing_options: bool
var _selected_option: int
var _reward: ItemData
var _awaiting_close: bool
var _awaiting_reward: bool


## Initialize the dialogue panel
func show_dialogue(
	speaker: String,
	lines: PackedStringArray,
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
	_update_body()
	_open(minutes)


func _rebuild_option_labels() -> void:
	for child in _options.get_children():
		child.free()
	for choice in _choices:
		var label := ResshanLabel.new()
		label.text = choice.player_text
		_options.add_child(label)


func _update_body() -> void:
	if _lines.is_empty():
		_body.text = ""
		return
	_body.text = _lines[_index]


func _on_interact_while_open() -> void:
	if _awaiting_close:
		if _awaiting_reward:
			_give_reward()
		_awaiting_reward = false
		_awaiting_close = false
		hide_popup()
		return

	if _showing_options:
		_confirm_option()
		return

	if _index < _lines.size() - 1:
		_index += 1
		_update_body()
	elif _choices.is_empty():
		_awaiting_close = true
	else:
		_enter_options_mode()


func _enter_options_mode() -> void:
	_showing_options = true
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

	_showing_options = false
	_options.visible = false
	_awaiting_close = true
	_body.text = choice.reply
	_reward = choice.reward
	_awaiting_reward = _reward != null
	option_confirmed.emit(choice.outcome_id)


func _refresh_options_visual() -> void:
	for i in _options.get_child_count():
		var label := _options.get_child(i) as ResshanLabel
		if label == null:
			continue
		label.modulate = Color.WHITE if i == _selected_option else Color.GRAY


func _give_reward() -> void:
	if _reward == null:
		return
	Inventory.add_item(_reward.duplicate() as ItemData)

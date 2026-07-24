class_name DialoguePanel
extends InteractionPanelBase

@onready var _speaker: ResshanLabel = $Root/Popup/MarginContainer/VBox/Speaker
@onready var _body: ResshanLabel = $Root/Popup/MarginContainer/VBox/Body
@onready var _options: VBoxContainer = $Root/Popup/MarginContainer/VBox/Options
@onready var _option_a: Label = _options.get_child(0)
@onready var _option_b: Label = _options.get_child(1)

var _lines: PackedStringArray = []
var _index: int = 0

var _showing_options: bool
var _selected_option: int
var _correct_option: int
var _reward: ItemData
var _awaiting_close: bool
var _awaiting_reward: bool
var _success_line: String
var _failure_line: String


## Initialize the dialogue panel
func show_dialogue(
	speaker: String,
	lines: PackedStringArray,
	option_a: String,
	option_b: String,
	correct_option: int,
	reward: ItemData,
	success_line: String,
	failure_line: String,
	minutes: int = 1,
) -> void:
	_showing_options = false
	_selected_option = 0
	_options.visible = false
	_option_a.text = option_a
	_option_b.text = option_b
	_correct_option = correct_option
	_reward = reward
	_success_line = success_line
	_failure_line = failure_line
	_speaker.text = speaker
	_lines = lines
	_index = 0
	_awaiting_close = false
	_awaiting_reward = false

	_update_body()
	_open(minutes)


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
	else:
		_enter_options_mode()


func _enter_options_mode() -> void:
	_showing_options = true
	_options.visible = true
	_refresh_options_visual()


func _unhandled_input(event: InputEvent) -> void:
	if not _is_open:
		return
	if event.is_action_pressed("move_up"):
		_selected_option = 0
		_refresh_options_visual()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("move_down"):
		_selected_option = 1
		_refresh_options_visual()
		get_viewport().set_input_as_handled()
		return
	super._unhandled_input(event)


func _confirm_option() -> void:
	_showing_options = false
	_options.visible = false
	_awaiting_close = true
	if _selected_option == _correct_option:
		_awaiting_reward = true
		_body.text = _success_line
	else:
		_awaiting_reward = false
		_body.text = _failure_line


func _refresh_options_visual() -> void:
	_option_a.modulate = Color.WHITE if _selected_option == 0 else Color.GRAY
	_option_b.modulate = Color.WHITE if _selected_option == 1 else Color.GRAY


func _give_reward() -> void:
	if _reward == null:
		return
	Inventory.add_item(_reward.duplicate() as ItemData)

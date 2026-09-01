class_name DialoguePanel
extends InteractionPanelBase

## Emitted when an option is confirmed, can be used to trigger actions based on the outcome
signal option_confirmed(outcome_id: StringName)

@export var player_name: String = "You"
@export var player_icon: Texture2D
@export var choice_nav_icons: Control
@export_range(5.0, 120.0, 1.0) var characters_per_second := 45.0

@onready var _speaker: ResshanLabel = $Root/Popup/MarginContainer/HBoxContainer/VBox/Speaker
@onready var _body: ResshanLabel = $Root/Popup/MarginContainer/HBoxContainer/VBox/Body
@onready var _options_scroll: ScrollContainer = $Root/Popup/MarginContainer/HBoxContainer/VBox/OptionsScroll
@onready var _options: VBoxContainer = $Root/Popup/MarginContainer/HBoxContainer/VBox/OptionsScroll/Options
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
var _typewriter_units: Array[String] = []
var _typewriter_index := 0
var _typewriter_accumulator := 0.0
var _typewriter_active := false

signal dialogue_complete


func _process(delta: float) -> void:
	if not _typewriter_active:
		return
	_typewriter_accumulator += delta * characters_per_second
	var count := int(_typewriter_accumulator)
	if count <= 0:
		return
	_typewriter_accumulator -= count
	_typewriter_index = mini(_typewriter_index + count, _typewriter_units.size())
	_body.text = _get_typewriter_text(_typewriter_index)
	if _typewriter_index >= _typewriter_units.size():
		_typewriter_active = false


## Initialize the dialogue panel
func show_dialogue(
	speaker: String,
	lines: Array[DialogueLine],
	choices: Array[DialogueChoice],
	minutes: int = 1,
) -> void:
	_showing_options = false
	_selected_option = 0
	_options_scroll.visible = false
	_options_scroll.scroll_vertical = 0
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
		_typewriter_active = false
		_speaker.text = ""
		_body.text = ""
		_speaker_icon.texture = null
		return
	
	_show_line(_lines[_index])


func _show_line(line: DialogueLine) -> void:
	_speaker.text = line.speaker
	_speaker_icon.texture = line.speaker_icon
	_start_typewriter(line.text)

	if line.sfx != null:
		_lines_sfx.stream = line.sfx
		_lines_sfx.play()

func _on_interact_while_open() -> void:
	if _typewriter_active:
		_finish_typewriter()
		return

	if _awaiting_close:
		if _awaiting_reward:
			_give_reward()
			_awaiting_reward = false
		_close_dialog()
		return

	if _showing_options:
		_confirm_option()
		return

	if _index < _lines.size() - 1:
		_index += 1
		_update_line()
	elif _choices.is_empty():
		_close_dialog()
	else:
		_enter_options_mode()


func _enter_options_mode() -> void:
	_typewriter_active = false
	_showing_options = true
	_body.text = ""
	_speaker.text = player_name
	_speaker_icon.texture = player_icon
	_options_scroll.visible = true
	choice_nav_icons.visible = true
	_refresh_options_visual()

func _exit_options_mode() -> void:
	_showing_options = false
	_body.text = ""
	_options_scroll.visible = false
	choice_nav_icons.visible = false
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
		_awaiting_close = true
		_awaiting_reward = true
	else:
		_awaiting_close = true
		_awaiting_reward = false
	
	_exit_options_mode()
	
	if choice.reply != null:
		_show_line(choice.reply)


func _refresh_options_visual() -> void:
	for i in _options.get_child_count():
		var label := _options.get_child(i) as ResshanLabel
		if label == null:
			continue
		var prefix : String = "> " if i == _selected_option else "  "
		label.text = prefix + _choices[i].player_text
		label.modulate = Color.WHITE if i == _selected_option else Color.GRAY
	call_deferred("_ensure_selected_option_visible")


func _ensure_selected_option_visible() -> void:
	if not _showing_options or _selected_option >= _options.get_child_count():
		return
	await get_tree().process_frame
	if not _showing_options or _selected_option >= _options.get_child_count():
		return
	_options_scroll.ensure_control_visible(_options.get_child(_selected_option))


func _give_reward() -> void:
	if _reward == null:
		return

	var item := _reward.duplicate() as ItemData
	if item is TicketData:
		(item as TicketData).resolve_departure()
		SignalBus.ticket_purchased.emit(item.departure_hours, item.departure_minutes, item.departure_seconds)
	Inventory.add_item(item)


func _close_dialog() -> void:
	_typewriter_active = false
	_awaiting_close = false
	_awaiting_reward = false
	hide_popup()
	dialogue_complete.emit()


func _start_typewriter(value: String) -> void:
	_typewriter_units = _split_typewriter_units(value)
	_typewriter_index = 0
	_typewriter_accumulator = 0.0
	_typewriter_active = not _typewriter_units.is_empty()
	_body.text = ""


func _finish_typewriter() -> void:
	_typewriter_index = _typewriter_units.size()
	_body.text = _get_typewriter_text(_typewriter_index)
	_typewriter_active = false
	_typewriter_accumulator = 0.0


func _split_typewriter_units(value: String) -> Array[String]:
	var units: Array[String] = []
	var index := 0
	while index < value.length():
		if value.substr(index, 2) == "<<":
			var closing := value.find(">>", index + 2)
			if closing != -1:
				units.append(value.substr(index, closing + 2 - index))
				index = closing + 2
				continue
		if value.substr(index, 2) == "/n":
			units.append("/n")
			index += 2
			continue
		units.append(value.substr(index, 1))
		index += 1
	return units


func _get_typewriter_text(count: int) -> String:
	var result := ""
	for index in mini(count, _typewriter_units.size()):
		result += _typewriter_units[index]
	return result


var _full_offset_left := 0.0
var _full_offset_right := 0.0
var _full_min_width := 0.0
var _full_saved := false
var _compact_tween: Tween


func set_compact(
	enabled: bool,
	edge: float,
	duration := 0.0,
	align_right := false,
) -> void:
	var popup: PanelContainer = $Root/Popup
	if not _full_saved:
		_full_saved = true
		_full_offset_left = popup.offset_left
		_full_offset_right = popup.offset_right
		_full_min_width = popup.custom_minimum_size.x

	var target_left := _full_offset_left
	var target_right := _full_offset_right
	var target_width := _full_min_width
	if enabled:
		if align_right:
			target_left = edge
			target_right = ($Root as Control).size.x
			target_width = maxf(target_right - target_left, 0.0)
		else:
			target_left = 0.0
			target_right = edge
			target_width = maxf(edge, 0.0)

	if _compact_tween != null and _compact_tween.is_valid():
		_compact_tween.kill()

	if duration <= 0.0:
		popup.offset_left = target_left
		popup.offset_right = target_right
		popup.custom_minimum_size.x = target_width
		return

	_compact_tween = create_tween().set_parallel(true)
	_compact_tween.set_ease(Tween.EASE_OUT)
	_compact_tween.set_trans(Tween.TRANS_CUBIC)
	_compact_tween.tween_property(popup, "offset_left", target_left, duration)
	_compact_tween.tween_property(popup, "offset_right", target_right, duration)
	_compact_tween.tween_property(popup, "custom_minimum_size:x", target_width, duration)

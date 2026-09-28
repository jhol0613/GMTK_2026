extends CanvasLayer
class_name InteractionPanelBase

signal opened
signal closed

@onready var _root: Control = $Root

var _is_open: bool = false
## Info-only panels (maps, signs) set this so escape or a click outside the popup
## also closes them. Dialogue leaves it off so a stray click cannot skip a reward.
var dismissible: bool = false
@export var compact_shift_x := 300.0

var _compact_tween: Tween
var _compact_home_left: float
var _compact_home_saved := false


func _ready() -> void:
	add_to_group("interaction_panel")
	_root.visible = false
	_root.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	$Root/Popup.mouse_filter = Control.MOUSE_FILTER_STOP
	var dimmer := get_node_or_null("Root/DimScreen") as Control
	if dimmer != null:
		dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
		dimmer.gui_input.connect(_on_dimmer_gui_input)


func _on_dimmer_gui_input(event: InputEvent) -> void:
	if dismissible and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_root.accept_event()
		if not event.pressed:
			hide_popup()


func hide_popup() -> void:
	if not _is_open:
		return
	_root.visible = false
	_is_open = false
	closed.emit()


func is_open() -> bool:
	return _is_open


func set_compact(enabled: bool, _edge: float, duration := 0.0, _align_right := false) -> void:
	var popup: Control = $Root/Popup
	if not _compact_home_saved:
		_compact_home_saved = true
		_compact_home_left = popup.offset_left
	var width := popup.offset_right - popup.offset_left
	var target := _compact_home_left + (compact_shift_x if enabled else 0.0)

	if _compact_tween != null and _compact_tween.is_valid():
		_compact_tween.kill()
	if duration <= 0.0:
		popup.offset_left = target
		popup.offset_right = target + width
		return
	_compact_tween = create_tween().set_parallel(true)
	_compact_tween.set_ease(Tween.EASE_OUT)
	_compact_tween.set_trans(Tween.TRANS_CUBIC)
	_compact_tween.tween_property(popup, "offset_left", target, duration)
	_compact_tween.tween_property(popup, "offset_right", target + width, duration)


func _open(minutes: int = 1) -> void:
	# If the CanvasLayer is invisible, the Root will not be visible either.
	visible = true
	_root.visible = true
	_is_open = true
	opened.emit()
	SignalBus.minutes_passed.emit(minutes)


func _unhandled_input(event: InputEvent) -> void:
	if not _is_open:
		return

	var focused := get_viewport().gui_get_focus_owner()
	if focused is LineEdit or focused is TextEdit:
		return

	if dismissible and not _notebook_has_priority():
		if event.is_action_pressed("escape"):
			hide_popup()
			get_viewport().set_input_as_handled()
			return
		if (
			event is InputEventMouseButton
			and event.pressed
			and event.button_index == MOUSE_BUTTON_LEFT
			and not _popup_rect().has_point(event.position)
		):
			hide_popup()
			get_viewport().set_input_as_handled()
			return

	if event.is_action_pressed("interact"):
		_on_interact_while_open()
		get_viewport().set_input_as_handled()


func _notebook_has_priority() -> bool:
	var ui := get_tree().get_first_node_in_group("ui_overlay")
	return ui != null and ui.has_method("notebook_is_docked") and ui.notebook_is_docked()


func _popup_rect() -> Rect2:
	return ($Root/Popup as Control).get_global_rect()


## Override in subclasses to handle interaction while the panel is open
func _on_interact_while_open() -> void:
	hide_popup()

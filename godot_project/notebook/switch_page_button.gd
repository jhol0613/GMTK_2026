extends Button
class_name SwitchPageButton

@export var page_increment = 1 #-1 for previous page
@export var hover_sound: AudioStreamPlayer
@export var button_hover_scale := Vector2(1.03, 1.03)

var _dragged_data: NotebookEntry
var _page_switch_timer: SceneTreeTimer
const hover_time_to_page_switch := 0.5

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	pass # Replace with function body.

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	_dragged_data = data
	if not _page_switch_timer or not _page_switch_timer.timeout.is_connected(_on_page_switch_timeout):
		_page_switch_timer = get_tree().create_timer(hover_time_to_page_switch)
		_page_switch_timer.timeout.connect(_on_page_switch_timeout)
	return true

func _on_page_switch_timeout():
	if _dragged_data:
		_dragged_data.move_page_requested.emit(page_increment)
		_dragged_data.request_switch_page_view.emit(page_increment)
		#_on_next_page_pressed()
		#_dragged_data.move_requested.emit(get_index(), true)
		#_dragged_data.request_switch_section_view.emit(get_index())
		#_dragged_data._get_entry_drag_data(Vector2.ZERO)

func _drop_data(at_position: Vector2, data: Variant) -> void:
	if _dragged_data is NotebookEntry:
		_dragged_data.move_page_requested.emit(page_increment)
		if _page_switch_timer and _page_switch_timer.timeout.is_connected(_on_page_switch_timeout):
			_page_switch_timer.timeout.disconnect(_on_page_switch_timeout)

func _on_mouse_entered() -> void:
	hover_sound.play()
	scale = button_hover_scale

func _on_mouse_exited() -> void:
	scale = Vector2.ONE
	if _page_switch_timer and _page_switch_timer.timeout.is_connected(_on_page_switch_timeout):
		_page_switch_timer.timeout.disconnect(_on_page_switch_timeout)

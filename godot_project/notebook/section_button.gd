extends TextureButton
class_name SectionTab

@export var color: Color
@export var hover_modulate = 0.7
@export var hover_scale := Vector2(1.05, 1.05)
@export var hover_offset := Vector2(3, -1)
@export var hover_time_to_section_switch := 0.5

@onready var label : Label = $Label
@onready var sticker : TextureRect = $Sticker
@onready var hover_sound : AudioStreamPlayer = $HoverSound

@onready var original_z_index : int = z_index

var _section_switch_timer: SceneTreeTimer
var _dragged_data: NotebookEntry

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	modulate = color

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	_dragged_data = data
	if not _section_switch_timer or not _section_switch_timer.timeout.is_connected(_on_section_switch_timeout):
		_section_switch_timer = get_tree().create_timer(hover_time_to_section_switch)
		_section_switch_timer.timeout.connect(_on_section_switch_timeout)
	return true

func _on_section_switch_timeout():
	if _dragged_data:
		_dragged_data.request_switch_section_view.emit(get_index())
		_dragged_data.move_requested.emit(get_index(), false)
		#_dragged_data._get_entry_drag_data(Vector2.ZERO)

func _drop_data(at_position: Vector2, data: Variant) -> void:
	if _dragged_data is NotebookEntry:
		_dragged_data.move_requested.emit(get_index(), true)
		if _section_switch_timer and _section_switch_timer.timeout.is_connected(_on_section_switch_timeout):
			_section_switch_timer.timeout.disconnect(_on_section_switch_timeout)

func _on_mouse_entered() -> void:
	modulate.r = color.r * hover_modulate
	modulate.g = color.g * hover_modulate
	modulate.b = color.b * hover_modulate
	scale = hover_scale
	position += hover_offset
	hover_sound.play()
	print("mouse entered")

func _on_mouse_exited() -> void:
	modulate = color
	scale = Vector2(1, 1)
	position -= hover_offset
	if _section_switch_timer and _section_switch_timer.timeout.is_connected(_on_section_switch_timeout):
		_section_switch_timer.timeout.disconnect(_on_section_switch_timeout)

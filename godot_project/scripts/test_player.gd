extends CharacterBody3D

## Minimal WASD + mouse-look controller for walking around the audio test world.
## Also switches the MusicManager state with the 1 / 2 / 3 keys.
## No InputMap setup needed — keys are read directly.

@export var move_speed: float = 5.0
@export var mouse_sensitivity: float = 0.002
@export var music_manager_path: NodePath
@export var status_label_path: NodePath

@onready var _camera: Camera3D = $Camera3D
var _music: MusicManager
var _status: Label

func _ready() -> void:
	add_to_group("listener")
	_music = get_node_or_null(music_manager_path) as MusicManager
	_status = get_node_or_null(status_label_path) as Label
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_update_status()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		_camera.rotate_x(-event.relative.y * mouse_sensitivity)
		_camera.rotation.x = clamp(_camera.rotation.x, -1.4, 1.4)
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1: _set_music(MusicManager.State.CALM)
			KEY_2: _set_music(MusicManager.State.TENSION)
			KEY_3: _set_music(MusicManager.State.COMBAT)
			KEY_ESCAPE: Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _physics_process(_delta: float) -> void:
	var input_dir := Vector3.ZERO
	if Input.is_physical_key_pressed(KEY_W): input_dir.z -= 1.0
	if Input.is_physical_key_pressed(KEY_S): input_dir.z += 1.0
	if Input.is_physical_key_pressed(KEY_A): input_dir.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D): input_dir.x += 1.0
	var direction := (transform.basis * input_dir).normalized()
	velocity.x = direction.x * move_speed
	velocity.z = direction.z * move_speed
	velocity.y = 0.0
	move_and_slide()

func _set_music(state: MusicManager.State) -> void:
	if _music != null:
		_music.set_state(state)
	_update_status()

func _update_status() -> void:
	if _status == null:
		return
	var state_name := "-"
	if _music != null:
		state_name = MusicManager.State.keys()[_music.get_state()]
	_status.text = "WASD move  |  mouse look  |  1/2/3 = music state  |  ESC = free cursor\nMusic state: %s" % state_name

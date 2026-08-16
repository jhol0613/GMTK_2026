extends Control


@export_group("Textures")
@export var shell_texture: Texture2D
@export var cell_full: Texture2D
@export var cell_empty: Texture2D
@export var cell_low: Texture2D
@export var cell_charging: Texture2D

@export_group("Layout (source pixels)")
@export var pixel_scale: int = 3:
	set(value):
		pixel_scale = maxi(1, value)
		_rebuild()
@export var columns: int = 8
@export var cell_origin := Vector2(4, 4)
@export var cell_step := Vector2(4, 7)

@export_group("Behaviour")
@export var low_threshold: int = 4
@export var charge_step_delay: float = 0.06
@export var discharge_step_delay: float = 0.06

@export_group("Audio")
@export var gain_sound: AudioStream
@export var drain_sound: AudioStream
@export_range(-80.0, 6.0, 0.5) var gain_volume_db: float = -8.0
@export_range(-80.0, 6.0, 0.5) var drain_volume_db: float = -8.0

var _shell: TextureRect
var _cells: Array[TextureRect] = []
var _gain_player: AudioStreamPlayer
var _drain_player: AudioStreamPlayer
var _displayed_tokens: int = 0
var _charge_generation: int = 0
var _motion_tween: Tween
var _base_position := Vector2.ZERO
var _base_scale := Vector2.ONE


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_base_position = position
	_base_scale = scale
	pivot_offset = size * 0.5
	_create_audio_players()
	_rebuild()
	_displayed_tokens = Wallet.tokens
	Wallet.tokens_changed.connect(_on_tokens_changed)
	_refresh(_displayed_tokens)


func _create_audio_players() -> void:
	_gain_player = AudioStreamPlayer.new()
	_gain_player.bus = &"SFX"
	add_child(_gain_player)
	_drain_player = AudioStreamPlayer.new()
	_drain_player.bus = &"SFX"
	add_child(_drain_player)


func _rebuild() -> void:
	if not is_node_ready():
		return

	if _shell != null:
		_shell.queue_free()
	for cell in _cells:
		cell.queue_free()
	_cells.clear()

	_shell = TextureRect.new()
	_shell.texture = shell_texture
	_shell.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_shell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if shell_texture != null:
		_shell.size = shell_texture.get_size() * pixel_scale
		custom_minimum_size = _shell.size
	add_child(_shell)

	var cell_size := Vector2.ZERO
	if cell_full != null:
		cell_size = cell_full.get_size() * pixel_scale

	for index in Wallet.MAX_TOKENS:
		var cell := TextureRect.new()
		cell.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell.position = (
			cell_origin + Vector2(index % columns, index / columns) * cell_step
		) * pixel_scale
		cell.size = cell_size
		add_child(cell)
		_cells.append(cell)

	_refresh(_displayed_tokens)


func _on_tokens_changed(current: int, _maximum: int) -> void:
	current = clampi(current, 0, _cells.size())
	if current == _displayed_tokens:
		_refresh(current)
		return
	_charge_generation += 1
	var generation := _charge_generation
	if current > _displayed_tokens:
		_animate_gain(current, generation)
	else:
		_animate_drain(current, generation)


func _animate_gain(target: int, generation: int) -> void:
	_play_audio(_gain_player, gain_sound, gain_volume_db)
	_play_scale_bump()
	while _displayed_tokens < target:
		var cell := _cell_for_token(_displayed_tokens)
		if cell != null:
			cell.texture = cell_charging if cell_charging != null else cell_full
		await get_tree().create_timer(charge_step_delay * 0.45).timeout
		if generation != _charge_generation:
			return
		_displayed_tokens += 1
		_refresh(_displayed_tokens)
		await get_tree().create_timer(charge_step_delay * 0.55).timeout
		if generation != _charge_generation:
			return
	_play_completion_flash()


func _animate_drain(target: int, generation: int) -> void:
	_play_audio(_drain_player, drain_sound, drain_volume_db)
	_play_scale_bump()
	while _displayed_tokens > target:
		var cell := _cell_for_token(_displayed_tokens - 1)
		if cell != null:
			cell.texture = cell_low if cell_low != null else cell_empty
		await get_tree().create_timer(discharge_step_delay * 0.45).timeout
		if generation != _charge_generation:
			return
		_displayed_tokens -= 1
		_refresh(_displayed_tokens)
		await get_tree().create_timer(discharge_step_delay * 0.55).timeout
		if generation != _charge_generation:
			return
	if _displayed_tokens <= low_threshold:
		_play_low_pulse()


func _refresh(amount: int) -> void:
	if _cells.is_empty():
		return
	var lit_texture := cell_low if amount <= low_threshold else cell_full
	for cell in _cells:
		cell.texture = cell_empty
	for token_index in mini(amount, _cells.size()):
		var cell := _cell_for_token(token_index)
		if cell != null:
			cell.texture = lit_texture


func _cell_for_token(token_index: int) -> TextureRect:
	if columns <= 0:
		return null
	var row_count := ceili(float(_cells.size()) / float(columns))
	var column := floori(float(token_index) / float(row_count))
	var row_from_bottom := token_index % row_count
	var row := row_count - 1 - row_from_bottom
	var cell_index: int = row * columns + column
	if cell_index < 0 or cell_index >= _cells.size():
		return null
	return _cells[cell_index]


func _play_audio(player: AudioStreamPlayer, stream: AudioStream, volume_db: float) -> void:
	if stream == null:
		return
	player.stream = stream
	player.volume_db = volume_db
	player.play()


func _play_scale_bump() -> void:
	_kill_motion_tween()
	position = _base_position
	scale = _base_scale
	_motion_tween = create_tween()
	_motion_tween.tween_property(self, "scale", _base_scale * 1.18, 0.1)
	_motion_tween.tween_property(self, "scale", _base_scale, 0.18)


func _play_shake() -> void:
	_kill_motion_tween()
	position = _base_position
	scale = _base_scale
	_motion_tween = create_tween()
	_motion_tween.tween_property(self, "position", _base_position + Vector2(pixel_scale, 0.0), 0.035)
	_motion_tween.tween_property(self, "position", _base_position - Vector2(pixel_scale, 0.0), 0.035)
	_motion_tween.tween_property(self, "position", _base_position, 0.05)


func _play_completion_flash() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(0.75, 1.0, 1.0, 1.0), 0.06)
	tween.tween_property(self, "modulate", Color.WHITE, 0.12)


func _play_low_pulse() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(1.0, 0.72, 0.45, 1.0), 0.08)
	tween.tween_property(self, "modulate", Color.WHITE, 0.14)


func _kill_motion_tween() -> void:
	if _motion_tween != null and _motion_tween.is_valid():
		_motion_tween.kill()

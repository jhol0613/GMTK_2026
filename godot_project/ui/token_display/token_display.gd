extends Control

## Battery-style charge meter. Cells are laid out inside the shell's carved
## slots, using source-pixel coordinates scaled by `pixel_scale`.
## Cells fill in reading order, so spending drains from the bottom-right back.

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
## Top-left corner of the first slot inside the shell.
@export var cell_origin := Vector2(4, 4)
## Distance between slot corners (cell size + gap).
@export var cell_step := Vector2(4, 7)

@export_group("Behaviour")
## At or below this many tokens every lit cell switches to the low texture.
@export var low_threshold: int = 4
@export var charge_step_delay: float = 0.05

var _shell: TextureRect
var _cells: Array[TextureRect] = []
var _charge_generation: int = 0


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_rebuild()
	Wallet.tokens_changed.connect(_on_tokens_changed)
	Wallet.refilled.connect(_on_refilled)
	_refresh()


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

	_refresh()


func _on_tokens_changed(_current: int, _maximum: int) -> void:
	_charge_generation += 1
	_refresh()


func _refresh() -> void:
	if _cells.is_empty():
		return
	var lit_texture := cell_low if Wallet.tokens <= low_threshold else cell_full
	for index in _cells.size():
		_cells[index].texture = lit_texture if index < Wallet.tokens else cell_empty


## Light the cells up one by one when the wallet is topped up at an ATM.
func _on_refilled() -> void:
	if cell_charging == null or _cells.is_empty():
		return
	_charge_generation += 1
	var generation := _charge_generation
	for index in _cells.size():
		_cells[index].texture = cell_charging
		await get_tree().create_timer(charge_step_delay).timeout
		if generation != _charge_generation:
			return
	_refresh()

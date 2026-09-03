class_name NotebookPage
extends Control

signal limit_reached
signal entry_removed
signal entry_updated(encoded:String, new_text:String)
signal entry_order_changed

const LIMIT: = 5


var entries_count: int = 0
var _drop_indicator: Line2D


func _ready() -> void:
	_drop_indicator = Line2D.new()
	_drop_indicator.width = 4.0
	_drop_indicator.default_color = Color("0a9e80")
	_drop_indicator.antialiased = false
	_drop_indicator.z_index = 1000
	_drop_indicator.visible = false
	add_child(_drop_indicator)


func _new_entry(encoded:String, initial_text = "") -> NotebookEntry:
	var entry:NotebookEntry = preload('uid://s4gdpvpyayn0').instantiate()
	
	$Holder.add_child(entry)
	entry.player_input.text = initial_text
	entry.add_resshan(encoded)
	entry.player_input.text_changed.connect(_handle_entry_update.bind(encoded))
	entry.reordered.connect(entry_order_changed.emit)
	entries_count += 1
	if entries_count == LIMIT:
		limit_reached.emit()
	
	return entry

# This WILL cause memory leak, if entry isn't properly handled 
func remove_entry(entry:NotebookEntry) -> void:
	$Holder.remove_child(entry)
	entries_count -= 1
	entry_removed.emit()


func _handle_entry_update(new_text:String, encoded:String) -> void:
	entry_updated.emit(encoded, new_text)


func get_entries() -> Array[NotebookEntry]:
	var arr: Array[NotebookEntry] = []
	arr.append_array($Holder.get_children())
	return arr


func show_drop_indicator(entry: NotebookEntry, after: bool) -> void:
	var y: float = $Holder.position.y + entry.position.y
	if after:
		y += entry.size.y
	_drop_indicator.points = PackedVector2Array([
		Vector2($Holder.position.x, y),
		Vector2($Holder.position.x + $Holder.size.x, y),
	])
	_drop_indicator.visible = true


func hide_drop_indicator() -> void:
	_drop_indicator.visible = false
	

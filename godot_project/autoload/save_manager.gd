extends Node

const LEVELS := [Enums.Scenes.LEVEL_0, Enums.Scenes.LEVEL_1, Enums.Scenes.LEVEL_2]

var save_data_path := "user://save_data.tres"
var save_data: SaveData
var restoring := false
var transitioning := false
var notebook_state: Dictionary = {}
var world_state: Dictionary = {}
var last_error := ""


func _ready() -> void:
	load_game()


func load_game() -> void:
	save_data = _read_save(save_data_path)
	if save_data == null:
		save_data = _read_save(_backup_path())


func has_save() -> bool:
	return save_data != null


func _backup_path() -> String:
	return save_data_path.get_basename() + ".backup.tres"


func _reject(reason: String) -> SaveData:
	push_warning("Save rejected: " + reason)
	return null


func _read_save(path: String) -> SaveData:
	if not FileAccess.file_exists(path):
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null or not file.get_line().begins_with("[gd_resource "):
		return _reject("not a resource file")
	file.close()
	var data = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	if not data is SaveData:
		return _reject("not a SaveData resource")
	if data.version != 1:
		return _reject("version %s" % data.version)
	if data.level not in LEVELS:
		return _reject("level %s" % data.level)
	if data.clock.is_empty() or data.vocabulary.is_empty():
		return _reject("clock or vocabulary missing")
	if int(data.clock.get("remaining", 0)) <= 0:
		return _reject("run already over")
	for item in data.items:
		if item == null or item.quantity < 1:
			return _reject("item with no quantity")
		if item is TicketData:
			if item.train_line not in Enums.TrainColor.values() or item.direction not in Enums.TrainDirection.values():
				return _reject("ticket with line %s direction %s" % [item.train_line, item.direction])
		elif item.id == &"":
			return _reject("item with no id: " + item.item_name)
	return data


func save_unavailable_reason() -> String:
	var level := get_tree().current_scene
	if level == null or not level is LevelTemplate:
		return "Save is only available in a level."
	if transitioning or restoring or GameManager._transition_layer.get_child_count() > 0:
		return "Please wait for the transition to finish."
	if level.get("_intro_active") == true:
		return "Please finish the opening first."
	if TimeManager.total_seconds() <= 0:
		return "This run has ended."
	var ui := level.get_node_or_null("UiOverlay")
	if ui != null and (ui.player_in_arrive_disembark_anim or ui.in_dialog or ui.dragging_item or ui._item_popup.visible):
		return "Please finish the current interaction first."
	for node in get_tree().get_nodes_in_group("save_state"):
		if node.has_method("save_in_progress") and node.save_in_progress():
			return "Please wait for the current event to finish."
	return ""


func save_game() -> bool:
	last_error = save_unavailable_reason()
	if not last_error.is_empty():
		return false
	capture_scene()
	var data := SaveData.new()
	data.first_play = false
	data.level = GameManager.get_current_scene()
	if data.level not in LEVELS:
		last_error = "This level cannot be saved."
		return false
	data.saved_at = Time.get_datetime_string_from_system()
	data.clock = TimeManager.get_save_state()
	data.tokens = Wallet.tokens
	data.battery_enabled = Wallet.enabled
	for item in Inventory.items:
		data.items.append(item.duplicate(true))
	data.vocabulary = Notebook.player_vocab.data.duplicate(true)
	data.notebook = notebook_state.duplicate(true)
	data.world = world_state.duplicate(true)
	var temporary := save_data_path.get_basename() + ".tmp.tres"
	var write_error := ResourceSaver.save(data, temporary)
	if write_error != OK:
		return _fail("Couldn't write the save file: " + error_string(write_error), temporary)
	if _read_save(temporary) == null:
		return _fail("Save data validation failed. Previous save was kept.", temporary)
	var previous := _read_save(save_data_path)
	if previous != null and ResourceSaver.save(previous, _backup_path()) != OK:
		return _fail("Couldn't back up the previous save.", temporary)
	if DirAccess.rename_absolute(temporary, save_data_path) != OK:
		return _fail("Couldn't replace the save file.", temporary)
	save_data = data
	return true


func _fail(reason: String, temporary: String) -> bool:
	last_error = reason
	push_warning("Save failed: " + reason)
	DirAccess.remove_absolute(temporary)
	return false


func continue_game() -> bool:
	load_game()
	if not has_save():
		return false
	restoring = true
	world_state = save_data.world.duplicate(true)
	notebook_state = save_data.notebook.duplicate(true)
	Notebook.player_vocab.data = save_data.vocabulary.duplicate(true)
	Inventory.items.clear()
	for item in save_data.items:
		Inventory.items.append(item.duplicate(true))
	Wallet.tokens = clampi(save_data.tokens, 0, Wallet.MAX_TOKENS)
	Wallet.enabled = save_data.battery_enabled
	TimeManager.restore_save_state(save_data.clock)
	GameManager.level_0_intro_pending = false
	GameManager.stashed_data = null
	SignalBus.rest_ended.emit()
	GameManager.load_scene(save_data.level)
	return true


func new_game() -> void:
	world_state.clear()
	notebook_state.clear()
	Notebook.player_vocab.data = JSON.parse_string(FileAccess.get_file_as_string("res://resshan_systems/player_vocab.json"))
	Inventory.items.clear()
	Wallet.enabled = true
	Wallet.tokens = Wallet.MAX_TOKENS
	TimeManager.begin_new_run()
	GameManager.stashed_data = null
	GameManager.level_0_intro_pending = true
	SignalBus.rest_ended.emit()
	GameManager.load_scene(Enums.Scenes.LEVEL_0)


func capture_scene() -> void:
	if restoring:
		return
	var scene := get_tree().current_scene
	if not scene is LevelTemplate:
		return
	for node in get_tree().get_nodes_in_group("save_state"):
		if scene.is_ancestor_of(node):
			world_state[_node_key(node)] = node.get_save_state()
	for notebook in get_tree().get_nodes_in_group("notebook"):
		if scene.is_ancestor_of(notebook):
			notebook_state = notebook.get_save_state()


func state_for(node: Node) -> Dictionary:
	return world_state.get(_node_key(node), {})


func _node_key(node: Node) -> String:
	var level := node
	while level.get_parent() != null and not level is LevelTemplate:
		level = level.get_parent()
	return level.scene_file_path + "::" + str(level.get_path_to(node))


func level_ready(level: Node) -> void:
	await get_tree().process_frame
	if not is_instance_valid(level) or get_tree().current_scene != level:
		return
	var loaded := restoring
	restoring = false
	transitioning = false
	if loaded:
		return
	while is_instance_valid(level) and get_tree().current_scene == level:
		if save_unavailable_reason().is_empty():
			if not save_game():
				push_warning("Autosave failed: " + last_error)
			return
		await get_tree().create_timer(0.25, false).timeout

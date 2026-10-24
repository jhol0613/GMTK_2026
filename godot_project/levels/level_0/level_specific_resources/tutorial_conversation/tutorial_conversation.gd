extends Sprite2D


@onready var dialogue_interactable := $DialogueInteractable
@onready var dialogue_panel := $CanvasLayer/DialoguePanel

##After a failed run, move on to the next dialogue in the array and so on. After a successful run, 
##start back at 0th dialogue
@export var dialogues: Array[Dialogue]

signal scene_complete

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_modify_dialogues()
	var run_history = SaveManager.get_run_history_since_last_new_game()
	var dialogue_index = 0
	for i in range(run_history.size() - 1, -1, -1):
		#dialogue_index = i
		if dialogue_index >= dialogues.size() - 1:
			break
		if run_history[i] == Enums.RunResult.GOOD_ENDING:
			break
		dialogue_index += 1
	dialogue_interactable.dialogue = dialogues[dialogue_index]
	dialogue_interactable.interact()
	dialogue_panel.dialogue_complete.connect(_on_dialogue_complete)

func _on_dialogue_complete():
	scene_complete.emit()
	#queue_free()

#modify dialogues that use %s
func _modify_dialogues():
	var d: Dialogue = dialogues[1]
	var last_station = SaveManager.get_last_failed_station()
	if last_station:
		d.lines[3].text = d.lines[3].text % Enums.station_scene_to_resshan(last_station)
		d.lines[4].text = d.lines[4].text % Enums.station_scene_to_resshan(last_station)
		d.lines[5].text = d.lines[5].text % Enums.station_scene_to_resshan(last_station)
	

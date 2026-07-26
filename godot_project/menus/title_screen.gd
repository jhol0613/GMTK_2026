extends Node2D

@export_category("Button Sounds")
@export var button_hover_sound: AudioStream
@export var button_click_sound: AudioStream
@export_range(-40.0, 6.0, 0.5) var hover_volume_db: float = 0.0
@export_range(-40.0, 6.0, 0.5) var click_volume_db: float = 0.0

func _ready() -> void:
	for child in $Buttons.get_children():
		if child is Button:
			child.mouse_entered.connect(_play_button_hover)


func _on_play_button_pressed() -> void:
	_play_button_click()
	GameManager.load_scene(Enums.Scenes.LEVEL_0)


func _on_options_button_pressed() -> void:
	_play_button_click()
	GameManager.load_scene(Enums.Scenes.OPTIONS)


func _on_quit_button_pressed() -> void:
	_play_button_click()
	await get_tree().create_timer(0.12).timeout
	get_tree().quit()


func _play_button_hover() -> void:
	AudioManager.play_ui_sfx(
		button_hover_sound,
		hover_volume_db
	)


func _play_button_click() -> void:
	AudioManager.play_ui_sfx(
		button_click_sound,
		click_volume_db
	)

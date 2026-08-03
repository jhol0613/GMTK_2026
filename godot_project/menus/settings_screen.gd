extends Control

@export_category("Button Sounds")
@export var button_hover_sound: AudioStream
@export var button_click_sound: AudioStream
@export_range(-40.0, 6.0, 0.5) var hover_volume_db: float = 0.0
@export_range(-40.0, 6.0, 0.5) var click_volume_db: float = 0.0

@export_category("SFX Test")
@export var sfx_test_sound: AudioStream
@export_range(-40.0, 6.0, 0.5) var sfx_test_volume_db: float = 0.0

@export var in_game_pause: bool = false

@export_category("Pause Menu Music")
@export var pause_menu_bgm: AudioStream
@export_range(-40.0, 6.0, 0.5) var pause_menu_bgm_volume_db: float = -8.0
@export_range(0.0, 5.0, 0.1) var pause_menu_bgm_fade_in: float = 0.5
@export_range(0.0, 5.0, 0.1) var level_bgm_fade_in: float = 0.5

@onready var _music_slider: HSlider = %MusicSlider
@onready var _sfx_slider: HSlider = %SFXSlider
@onready var _back_button: TextureButton = $TextureButton
@onready var _sfx_test_timer: Timer = $SFXTestTimer
@onready var _resume_button: TextureButton = $ResumeButton

var _opened_as_pause_menu := false


func _ready() -> void:
	_opened_as_pause_menu = get_tree().paused
	_resume_button.visible = _opened_as_pause_menu
	
	if _opened_as_pause_menu:
		AudioManager.play_pause_menu_music(
			pause_menu_bgm,
			pause_menu_bgm_fade_in,
			pause_menu_bgm_volume_db
		)
	
	_music_slider.set_value_no_signal(
		AudioManager.get_music_volume() * 100.0
	)
	_sfx_slider.set_value_no_signal(
		AudioManager.get_sfx_volume() * 100.0
	)
	_back_button.mouse_entered.connect(_play_button_hover)


func _on_music_slider_value_changed(value: float) -> void:
	AudioManager.set_music_volume(value / 100.0)


func _on_sfx_slider_value_changed(value: float) -> void:
	AudioManager.set_sfx_volume(value / 100.0)
	_sfx_test_timer.start()


func _play_sfx_test_sound() -> void:
	AudioManager.play_ui_sfx(
		sfx_test_sound,
		sfx_test_volume_db
	)


func _on_texture_button_pressed() -> void:
	AudioManager.play_ui_sfx(
		button_click_sound,
		click_volume_db
	)
	GameManager.load_scene(Enums.Scenes.MAIN)


func _play_button_hover() -> void:
	AudioManager.play_ui_sfx(
		button_hover_sound,
		hover_volume_db
	)

func _on_resume_button_pressed() -> void:
	AudioManager.play_ui_sfx(
		button_click_sound,
		click_volume_db
	)
	AudioManager.resume_music_after_pause(
		level_bgm_fade_in
	)
	GameManager.unpause_game()

func _unhandled_input(event: InputEvent) -> void:
	if not _opened_as_pause_menu:
		return

	if event.is_action_pressed("escape"):
		_on_resume_button_pressed()
		get_viewport().set_input_as_handled()

extends Node2D

const PURCHASE_OUTCOME: StringName = &"bought_coffee"

@export var slow_duration_minutes: int = 5
@export var time_scale_while_active: float = 0.5
@export var purchase_animation: Texture2D
@export var purchase_animation_frames: int = 4
@export var purchase_animation_fps: float = 6.0
@export var empty_cup_item: ItemData

@export_group("Audio")
@export var purchase_sound: AudioStream
@export var drinking_sound: AudioStream
@export var effect_sound: AudioStream
@export_range(-80.0, 6.0, 0.5) var purchase_volume_db := -4.0
@export_range(-80.0, 6.0, 0.5) var drinking_volume_db := 0.0
@export_range(-80.0, 6.0, 0.5) var effect_volume_db := -10.0

@onready var _dialogue_panel: DialoguePanel = $DialoguePanel
@onready var _lightning_origin := $LightningOrigin


func _ready() -> void:
	_dialogue_panel.option_confirmed.connect(_on_option_confirmed)


func _on_option_confirmed(outcome_id: StringName) -> void:
	_dialogue_panel.hide_popup.call_deferred()
	if outcome_id != PURCHASE_OUTCOME:
		return
	if not Wallet.spend(Wallet.COFFEE_COST, _lightning_origin.global_position):
		return
	if purchase_sound != null:
		AudioManager.play_ui_sfx(purchase_sound, purchase_volume_db)
	if purchase_animation != null:
		SignalBus.animated_item_popup_requested.emit(
			purchase_animation,
			purchase_animation_frames,
			purchase_animation_fps,
		)
		if drinking_sound != null:
			AudioManager.play_ui_sfx(drinking_sound, drinking_volume_db)
		await SignalBus.item_popup_finished
	elif purchase_sound != null:
		await get_tree().create_timer(purchase_sound.get_length()).timeout
	if empty_cup_item != null:
		Inventory.add_item(empty_cup_item.duplicate() as ItemData)
	if effect_sound != null:
		AudioManager.play_ui_sfx(effect_sound, effect_volume_db)
	TimeManager.set_time_scale(time_scale_while_active, slow_duration_minutes)
	

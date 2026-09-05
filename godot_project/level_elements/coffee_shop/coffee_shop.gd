extends Node2D

const PURCHASE_OUTCOME: StringName = &"bought_coffee"
const EMPTY_COFFEE_ID: StringName = &"empty_coffee_cup"

@export var slow_duration_minutes: int = 5
@export var time_scale_while_active: float = 0.5
@export var no_money_line: DialogueLine

@onready var _dialogue_panel: DialoguePanel = $DialoguePanel
@onready var _lightning_origin := $LightningOrigin
@onready var _drinking_sound := $DrinkingSound

func _ready() -> void:
	_dialogue_panel.option_confirmed.connect(_on_option_confirmed)


func _on_option_confirmed(outcome_id: StringName) -> void:
	if outcome_id == &"NONE":
		_dialogue_panel.hide_popup.call_deferred()
		return
	if outcome_id != PURCHASE_OUTCOME:
		return
	if not Wallet.spend(Wallet.COFFEE_COST):
		var line = no_money_line.duplicate()
		line.text = no_money_line.text % [Wallet.tokens, Wallet.COFFEE_COST]
		_dialogue_panel.reject_choice(line)
		return
	Inventory.item_added.connect(_on_item_added)
	TimeManager.set_time_scale(time_scale_while_active, slow_duration_minutes)

func _on_item_added(item: ItemData):
	if item.id != EMPTY_COFFEE_ID:
		return
	Inventory.item_added.disconnect(_on_item_added)
	if _drinking_sound.stream != null:
		_drinking_sound.play()

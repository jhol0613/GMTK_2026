extends Node2D

const PURCHASE_OUTCOME: StringName = &"bought_coffee"
const EMPTY_COFFEE_ID: StringName = &"empty_coffee_cup"

@export var slow_duration_minutes: int = 5
@export var time_scale_while_active: float = 0.5
@export var no_money_line: DialogueLine
@export var after_first_coffee_line: DialogueLine

@onready var _dialogue_panel: DialoguePanel = $DialoguePanel
@onready var _lightning_origin := $LightningOrigin
@onready var _drinking_sound := $DrinkingSound
@onready var _interactable := $DialogueInteractable

var _got_free_coffee = false

func _ready() -> void:
	_dialogue_panel.option_confirmed.connect(_on_option_confirmed)

func _on_option_confirmed(outcome_id: StringName) -> void:
	if outcome_id == &"NONE":
		_dialogue_panel.hide_popup.call_deferred()
		return
	if outcome_id != PURCHASE_OUTCOME:
		return
	var cost = Wallet.COFFEE_COST if _got_free_coffee else 0
	if not Wallet.spend(cost):
		var line = no_money_line.duplicate()
		line.text = no_money_line.text % [Wallet.tokens, Wallet.COFFEE_COST]
		_dialogue_panel.reject_choice(line)
		return
	_got_free_coffee = true
	_interactable.dialogue.lines[1] = after_first_coffee_line
	Inventory.item_added.connect(_on_item_added)
	TimeManager.set_time_scale(time_scale_while_active, slow_duration_minutes)

func _on_item_added(item: ItemData):
	if item.id != EMPTY_COFFEE_ID:
		return
	Inventory.item_added.disconnect(_on_item_added)
	if _drinking_sound.stream != null:
		_drinking_sound.play()

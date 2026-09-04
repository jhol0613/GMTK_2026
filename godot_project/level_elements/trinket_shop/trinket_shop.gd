extends Node2D


const PURCHASE_OUTCOME: StringName = &"sold_trinket"

@onready var _dialogue_panel: DialoguePanel = $DialoguePanel
@onready var _purchase_sfx: AudioStreamPlayer2D = $PurchaseSfx
@onready var _lightning_origin := $LightningOrigin

var _awaiting_trinket: bool = false


func _ready() -> void:
	_dialogue_panel.option_confirmed.connect(_on_option_confirmed)
	Inventory.item_added.connect(_on_item_added)


func _on_option_confirmed(outcome_id: StringName) -> void:
	if outcome_id == &"NONE":
		_dialogue_panel.hide_popup.call_deferred()
		return
	#if outcome_id != PURCHASE_OUTCOME:
		#return
	if not Wallet.can_afford(Wallet.TRINKET_COST):
		_dialogue_panel.reject_choice("<<0>> <<money>> <<0>> <<mask>> <<angry>>")
		return
	if Inventory.is_full():
		SignalBus.inventory_full.emit()
		return
	Wallet.spend(Wallet.TRINKET_COST, _lightning_origin.global_position)
	_awaiting_trinket = true


func _on_item_added(item: ItemData) -> void:
	if not _awaiting_trinket:
		return
	if not String(item.id).begins_with("mask_"):
		return
	_awaiting_trinket = false
	if _purchase_sfx.stream != null:
		_purchase_sfx.play()

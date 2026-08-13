extends Node


signal tokens_changed(current: int, maximum: int)
signal spend_failed(cost: int, current: int)
signal refilled

const MAX_TOKENS: int = 16
const TICKET_COST: int = 4
const TRINKET_COST: int = 2
const COFFEE_COST: int = 5

var tokens: int = MAX_TOKENS


func _ready() -> void:
	tokens_changed.emit(tokens, MAX_TOKENS)


func spend(cost: int) -> bool:
	if cost <= 0:
		return true
	if tokens < cost:
		spend_failed.emit(cost, tokens)
		return false
	tokens -= cost
	tokens_changed.emit(tokens, MAX_TOKENS)
	return true


func can_afford(cost: int) -> bool:
	return tokens >= cost


func refill() -> void:
	if tokens == MAX_TOKENS:
		return
	tokens = MAX_TOKENS
	tokens_changed.emit(tokens, MAX_TOKENS)
	refilled.emit()


func add(amount: int) -> void:
	if amount <= 0:
		return
	tokens = mini(tokens + amount, MAX_TOKENS)
	tokens_changed.emit(tokens, MAX_TOKENS)


func reset() -> void:
	tokens = MAX_TOKENS
	tokens_changed.emit(tokens, MAX_TOKENS)

extends Resource

class_name SaveData

@export var first_play := true
@export var version := 1
@export var level := -1
@export var saved_at := ""
@export var clock: Dictionary = {}
@export var tokens := 0
@export var battery_enabled := true
@export var items: Array[ItemData] = []
@export var vocabulary: Dictionary = {}
@export var notebook: Dictionary = {}
@export var world: Dictionary = {}

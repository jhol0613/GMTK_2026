extends Resource

##Used for data (aside from Notebook) that should persist between runs (e.g. Options settings, run result history)
class_name PersistentSaveData

@export var run_history : Array[Enums.RunResult] = []

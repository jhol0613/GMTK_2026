class_name DialogueChoice
extends Resource

@export var player_text: String = ""
@export var reply: String = ""
## Optional item granted when this choice is confirmed. Leave empty for none.
@export var reward: ItemData
## Optional id for scene-side effects (animations, doors, etc.).
@export var outcome_id: StringName = &""

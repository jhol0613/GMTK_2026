class_name DroppedCoffee
extends Interactable

signal collected

const GROUND_OBJECT_GROUP := &"coffee_npc_ground_object"

@export var item: ItemData


func _ready() -> void:
	super._ready()
	for object in get_tree().get_nodes_in_group(GROUND_OBJECT_GROUP):
		if (
			object != self
			and not object.is_queued_for_deletion()
			and object.get_instance_id() < get_instance_id()
		):
			queue_free()
			return


func interact() -> void:
	if item != null and not Inventory.add_item(item.duplicate() as ItemData):
		return
	collected.emit()
	for object in get_tree().get_nodes_in_group(GROUND_OBJECT_GROUP):
		if not object.is_queued_for_deletion():
			object.queue_free()

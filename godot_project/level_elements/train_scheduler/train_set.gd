##Allows basic O(1) set operations on groups of trains
class_name TrainSet
extends Resource

##dicionary used as a wrapper since keys are stored as a set
var train_dict: Dictionary[Train, bool]

##Adds to the set if the set doesn't already contain that train
func push_unique(key: Train):
	train_dict.get_or_add(key, false)

##Removes a random key from the set and returns its value. Returns null if set is empty
func pop_rand() -> Train:
	if train_dict.is_empty():
		return null
	var index = randi_range(0, train_dict.keys().size()-1)
	var train_to_return = train_dict.keys()[index]
	train_dict.erase(train_to_return)
	return train_to_return

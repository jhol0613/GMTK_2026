extends SectionTab

## override to remove functionality
func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	return false

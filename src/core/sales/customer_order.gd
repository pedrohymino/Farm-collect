class_name CustomerOrder
extends RefCounted
## What one customer wants. is_ready = the customer is standing at the counter.

var item_id: StringName
var count: int
var patience: float
var is_ready: bool = false


func _init(p_item_id: StringName, p_count: int, p_patience: float) -> void:
	item_id = p_item_id
	count = p_count
	patience = p_patience

class_name Modifier
extends RefCounted
## A change applied to one stat by one source (upgrade, passive, worker...).
## See StatRegistry for how modifier types combine.

enum Type { FLAT, PERCENT, MULTIPLIER }

var stat_id: StringName
var type: Type
var value: float
var source_id: StringName


func _init(p_stat_id: StringName, p_type: Type, p_value: float, p_source_id: StringName) -> void:
	stat_id = p_stat_id
	type = p_type
	value = p_value
	source_id = p_source_id

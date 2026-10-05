class_name StatDef
extends RefCounted
## Definition of one stat, loaded from data/balance/stats.json.

var id: StringName
var base: float = 0.0
var min_value: float = -INF
var max_value: float = INF
var is_integer: bool = false


static func from_dict(p_id: StringName, raw: Dictionary) -> StatDef:
	var stat_def := StatDef.new()
	stat_def.id = p_id
	stat_def.base = float(raw.get("base", 0.0))
	stat_def.min_value = float(raw.get("min", -INF))
	stat_def.max_value = float(raw.get("max", INF))
	stat_def.is_integer = bool(raw.get("integer", false))
	return stat_def

class_name StatRegistry
extends RefCounted
## Pure stat + modifier logic; the Stats autoload wraps one instance.
##
## final = (base + sum(FLAT)) * (1 + sum(PERCENT)) * product(MULTIPLIER), clamped to [min, max].
## A dev override (absolute value or multiplier) is applied last and ignores the clamp.
## Integer stats are rounded at the end.

signal stat_changed(stat_id: StringName, value: float)

var _defs: Dictionary = {}  # StringName -> StatDef
var _modifiers: Dictionary = {}  # StringName -> Array[Modifier]
var _dev_overrides: Dictionary = {}  # StringName -> {"multiplier": float, "absolute": Variant}
var _cache: Dictionary = {}  # StringName -> float


## Replaces stat definitions. Modifiers and dev overrides of stats that still exist are kept,
## so balance data can be reloaded while playing.
func load_defs(raw: Dictionary) -> void:
	_defs.clear()
	for key: String in raw:
		_defs[StringName(key)] = StatDef.from_dict(StringName(key), raw[key])
	for stat_id: StringName in _modifiers.keys():
		if not _defs.has(stat_id):
			_modifiers.erase(stat_id)
	for stat_id: StringName in _dev_overrides.keys():
		if not _defs.has(stat_id):
			_dev_overrides.erase(stat_id)
	_cache.clear()
	for stat_id: StringName in _defs:
		stat_changed.emit(stat_id, get_value(stat_id))


func has_stat(stat_id: StringName) -> bool:
	return _defs.has(stat_id)


func stat_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	ids.assign(_defs.keys())
	ids.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	return ids


func get_value(stat_id: StringName) -> float:
	if not _defs.has(stat_id):
		push_error("Unknown stat: %s" % stat_id)
		return 0.0
	if not _cache.has(stat_id):
		_cache[stat_id] = _compute(stat_id)
	return _cache[stat_id]


## Global stat times its scoped variant, e.g. production.rate * production.rate.egg.
## Scoped stats are optional: without one, the global value is returned.
func get_scoped(stat_id: StringName, scope: StringName) -> float:
	var global_value := get_value(stat_id)
	var scoped_id := StringName("%s.%s" % [stat_id, scope])
	if _defs.has(scoped_id):
		return global_value * get_value(scoped_id)
	return global_value


func add_modifier(modifier: Modifier) -> void:
	if not _defs.has(modifier.stat_id):
		push_error("Unknown stat: %s (modifier from %s)" % [modifier.stat_id, modifier.source_id])
		return
	if not _modifiers.has(modifier.stat_id):
		var list: Array[Modifier] = []
		_modifiers[modifier.stat_id] = list
	_modifiers[modifier.stat_id].append(modifier)
	_invalidate(modifier.stat_id)


func remove_modifiers_from(source_id: StringName) -> void:
	var changed: Array[StringName] = []
	for stat_id: StringName in _modifiers:
		var list: Array[Modifier] = _modifiers[stat_id]
		var kept := list.filter(func(m: Modifier) -> bool: return m.source_id != source_id)
		if kept.size() != list.size():
			list.assign(kept)
			changed.append(stat_id)
	for stat_id in changed:
		_invalidate(stat_id)


func modifier_count() -> int:
	var total := 0
	for stat_id: StringName in _modifiers:
		total += _modifiers[stat_id].size()
	return total


func set_base(stat_id: StringName, base: float) -> void:
	if not _defs.has(stat_id):
		push_error("Unknown stat: %s" % stat_id)
		return
	_defs[stat_id].base = base
	_invalidate(stat_id)


func set_dev_override(
	stat_id: StringName, multiplier: float = 1.0, absolute: Variant = null
) -> void:
	if not _defs.has(stat_id):
		push_error("Unknown stat: %s" % stat_id)
		return
	_dev_overrides[stat_id] = {"multiplier": multiplier, "absolute": absolute}
	_invalidate(stat_id)


func clear_dev_override(stat_id: StringName) -> void:
	if _dev_overrides.erase(stat_id):
		_invalidate(stat_id)


func clear_all_dev_overrides() -> void:
	var ids: Array = _dev_overrides.keys()
	_dev_overrides.clear()
	for stat_id: StringName in ids:
		_invalidate(stat_id)


func dev_overrides() -> Dictionary:
	return _dev_overrides.duplicate(true)


## Everything the dev panel needs to explain a value.
func breakdown(stat_id: StringName) -> Dictionary:
	if not _defs.has(stat_id):
		push_error("Unknown stat: %s" % stat_id)
		return {}
	var stat_def: StatDef = _defs[stat_id]
	var modifiers: Array[Dictionary] = []
	for modifier: Modifier in _modifiers.get(stat_id, []):
		modifiers.append(
			{"type": modifier.type, "value": modifier.value, "source_id": modifier.source_id}
		)
	return {
		"base": stat_def.base,
		"min": stat_def.min_value,
		"max": stat_def.max_value,
		"is_integer": stat_def.is_integer,
		"modifiers": modifiers,
		"dev": _dev_overrides.get(stat_id, {}).duplicate(),
		"final": get_value(stat_id),
	}


func _compute(stat_id: StringName) -> float:
	var stat_def: StatDef = _defs[stat_id]
	var flat := 0.0
	var percent := 0.0
	var multiplier := 1.0
	for modifier: Modifier in _modifiers.get(stat_id, []):
		match modifier.type:
			Modifier.Type.FLAT:
				flat += modifier.value
			Modifier.Type.PERCENT:
				percent += modifier.value
			Modifier.Type.MULTIPLIER:
				multiplier *= modifier.value
	var value := (stat_def.base + flat) * (1.0 + percent) * multiplier
	value = clampf(value, stat_def.min_value, stat_def.max_value)
	if _dev_overrides.has(stat_id):
		var dev: Dictionary = _dev_overrides[stat_id]
		if dev["absolute"] != null:
			value = float(dev["absolute"])
		else:
			value *= float(dev["multiplier"])
	if stat_def.is_integer:
		value = roundf(value)
	return value


func _invalidate(stat_id: StringName) -> void:
	_cache.erase(stat_id)
	stat_changed.emit(stat_id, get_value(stat_id))

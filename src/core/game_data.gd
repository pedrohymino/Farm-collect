class_name GameData
extends RefCounted
## Everything that is saved. Pure data; the GameState autoload holds the live instance.
## from_dict() is tolerant: missing or invalid fields fall back to new-game defaults.

const DEFAULT_FARM_LEVEL: int = 1

var wallet: Wallet = Wallet.new()
var unlocked: Dictionary = {}  # StringName -> true
var unlock_progress: Dictionary = {}  # StringName -> float (money already paid into a pad)
var upgrade_levels: Dictionary = {}  # StringName -> int
var passive_nodes: Dictionary = {}  # StringName -> true
var farm_level: int = DEFAULT_FARM_LEVEL
var farm_xp: float = 0.0
var locations: Dictionary = {}  # StringName -> Dictionary owned by that location


func is_unlocked(unlock_id: StringName) -> bool:
	return unlocked.has(unlock_id)


func unlock(unlock_id: StringName) -> void:
	unlocked[unlock_id] = true
	unlock_progress.erase(unlock_id)


func to_dict() -> Dictionary:
	return {
		"wallet": wallet.to_dict(),
		"unlocked": _keys_as_strings(unlocked),
		"unlock_progress": _keys_to_strings(unlock_progress),
		"upgrade_levels": _keys_to_strings(upgrade_levels),
		"passive_nodes": _keys_as_strings(passive_nodes),
		"farm_level": farm_level,
		"farm_xp": farm_xp,
		"locations": _keys_to_strings(locations),
	}


static func from_dict(raw: Dictionary) -> GameData:
	var data := GameData.new()
	data.wallet.load_dict(_dict_or_empty(raw.get("wallet")))
	data.unlocked = _string_set(raw.get("unlocked"))
	data.passive_nodes = _string_set(raw.get("passive_nodes"))
	data.unlock_progress = _number_map(raw.get("unlock_progress"), false)
	data.upgrade_levels = _number_map(raw.get("upgrade_levels"), true)
	data.farm_level = maxi(_int_or(raw.get("farm_level"), DEFAULT_FARM_LEVEL), DEFAULT_FARM_LEVEL)
	data.farm_xp = maxf(_float_or(raw.get("farm_xp"), 0.0), 0.0)
	var raw_locations := _dict_or_empty(raw.get("locations"))
	for location_id: String in raw_locations:
		data.locations[StringName(location_id)] = _dict_or_empty(raw_locations[location_id])
	return data


static func _keys_as_strings(set_dict: Dictionary) -> Array:
	var keys: Array = []
	for key: StringName in set_dict:
		keys.append(String(key))
	return keys


static func _keys_to_strings(source: Dictionary) -> Dictionary:
	var result := {}
	for key: StringName in source:
		result[String(key)] = source[key]
	return result


static func _dict_or_empty(value: Variant) -> Dictionary:
	return value if typeof(value) == TYPE_DICTIONARY else {}


static func _string_set(value: Variant) -> Dictionary:
	var result := {}
	if typeof(value) != TYPE_ARRAY:
		return result
	for entry: Variant in value:
		if typeof(entry) == TYPE_STRING:
			result[StringName(entry)] = true
	return result


## Keeps only non-negative numbers; rounds to int when `as_int`.
static func _number_map(value: Variant, as_int: bool) -> Dictionary:
	var result := {}
	for key: String in _dict_or_empty(value):
		var number: Variant = value[key]
		if typeof(number) != TYPE_FLOAT and typeof(number) != TYPE_INT:
			continue
		if float(number) < 0.0:
			continue
		result[StringName(key)] = roundi(number) if as_int else float(number)
	return result


static func _int_or(value: Variant, fallback: int) -> int:
	if typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT:
		return roundi(value)
	return fallback


static func _float_or(value: Variant, fallback: float) -> float:
	if typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT:
		return float(value)
	return fallback

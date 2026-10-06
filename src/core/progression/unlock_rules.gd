class_name UnlockRules
extends RefCounted
## Pure unlock logic over data/balance/unlocks.json and the saved GameData:
## availability (all requirements done), partial payments, unit bonuses, validation.
## Def shape: {"cost": number, "requires": [ids], "units": {producer_id: int}}

## Remaining cost below this counts as fully paid (float drain steps).
const COMPLETE_EPSILON: float = 0.001

var _defs: Dictionary


func _init(defs: Dictionary) -> void:
	_defs = defs


func has(unlock_id: StringName) -> bool:
	return _defs.has(String(unlock_id))


func ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for unlock_id: String in _defs:
		result.append(StringName(unlock_id))
	return result


func base_cost(unlock_id: StringName) -> float:
	return float(_def(unlock_id).get("cost", 0.0))


func requires(unlock_id: StringName) -> Array[StringName]:
	var result: Array[StringName] = []
	for required: Variant in _def(unlock_id).get("requires", []):
		result.append(StringName(required))
	return result


func is_available(unlock_id: StringName, data: GameData) -> bool:
	if not has(unlock_id) or data.is_unlocked(unlock_id):
		return false
	for required in requires(unlock_id):
		if not data.is_unlocked(required):
			return false
	return true


func available_ids(data: GameData) -> Array[StringName]:
	var result: Array[StringName] = []
	for unlock_id in ids():
		if is_available(unlock_id, data):
			result.append(unlock_id)
	result.sort_custom(
		func(a: StringName, b: StringName) -> bool: return base_cost(a) < base_cost(b)
	)
	return result


func paid(unlock_id: StringName, data: GameData) -> float:
	return float(data.unlock_progress.get(unlock_id, 0.0))


func remaining(unlock_id: StringName, cost: float, data: GameData) -> float:
	if data.is_unlocked(unlock_id):
		return 0.0
	return maxf(cost - paid(unlock_id, data), 0.0)


## Adds `amount` to the unlock's progress (never more than what is left).
## Returns true when this payment completed the unlock.
func pay(unlock_id: StringName, amount: float, cost: float, data: GameData) -> bool:
	if not is_available(unlock_id, data) or amount < 0.0:
		return false
	var applied := minf(amount, remaining(unlock_id, cost, data))
	data.unlock_progress[unlock_id] = paid(unlock_id, data) + applied
	if remaining(unlock_id, cost, data) <= COMPLETE_EPSILON:
		data.unlock(unlock_id)
		return true
	return false


## Extra units (animals, crop beds) that completed unlocks give to a producer.
func units_bonus(target: StringName, data: GameData) -> int:
	var total := 0
	for unlock_id in ids():
		if data.is_unlocked(unlock_id):
			total += int(_def(unlock_id).get("units", {}).get(String(target), 0))
	return total


static func validate(defs: Dictionary, producers: Dictionary) -> PackedStringArray:
	var found := PackedStringArray()
	var max_bonus := {}
	for unlock_id: String in defs:
		var entry: Variant = defs[unlock_id]
		if typeof(entry) != TYPE_DICTIONARY:
			found.append("unlock '%s' must be an object" % unlock_id)
			continue
		var cost: Variant = entry.get("cost")
		if (typeof(cost) != TYPE_INT and typeof(cost) != TYPE_FLOAT) or float(cost) < 0.0:
			found.append("unlock '%s' needs a 'cost' >= 0" % unlock_id)
		for required: Variant in entry.get("requires", []):
			if not defs.has(required):
				found.append("unlock '%s' requires unknown '%s'" % [unlock_id, required])
		var units: Variant = entry.get("units", {})
		for target: String in units:
			if not producers.has(target):
				found.append(
					"unlock '%s' gives units to unknown producer '%s'" % [unlock_id, target]
				)
			elif int(units[target]) <= 0:
				found.append("unlock '%s' must give a positive number of units" % unlock_id)
			else:
				max_bonus[target] = int(max_bonus.get(target, 0)) + int(units[target])
	for target: String in max_bonus:
		var producer: Dictionary = producers[target]
		if (
			int(producer.get("base_units", 0)) + max_bonus[target]
			> int(producer.get("max_units", 0))
		):
			found.append("unlocks give '%s' more units than its max_units" % target)
	found.append_array(_find_cycles(defs))
	return found


static func _find_cycles(defs: Dictionary) -> PackedStringArray:
	var found := PackedStringArray()
	var state := {}  # id -> 1 visiting, 2 done
	for unlock_id: String in defs:
		if _visit(unlock_id, defs, state):
			found.append("unlock requirements have a cycle through '%s'" % unlock_id)
			break
	return found


## Depth-first search; returns true when it finds a cycle.
static func _visit(unlock_id: String, defs: Dictionary, state: Dictionary) -> bool:
	if state.get(unlock_id, 0) == 2:
		return false
	if state.get(unlock_id, 0) == 1:
		return true
	state[unlock_id] = 1
	var entry: Variant = defs.get(unlock_id, {})
	if typeof(entry) == TYPE_DICTIONARY:
		for required: Variant in entry.get("requires", []):
			if defs.has(required) and _visit(String(required), defs, state):
				return true
	state[unlock_id] = 2
	return false


func _def(unlock_id: StringName) -> Dictionary:
	var entry: Variant = _defs.get(String(unlock_id), {})
	return entry if typeof(entry) == TYPE_DICTIONARY else {}

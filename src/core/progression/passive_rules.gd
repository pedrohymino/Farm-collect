class_name PassiveRules
extends RefCounted
## Passive tree from data/balance/passives.json, bought with stars.
## A node can be bought when it has no requirements (branch root) or when any required
## neighbor is owned. Def shape: {"branch", "cost", "requires": [ids], "key"?, "effects": [...]}

enum NodeState { LOCKED, AVAILABLE, OWNED }

const SOURCE_PREFIX: String = "passive:"

var _defs: Dictionary


func _init(defs: Dictionary) -> void:
	_defs = defs


func ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for node_id: String in _defs:
		result.append(StringName(node_id))
	return result


func has(node_id: StringName) -> bool:
	return _defs.has(String(node_id))


## Branch ids in file order.
func branches() -> Array[StringName]:
	var result: Array[StringName] = []
	for node_id in ids():
		var branch := branch_of(node_id)
		if not result.has(branch):
			result.append(branch)
	return result


func nodes_in_branch(branch: StringName) -> Array[StringName]:
	var result: Array[StringName] = []
	for node_id in ids():
		if branch_of(node_id) == branch:
			result.append(node_id)
	return result


func branch_of(node_id: StringName) -> StringName:
	return StringName(_def(node_id).get("branch", ""))


func cost(node_id: StringName) -> int:
	return int(_def(node_id).get("cost", 0))


func is_key(node_id: StringName) -> bool:
	return bool(_def(node_id).get("key", false))


func requires(node_id: StringName) -> Array[StringName]:
	var result: Array[StringName] = []
	for required: Variant in _def(node_id).get("requires", []):
		result.append(StringName(required))
	return result


## Distance from the branch root (root = 1).
func depth(node_id: StringName) -> int:
	var parents := requires(node_id)
	if parents.is_empty():
		return 1
	var deepest := 0
	for parent in parents:
		deepest = maxi(deepest, depth(parent))
	return deepest + 1


func effects(node_id: StringName) -> Array:
	return _def(node_id).get("effects", [])


func can_unlock(node_id: StringName, data: GameData) -> bool:
	if not has(node_id) or data.passive_nodes.has(node_id):
		return false
	var parents := requires(node_id)
	if parents.is_empty():
		return true
	for parent in parents:
		if data.passive_nodes.has(parent):
			return true
	return false


func state(node_id: StringName, data: GameData) -> NodeState:
	if data.passive_nodes.has(node_id):
		return NodeState.OWNED
	return NodeState.AVAILABLE if can_unlock(node_id, data) else NodeState.LOCKED


func source_id(node_id: StringName) -> StringName:
	return StringName(SOURCE_PREFIX + node_id)


func modifiers(node_id: StringName) -> Array[Modifier]:
	return EffectSpec.to_modifiers(effects(node_id), 1, source_id(node_id))


static func validate(defs: Dictionary, stats: Dictionary) -> PackedStringArray:
	var found := PackedStringArray()
	for node_id: String in defs:
		var entry: Variant = defs[node_id]
		if typeof(entry) != TYPE_DICTIONARY:
			found.append("passive '%s' must be an object" % node_id)
			continue
		if String(entry.get("branch", "")).is_empty():
			found.append("passive '%s' needs a 'branch'" % node_id)
		elif int(entry.get("cost", 0)) < 1:
			found.append("passive '%s' needs a 'cost' of at least 1 star" % node_id)
		for required: Variant in entry.get("requires", []):
			if not defs.has(required):
				found.append("passive '%s' requires unknown '%s'" % [node_id, required])
		found.append_array(EffectSpec.validate(entry.get("effects"), stats, node_id))
	return found


func _def(node_id: StringName) -> Dictionary:
	var entry: Variant = _defs.get(String(node_id), {})
	return entry if typeof(entry) == TYPE_DICTIONARY else {}

class_name UpgradeRules
extends RefCounted
## Leveled money upgrades from data/balance/upgrades.json.
## cost(level) = base_cost × growth^level × cost_multiplier (the upgrade.cost stat).
## Def shape: {"base_cost", "growth", "max_level"?, "requires_unlock"?, "effects": [...]}

const SOURCE_PREFIX: String = "upgrade:"

var _defs: Dictionary


func _init(defs: Dictionary) -> void:
	_defs = defs


func ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for upgrade_id: String in _defs:
		result.append(StringName(upgrade_id))
	return result


func has(upgrade_id: StringName) -> bool:
	return _defs.has(String(upgrade_id))


func cost(upgrade_id: StringName, level: int, cost_multiplier: float) -> float:
	var entry := _def(upgrade_id)
	return (
		float(entry.get("base_cost", 0.0))
		* pow(float(entry.get("growth", 1.0)), level)
		* cost_multiplier
	)


## 0 = no limit.
func max_level(upgrade_id: StringName) -> int:
	return int(_def(upgrade_id).get("max_level", 0))


func is_maxed(upgrade_id: StringName, level: int) -> bool:
	var limit := max_level(upgrade_id)
	return limit > 0 and level >= limit


## Unlock that must be completed before the upgrade shows up ("" = always available).
func required_unlock(upgrade_id: StringName) -> StringName:
	return StringName(_def(upgrade_id).get("requires_unlock", ""))


func is_visible(upgrade_id: StringName, data: GameData) -> bool:
	var required := required_unlock(upgrade_id)
	return required.is_empty() or data.is_unlocked(required)


func effects(upgrade_id: StringName) -> Array:
	return _def(upgrade_id).get("effects", [])


func source_id(upgrade_id: StringName) -> StringName:
	return StringName(SOURCE_PREFIX + upgrade_id)


func modifiers(upgrade_id: StringName, level: int) -> Array[Modifier]:
	return EffectSpec.to_modifiers(effects(upgrade_id), level, source_id(upgrade_id))


static func validate(defs: Dictionary, stats: Dictionary) -> PackedStringArray:
	var found := PackedStringArray()
	for upgrade_id: String in defs:
		var entry: Variant = defs[upgrade_id]
		if typeof(entry) != TYPE_DICTIONARY:
			found.append("upgrade '%s' must be an object" % upgrade_id)
			continue
		if float(entry.get("base_cost", 0)) <= 0.0:
			found.append("upgrade '%s' needs a positive 'base_cost'" % upgrade_id)
		elif float(entry.get("growth", 0)) <= 1.0:
			found.append("upgrade '%s' needs 'growth' > 1" % upgrade_id)
		found.append_array(EffectSpec.validate(entry.get("effects"), stats, upgrade_id))
	return found


func _def(upgrade_id: StringName) -> Dictionary:
	var entry: Variant = _defs.get(String(upgrade_id), {})
	return entry if typeof(entry) == TYPE_DICTIONARY else {}

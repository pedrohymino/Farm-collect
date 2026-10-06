class_name EffectSpec
extends RefCounted
## Turns data effects ({"stat", "type": flat|percent|multiplier, "value"}) into stat Modifiers.
## Shared by upgrades (scaled by level) and passives (level 1).
## Per level: flat and percent add up (value × level); multipliers compound (value ^ level).

const TYPES: Dictionary = {
	"flat": Modifier.Type.FLAT,
	"percent": Modifier.Type.PERCENT,
	"multiplier": Modifier.Type.MULTIPLIER,
}


static func to_modifiers(effects: Array, level: int, source_id: StringName) -> Array[Modifier]:
	var modifiers: Array[Modifier] = []
	if level <= 0:
		return modifiers
	for effect: Dictionary in effects:
		var type: Modifier.Type = TYPES[effect["type"]]
		var value := float(effect["value"])
		var scaled := pow(value, level) if type == Modifier.Type.MULTIPLIER else value * level
		modifiers.append(Modifier.new(StringName(effect["stat"]), type, scaled, source_id))
	return modifiers


static func validate(effects: Variant, stats: Dictionary, owner_id: String) -> PackedStringArray:
	var found := PackedStringArray()
	if typeof(effects) != TYPE_ARRAY:
		found.append("'%s' needs an 'effects' list" % owner_id)
		return found
	for effect: Variant in effects:
		if typeof(effect) != TYPE_DICTIONARY:
			found.append("'%s' has an effect that is not an object" % owner_id)
		elif not stats.has(effect.get("stat", "")):
			found.append("'%s' affects unknown stat '%s'" % [owner_id, effect.get("stat")])
		elif not TYPES.has(effect.get("type", "")):
			found.append("'%s' has unknown effect type '%s'" % [owner_id, effect.get("type")])
		elif typeof(effect.get("value")) != TYPE_INT and typeof(effect.get("value")) != TYPE_FLOAT:
			found.append("'%s' has an effect without a numeric 'value'" % owner_id)
	return found

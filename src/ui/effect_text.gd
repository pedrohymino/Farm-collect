class_name EffectText
extends RefCounted
## Human text for data effects, e.g. "+6% Speed", "+2 Carry capacity", "+5% Tip chance".
## Stat names come from translation keys STAT_<ID> (dots become underscores).

const DECIMALS: int = 2
## Flat effects on these stats are shown as percentage points (0.05 -> "+5%").
const CHANCE_SUFFIX: String = "_chance"


static func stat_name_key(stat_id: String) -> String:
	return "STAT_" + stat_id.to_upper().replace(".", "_")


static func amount(effect: Dictionary, level: int = 1) -> String:
	var value := float(effect["value"])
	match effect["type"]:
		"percent":
			return _signed(value * level * 100.0) + "%"
		"multiplier":
			return "×" + NumberFormat.trimmed(pow(value, level), DECIMALS)
		_:
			if String(effect["stat"]).ends_with(CHANCE_SUFFIX):
				return _signed(value * level * 100.0) + "%"
			return _signed(value * level)


## One line per effect: "<amount> <stat name>". `translate` maps a key to text (usually tr).
static func describe(effects: Array, translate: Callable, level: int = 1) -> String:
	var lines := PackedStringArray()
	for effect: Dictionary in effects:
		lines.append(
			"%s %s" % [amount(effect, level), translate.call(stat_name_key(effect["stat"]))]
		)
	return "\n".join(lines)


static func _signed(value: float) -> String:
	return ("+" if value >= 0.0 else "") + NumberFormat.trimmed(value, DECIMALS)

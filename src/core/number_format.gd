class_name NumberFormat
extends RefCounted
## Short number formatting for incremental values: 999, 1.2K, 34.5M, 123B, 1aa, 2.5ab...
## Always floors (never shows more than the player actually has).

const NAMED_SUFFIXES: Array[String] = ["", "K", "M", "B", "T"]
const LETTERS: String = "abcdefghijklmnopqrstuvwxyz"
const TIER_SIZE: float = 1000.0
## Absorbs float error from repeated division (e.g. 0.9999999 that should be 1).
const EPSILON: float = 1e-6
## Relative tolerance for moving to the next tier; must stay far below display precision.
const TIER_TOLERANCE: float = 1e-9


static func format(value: float) -> String:
	var sign_prefix := "-" if value < 0.0 else ""
	var magnitude := absf(value)
	var tier := 0
	while magnitude >= TIER_SIZE * (1.0 - TIER_TOLERANCE):
		magnitude /= TIER_SIZE
		tier += 1
	return sign_prefix + _mantissa(magnitude, tier) + _suffix(tier)


static func _mantissa(magnitude: float, tier: int) -> String:
	if tier == 0 or magnitude >= 100.0:
		return str(floori(magnitude + EPSILON))
	var tenths := floori(magnitude * 10.0 + EPSILON)
	var whole := floori(tenths / 10.0)
	var decimal := tenths % 10
	if decimal == 0:
		return str(whole)
	return "%d.%d" % [whole, decimal]


static func _suffix(tier: int) -> String:
	if tier < NAMED_SUFFIXES.size():
		return NAMED_SUFFIXES[tier]
	var index := tier - NAMED_SUFFIXES.size()
	var first := floori(index / float(LETTERS.length()))
	if first >= LETTERS.length():
		return "e%d" % (tier * 3)
	return LETTERS[first] + LETTERS[index % LETTERS.length()]

extends GutTest

const STATS := {"speed": {"base": 4.0}, "carry": {"base": 8}}


func test_builds_scaled_modifiers() -> void:
	var effects := [
		{"stat": "speed", "type": "percent", "value": 0.06},
		{"stat": "carry", "type": "flat", "value": 2},
	]
	var modifiers := EffectSpec.to_modifiers(effects, 3, &"upgrade:boots")
	assert_eq(modifiers.size(), 2)
	assert_eq(modifiers[0].stat_id, &"speed")
	assert_eq(modifiers[0].type, Modifier.Type.PERCENT)
	assert_almost_eq(modifiers[0].value, 0.18, 0.0001)
	assert_eq(modifiers[1].type, Modifier.Type.FLAT)
	assert_eq(modifiers[1].value, 6.0)
	assert_eq(modifiers[1].source_id, &"upgrade:boots")


func test_multiplier_compounds_per_level() -> void:
	var modifiers := EffectSpec.to_modifiers(
		[{"stat": "speed", "type": "multiplier", "value": 2.0}], 3, &"x"
	)
	assert_eq(modifiers[0].value, 8.0)


func test_level_zero_gives_nothing() -> void:
	assert_eq(EffectSpec.to_modifiers([{"stat": "speed", "type": "flat", "value": 1}], 0, &"x"), [])


func test_validate_reports_bad_effects() -> void:
	var effects := [
		{"stat": "speed", "type": "percent", "value": 0.1},
		{"stat": "ghost", "type": "flat", "value": 1},
		{"stat": "speed", "type": "weird", "value": 1},
		{"stat": "speed", "type": "flat"},
	]
	assert_eq(EffectSpec.validate(effects, STATS, "boots").size(), 3)

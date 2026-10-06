extends GutTest

var defs: Dictionary
var rules: UnlockRules
var data: GameData


func before_each() -> void:
	defs = {
		"a": {"cost": 10, "requires": [], "units": {"coop": 1}},
		"b": {"cost": 50, "requires": ["a"], "units": {"coop": 2}},
		"c": {"cost": 30, "requires": ["a"]},
		"d": {"cost": 0, "requires": ["b", "c"]},
	}
	rules = UnlockRules.new(defs)
	data = GameData.new()


func test_root_unlock_is_available_and_children_are_not() -> void:
	assert_true(rules.is_available(&"a", data))
	assert_false(rules.is_available(&"b", data))


func test_children_become_available_after_parent() -> void:
	data.unlock(&"a")
	assert_false(rules.is_available(&"a", data))
	assert_true(rules.is_available(&"b", data))
	assert_true(rules.is_available(&"c", data))
	assert_false(rules.is_available(&"d", data))


func test_needs_every_requirement() -> void:
	data.unlock(&"a")
	data.unlock(&"b")
	assert_false(rules.is_available(&"d", data))
	data.unlock(&"c")
	assert_true(rules.is_available(&"d", data))


func test_unknown_id_is_never_available() -> void:
	assert_false(rules.is_available(&"ghost", data))


func test_pay_accumulates_partial_progress() -> void:
	assert_false(rules.pay(&"a", 4.0, 10.0, data))
	assert_eq(rules.paid(&"a", data), 4.0)
	assert_eq(rules.remaining(&"a", 10.0, data), 6.0)


func test_pay_completes_and_clears_progress() -> void:
	rules.pay(&"a", 4.0, 10.0, data)
	assert_true(rules.pay(&"a", 6.0, 10.0, data))
	assert_true(data.is_unlocked(&"a"))
	assert_false(data.unlock_progress.has(&"a"))


func test_pay_never_overpays() -> void:
	assert_true(rules.pay(&"a", 25.0, 10.0, data))
	assert_eq(rules.remaining(&"a", 10.0, data), 0.0)


func test_pay_is_ignored_when_unavailable() -> void:
	assert_false(rules.pay(&"b", 100.0, 50.0, data))
	assert_false(data.is_unlocked(&"b"))
	assert_eq(rules.paid(&"b", data), 0.0)


func test_units_bonus_sums_completed_unlocks() -> void:
	assert_eq(rules.units_bonus(&"coop", data), 0)
	data.unlock(&"a")
	data.unlock(&"b")
	assert_eq(rules.units_bonus(&"coop", data), 3)
	assert_eq(rules.units_bonus(&"barn", data), 0)


func test_available_ids_sorted_by_cost() -> void:
	data.unlock(&"a")
	assert_eq(rules.available_ids(data), [&"c", &"b"] as Array[StringName])


func test_validate_accepts_project_style_defs() -> void:
	var producers := {"coop": {"item": "egg", "base_units": 2, "max_units": 6}}
	assert_eq(UnlockRules.validate(defs, producers), PackedStringArray())


func test_validate_reports_unknown_requirement_and_target() -> void:
	var bad := {
		"x": {"cost": 5, "requires": ["nope"]},
		"y": {"cost": 5, "requires": [], "units": {"dragon_pen": 1}},
	}
	assert_eq(UnlockRules.validate(bad, {}).size(), 2)


func test_validate_reports_negative_cost() -> void:
	assert_eq(UnlockRules.validate({"x": {"cost": -1, "requires": []}}, {}).size(), 1)


func test_validate_reports_cycles() -> void:
	var cyclic := {
		"x": {"cost": 1, "requires": ["y"]},
		"y": {"cost": 1, "requires": ["x"]},
	}
	assert_gt(UnlockRules.validate(cyclic, {}).size(), 0)


func test_validate_reports_units_beyond_max() -> void:
	var producers := {"coop": {"item": "egg", "base_units": 5, "max_units": 6}}
	assert_eq(UnlockRules.validate(defs, producers).size(), 1)


func test_unlock_effects_become_modifiers() -> void:
	var with_effects := UnlockRules.new(
		{
			"irrigation":
			{
				"cost": 1,
				"requires": [],
				"effects": [{"stat": "rate", "type": "percent", "value": 0.4}]
			}
		}
	)
	var modifiers := with_effects.modifiers(&"irrigation")
	assert_eq(modifiers.size(), 1)
	assert_eq(modifiers[0].source_id, &"unlock:irrigation")
	assert_eq(rules.modifiers(&"a"), [])


func test_validate_checks_unlock_effect_stats() -> void:
	var bad := {
		"x": {"cost": 1, "requires": [], "effects": [{"stat": "ghost", "type": "flat", "value": 1}]}
	}
	assert_eq(UnlockRules.validate(bad, {}, {"rate": {"base": 1.0}}).size(), 1)

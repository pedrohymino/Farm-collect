extends GutTest

const STATS := {"speed": {"base": 4.0}, "interval": {"base": 5.0}}

var rules: UpgradeRules


func before_each() -> void:
	rules = (
		UpgradeRules
		. new(
			{
				"boots":
				{
					"base_cost": 25,
					"growth": 1.5,
					"effects": [{"stat": "speed", "type": "percent", "value": 0.06}],
				},
				"ads":
				{
					"base_cost": 10,
					"growth": 2.0,
					"max_level": 2,
					"effects": [{"stat": "interval", "type": "percent", "value": -0.1}],
				},
			}
		)
	)


func test_cost_grows_exponentially_with_level() -> void:
	assert_eq(rules.cost(&"boots", 0, 1.0), 25.0)
	assert_eq(rules.cost(&"boots", 1, 1.0), 37.5)
	assert_almost_eq(rules.cost(&"boots", 4, 1.0), 25.0 * pow(1.5, 4), 0.0001)


func test_cost_multiplier_scales_price() -> void:
	assert_eq(rules.cost(&"boots", 0, 0.5), 12.5)


func test_max_level() -> void:
	assert_false(rules.is_maxed(&"ads", 1))
	assert_true(rules.is_maxed(&"ads", 2))
	assert_false(rules.is_maxed(&"boots", 500))


func test_modifiers_for_level_use_upgrade_source() -> void:
	var modifiers := rules.modifiers(&"boots", 2)
	assert_eq(modifiers.size(), 1)
	assert_almost_eq(modifiers[0].value, 0.12, 0.0001)
	assert_eq(modifiers[0].source_id, &"upgrade:boots")


func test_ids_keep_file_order() -> void:
	assert_eq(rules.ids(), [&"boots", &"ads"] as Array[StringName])


func test_validate_accepts_good_data_and_reports_bad() -> void:
	var good := {
		"boots":
		{
			"base_cost": 25,
			"growth": 1.5,
			"effects": [{"stat": "speed", "type": "flat", "value": 1}],
		},
	}
	assert_eq(UpgradeRules.validate(good, STATS), PackedStringArray())
	var bad := {
		"free": {"base_cost": 0, "growth": 1.5, "effects": []},
		"shrinking": {"base_cost": 5, "growth": 0.9, "effects": []},
	}
	assert_eq(UpgradeRules.validate(bad, STATS).size(), 2)

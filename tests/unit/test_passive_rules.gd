extends GutTest

const STATS := {"speed": {"base": 4.0}, "magnet": {"base": 0.0}}

var rules: PassiveRules
var data: GameData


func before_each() -> void:
	rules = (
		PassiveRules
		. new(
			{
				"f1":
				{
					"branch": "farmer",
					"cost": 1,
					"requires": [],
					"effects": [{"stat": "speed", "type": "percent", "value": 0.1}],
				},
				"f2": {"branch": "farmer", "cost": 2, "requires": ["f1"], "effects": []},
				"fk":
				{
					"branch": "farmer",
					"cost": 5,
					"requires": ["f2"],
					"key": true,
					"effects": [{"stat": "magnet", "type": "flat", "value": 1.5}],
				},
				"p1": {"branch": "production", "cost": 1, "requires": [], "effects": []},
			}
		)
	)
	data = GameData.new()


func test_roots_are_buyable_and_others_need_a_neighbor() -> void:
	assert_true(rules.can_unlock(&"f1", data))
	assert_true(rules.can_unlock(&"p1", data))
	assert_false(rules.can_unlock(&"f2", data))
	data.passive_nodes[&"f1"] = true
	assert_true(rules.can_unlock(&"f2", data))
	assert_false(rules.can_unlock(&"f1", data))


func test_state_reports_owned_available_and_locked() -> void:
	data.passive_nodes[&"f1"] = true
	assert_eq(rules.state(&"f1", data), PassiveRules.NodeState.OWNED)
	assert_eq(rules.state(&"f2", data), PassiveRules.NodeState.AVAILABLE)
	assert_eq(rules.state(&"fk", data), PassiveRules.NodeState.LOCKED)


func test_branches_and_depth() -> void:
	assert_eq(rules.branches(), [&"farmer", &"production"] as Array[StringName])
	assert_eq(rules.nodes_in_branch(&"farmer"), [&"f1", &"f2", &"fk"] as Array[StringName])
	assert_eq(rules.depth(&"fk"), 3)
	assert_true(rules.is_key(&"fk"))


func test_modifiers_use_passive_source() -> void:
	var modifiers := rules.modifiers(&"fk")
	assert_eq(modifiers[0].stat_id, &"magnet")
	assert_eq(modifiers[0].source_id, &"passive:fk")


func test_validate_reports_bad_nodes() -> void:
	var bad := {
		"a": {"branch": "x", "cost": 0, "requires": [], "effects": []},
		"b": {"branch": "x", "cost": 1, "requires": ["nope"], "effects": []},
		"c": {"cost": 1, "requires": [], "effects": []},
	}
	assert_eq(PassiveRules.validate(bad, STATS).size(), 3)

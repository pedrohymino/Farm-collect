# gdlint: disable=max-public-methods
extends GutTest

var registry: StatRegistry


func before_each() -> void:
	registry = StatRegistry.new()
	(
		registry
		. load_defs(
			{
				"speed": {"base": 4.0, "min": 1.0},
				"carry": {"base": 8, "min": 1, "integer": true},
				"chance": {"base": 0.0, "min": 0.0, "max": 1.0},
				"rate": {"base": 1.0},
				"rate.egg": {"base": 2.0},
			}
		)
	)


func test_returns_base_value_without_modifiers() -> void:
	assert_eq(registry.get_value(&"speed"), 4.0)


func test_flat_modifiers_add_to_base() -> void:
	registry.add_modifier(Modifier.new(&"carry", Modifier.Type.FLAT, 2.0, &"upgrade:bag"))
	registry.add_modifier(Modifier.new(&"carry", Modifier.Type.FLAT, 3.0, &"passive:a"))
	assert_eq(registry.get_value(&"carry"), 13.0)


func test_percent_modifiers_are_summed() -> void:
	registry.add_modifier(Modifier.new(&"speed", Modifier.Type.PERCENT, 0.10, &"a"))
	registry.add_modifier(Modifier.new(&"speed", Modifier.Type.PERCENT, 0.15, &"b"))
	assert_almost_eq(registry.get_value(&"speed"), 5.0, 0.0001)


func test_multipliers_are_multiplied() -> void:
	registry.add_modifier(Modifier.new(&"speed", Modifier.Type.MULTIPLIER, 2.0, &"a"))
	registry.add_modifier(Modifier.new(&"speed", Modifier.Type.MULTIPLIER, 1.5, &"b"))
	assert_almost_eq(registry.get_value(&"speed"), 12.0, 0.0001)


func test_full_formula_combines_flat_percent_and_multiplier() -> void:
	registry.add_modifier(Modifier.new(&"speed", Modifier.Type.FLAT, 1.0, &"a"))
	registry.add_modifier(Modifier.new(&"speed", Modifier.Type.PERCENT, 0.2, &"b"))
	registry.add_modifier(Modifier.new(&"speed", Modifier.Type.MULTIPLIER, 2.0, &"c"))
	# (4 + 1) * (1 + 0.2) * 2 = 12
	assert_almost_eq(registry.get_value(&"speed"), 12.0, 0.0001)


func test_value_is_clamped_to_min_and_max() -> void:
	registry.add_modifier(Modifier.new(&"speed", Modifier.Type.PERCENT, -0.99, &"a"))
	registry.add_modifier(Modifier.new(&"chance", Modifier.Type.FLAT, 5.0, &"b"))
	assert_eq(registry.get_value(&"speed"), 1.0)
	assert_eq(registry.get_value(&"chance"), 1.0)


func test_integer_stats_are_rounded() -> void:
	registry.add_modifier(Modifier.new(&"carry", Modifier.Type.PERCENT, 0.33, &"a"))
	# 8 * 1.33 = 10.64 -> 11
	assert_eq(registry.get_value(&"carry"), 11.0)


func test_remove_modifiers_from_source() -> void:
	registry.add_modifier(Modifier.new(&"carry", Modifier.Type.FLAT, 2.0, &"upgrade:bag"))
	registry.add_modifier(Modifier.new(&"speed", Modifier.Type.FLAT, 1.0, &"upgrade:bag"))
	registry.add_modifier(Modifier.new(&"carry", Modifier.Type.FLAT, 1.0, &"other"))
	registry.remove_modifiers_from(&"upgrade:bag")
	assert_eq(registry.get_value(&"carry"), 9.0)
	assert_eq(registry.get_value(&"speed"), 4.0)


func test_emits_stat_changed_with_new_value() -> void:
	watch_signals(registry)
	registry.add_modifier(Modifier.new(&"carry", Modifier.Type.FLAT, 2.0, &"a"))
	assert_signal_emitted_with_parameters(registry, "stat_changed", [&"carry", 10.0])


func test_cached_value_is_invalidated_on_change() -> void:
	assert_eq(registry.get_value(&"carry"), 8.0)
	registry.add_modifier(Modifier.new(&"carry", Modifier.Type.FLAT, 2.0, &"a"))
	assert_eq(registry.get_value(&"carry"), 10.0)
	registry.remove_modifiers_from(&"a")
	assert_eq(registry.get_value(&"carry"), 8.0)


func test_scoped_value_multiplies_global_and_specific() -> void:
	registry.add_modifier(Modifier.new(&"rate", Modifier.Type.PERCENT, 0.5, &"a"))
	# 1.5 * 2.0
	assert_almost_eq(registry.get_scoped(&"rate", &"egg"), 3.0, 0.0001)


func test_scoped_value_falls_back_to_global_when_specific_missing() -> void:
	assert_eq(registry.get_scoped(&"rate", &"milk"), 1.0)


func test_set_base_changes_value_and_emits() -> void:
	watch_signals(registry)
	registry.set_base(&"speed", 6.0)
	assert_eq(registry.get_value(&"speed"), 6.0)
	assert_signal_emitted(registry, "stat_changed")


func test_dev_multiplier_applies_last() -> void:
	registry.add_modifier(Modifier.new(&"carry", Modifier.Type.FLAT, 2.0, &"a"))
	registry.set_dev_override(&"carry", 3.0)
	assert_eq(registry.get_value(&"carry"), 30.0)


func test_dev_absolute_override_ignores_formula_and_clamp() -> void:
	registry.set_dev_override(&"chance", 1.0, 5.0)
	assert_eq(registry.get_value(&"chance"), 5.0)


func test_clearing_dev_overrides_restores_value() -> void:
	registry.set_dev_override(&"carry", 10.0)
	registry.set_dev_override(&"speed", 1.0, 99.0)
	registry.clear_dev_override(&"carry")
	assert_eq(registry.get_value(&"carry"), 8.0)
	registry.clear_all_dev_overrides()
	assert_eq(registry.get_value(&"speed"), 4.0)


func test_breakdown_lists_base_modifiers_and_final() -> void:
	registry.add_modifier(Modifier.new(&"speed", Modifier.Type.FLAT, 1.0, &"upgrade:boots"))
	var info: Dictionary = registry.breakdown(&"speed")
	assert_eq(info["base"], 4.0)
	assert_eq(info["final"], 5.0)
	assert_eq(info["modifiers"].size(), 1)
	assert_eq(info["modifiers"][0]["source_id"], &"upgrade:boots")


func test_stat_ids_are_sorted() -> void:
	assert_eq(registry.stat_ids(), [&"carry", &"chance", &"rate", &"rate.egg", &"speed"])


func test_unknown_stat_reports_error_and_returns_zero() -> void:
	assert_eq(registry.get_value(&"nope"), 0.0)
	assert_push_error("Unknown stat")


func test_modifier_for_unknown_stat_is_rejected() -> void:
	registry.add_modifier(Modifier.new(&"nope", Modifier.Type.FLAT, 1.0, &"a"))
	assert_push_error("Unknown stat")
	assert_eq(registry.modifier_count(), 0)
